---
layout: post
comments: true
title: Developing modem drivers for UnetStack
date: 15/8/2018
author: Mandar Chitre
categories: howto
feature-img: "assets/img/electronics.jpg"
thumbnail: "assets/img/electronics.jpg"
tags: [howto, modems, phy, driver]
---

UnetStack runs on several modems, simulators, and even laptops with sound cards. But what if we have a modem that UnetStack doesn't already run on? And we want it to! Well ... we need to write a driver for that modem. It really isn't that difficult, and this blog will walk you through the basics.

## A simple modem

For the sake of concreteness and simplicity, let's make some assumptions about our hypothetical modem. Our modem is accessed over a RS232 port from the computer that runs UnetStack. It supports transmission and reception of fixed length frames of 32 bytes at 320 bps, and allows the transmission power to be controlled between 120-180 dB re 1 µPa @ 1m. The default power level when the modem is powered up is 170 dB.

The modem supports two AT commands:

* `AT+TPL:`_nnn_ -- set transmit power to _nnn_ dB
* `AT+TX:`_nnn_, _xxxx_... -- transmit a frame to node _nnn_ with 32 bytes of data _xxxx_... given in hexadecimal format

and one unsolicited notification:

* `AT+RX:`_nnn_, _xxxx_... -- a frame with 32 bytes of data _xxxx_... was received from node _nnn_

## The modem driver

A modem driver is simply a [Unet agent](https://www.unetstack.net/unet-agents.html) that supports the [Physical](https://www.unetstack.net/svc-10-phy.html) and [Datagram](https://www.unetstack.net/svc-02-datagram.html) services.

There are several libraries for Java/Groovy that allow RS232 communications. We'll use [jSerialComm](http://fazecast.github.io/jSerialComm/) in our example here.

Let's start putting together a skeleton for it in Groovy:
```groovy
import org.arl.fjage.*
import org.arl.unet.*
import com.fazecast.jSerialComm.*

class MyModemDriver extends UnetAgent {

  SerialPort rs232 = SerialPort.getCommPorts()[0]
  AgentID notify      // notification topic
  int plvl = 170      // default power level setting

  void setup() {
    notify = topic()
    register Services.PHYSICAL
    register Services.DATAGRAM
  }

  void startup() {
    rs232.openPort()
  }

  void shutdown() {
    rs232.closePort()
  }

  Message processRequest(Message req) {
    // process frame transmission request here
    return null
  }

  List<Parameter> getParameterList() {
    return allOf(DatagramParam, PhysicalParam)
  }

}
```

What we have in this code is a simple agent that advertises the two services that it supports, two sets of parameters for those services, and creates a `notify` topic on which it can send it's notifications when a frame is received. It also opens a RS232 port for reading and writing to the modem. When a frame transmission request is made to the agent, the `processRequest()` method will be called, so we'd want to write the code to handle that there.

We'll conveniently ignore error handling throughout this blog to keep the code simple.

In order to support the Datagram service, the agent must honor a [`DatagramReq`](https://www.unetstack.net/javadoc/org/arl/unet/DatagramReq.html). It should also send a [`DatagramNtf`](https://www.unetstack.net/javadoc/org/arl/unet/DatagramNtf.html) when a frame is received by the modem, and expose a parameter `MTU` that advertises the frame size.

To honor the `DatagramReq`, we modify the `processRequest()` method to send out the proper AT command:
```groovy
  Message processRequest(Message req) {
    if (req instanceof DatagramReq) {
      String s = "AT+TX:" + req.to + "," + req.data.encodeHex() + "\n"
      byte[] b = s.getBytes()
      rs232.writeBytes(b, b.length)
      return new Message(req, Performative.AGREE)
    }
    return null
  }

```
To publish the `MTU` parameter, we simply declare a getter for it:
```groovy
  int getMTU() {
    return 32         // frame size
  }
```
Since our hypothetical modem uses a fixed frame size, we don't need a setter. We'll deal with generating `DatagramNtf` a little later.

Now let's look at what we need to do to support the Physical service. We need to support the [`TxFrameReq`](https://www.unetstack.net/javadoc/org/arl/unet/phy/TxFrameReq.html) request, and the [`RxFrameNtf`](https://www.unetstack.net/javadoc/org/arl/unet/phy/RxFrameNtf.html) and [`TxFrameNtf`](https://www.unetstack.net/javadoc/org/arl/unet/phy/TxFrameNtf.html) notifications. Since our modem doesn't support advanced functionality like collision detection, bad frame detection, snooping of frames for other nodes, we don't need to support the rest of the messages. Since the `TxFrameReq` class extends the `DatagramReq`, our `processRequest()` method above already honors these requests!

We add support for the `TxFrameNtf` to be sent the moment we ask the modem to send the frame for us. For this we add a [`OneShotBehavior`](http://org-arl.github.io/fjage/doc/html/behaviors.html) to our 'processMessage()' method:
```groovy
  Message processRequest(Message req) {
    if (req instanceof DatagramReq) {
      String s = "AT+TX:" + req.to + "," + req.data.encodeHex() + "\n"
      byte[] b = s.getBytes()
      rs232.writeBytes(b, b.length)
      add new OneShotBehavior({
        send new TxFrameNtf(req)
      })
      return new Message(req, Performative.AGREE)
    }
    return null
  }

```
The behavior will be executed as soon as the request is processed.

We also need to support a bunch of parameters, which we'll support by implementing some getters:
```groovy
  boolean getRxEnable() {
    return true
  }

  float getPropagationSpeed() {
    return 1500       // assume sound speed is 1500 m/s
  }

  int getTimestampedTxDelay() {
    return 0          // our modem doesn't support timestamped transmissions
  }

  long getTime() {
    return 1000*System.currentTimeMillis()    // use system clock for timing in µs
  }

  boolean getBusy() {
    return false
  }

  float getRefPowerLevel() {
    return 0          // our modem uses absolute power levels in dB re uPa @ 1m
  }

  float getMaxPowerLevel() {
    return 180        // our modem can transmit at max power level of 180 dB
  }

  float getMinPowerLevel() {
    return 120        // ... and a min power level of 120 dB
  }
```

The Physical service has two logical channels: CONTROL and DATA. Since our modem does not have multiple modulation schemes or forward error correction (FEC) codes, we don't need to differentiate between the two channels. We implement the getters for all the indexed parameters (indexed by the channel):
```groovy
  int getMTU(int ch) {
    return 32         // frame size
  }

  float getFrameDuration(int ch) {
    return getMTU(ch)/getDataRate(ch)
  }

  float getPowerLevel(int ch) {
    return plvl
  }

  int getErrorDetection(int ch) {
    return 0
  }

  int getFrameLength(int ch) {
    return getMTU(ch)   // fixed frame size
  }

  int getMaxFrameLength(int ch) {
    return getMTU(ch)   // fixed frame size
  }

  int getFec(int ch) {
    return 0
  }

  List getFecList(int ch) {
    return null
  }

  float getDataRate(int ch) {
    return 320.0      // data rate of 320 bps
  }
```
The only parameter that can be changed is the power level, so we need one setter that sends the appropriate AT command to the modem:
```groovy
  float setPowerLevel(int ch, float x) {
    plvl = x
    if (plvl < getMinPowerLevel()) plvl = getMinPowerLevel()
    if (plvl > getMaxPowerLevel()) plvl = getMaxPowerLevel()
    String s = "AT+TPL:" + plvl + "\n"
    byte[] b = s.getBytes()
    rs232.writeBytes(b, b.length)
    return plvl
  }
```

So now we can transmit data frames and control the transmit power level. The next thing to do is to be able to receive data frames. To do this, we need to monitor the serial port for unsolicited data. We could do this with an [event-based API](https://github.com/Fazecast/jSerialComm/wiki/Event-Based-Reading-Usage-Example) for performance, but to keep the code here simple, we'll use the [polling API](https://github.com/Fazecast/jSerialComm/wiki/Nonblocking-Reading-Usage-Example) instead. We can set up the polling in a [`CyclicBehavior`](http://org-arl.github.io/fjage/javadoc/index.html?org/arl/fjage/CyclicBehavior.html). To do this, we have to modify our `startup()` method:
```groovy
  void startup() {
    rs232.openPort()
    add new CyclicBehavior({
      int n = rs232.bytesAvailable()
      if (n == 0) Thread.sleep(20)
      else {
        // data available
        byte[] buf = new byte[n]
        rs232.readBytes(buf, n)
        parseRxData(new String(buf))
      }
    })
  }

```
and add a `parseRxData()` method to deal with the data coming in over the RS232 port, and to send out a `RxFrameNtf` if a frame is received:
```groovy
  String data = ''

  void parseRxData(String s) {
    data += s
    int n = data.indexOf('\n')
    if (n < 0) return
    s = data.substring(0, n)
    data = data.substring(n)
    if (s.startsWith("AT+RX:")) {
      int addr = s.substring(6,9) as int
      byte[] bytes = s.substring(10).decodeHex()
      send new RxFrameNtf(
        recipient: notify,
        from: addr,
        data: bytes,
        bits: 8*bytes.length,
        rxTime: 1000*System.currentTimeMillis()
      )
    }
  }
```
Again, since `RxFrameNtf` class extends `DatagramNtf`, we satify the Datagram service without having to explicitly generate a `DatagramNtf`.

## Loading the modem driver

Now that we have the modem driver ready, all that remains is to run UnetStack and to load the driver. You can manually do this in the shell, or use the `etc/setup.groovy` to load it:
```groovy
container.add 'phy', new MyModemDriver()
```
When you run UnetStack, you should be able to see (using the shell) your driver loaded:
```
> ps
phy: MyModemDriver - IDLE
```
and interact with it just like on any other modem running UnetStack:
```
> phy = agent('phy')
> phy.MTU
32
> phy << new TxFrameReq(to: 3, data: [1,2,3])
AGREE
```

## Advanced functionality

There's much more that modem drivers may support, depending on the capabilities of the modem. Once you understand how to write the simple modem driver above, the rest should be straightforward. Here are some additional functionalities that you may want to consider supporting:

* `CONTROL` and `DATA` channels, if the modem supports various levels of modulation/FEC robustness
* Optional `ClearReq`, `TxRawFrameReq`, `RxFrameStartNtf`, `BadFrameNtf` and `CollisionNtf` messages of the [Physical](https://www.unetstack.net/svc-10-phy.html) service
* Populating optional `to`, `protocol`, `timestamp` and `errors` fields of the [`RxFrameNtf`](https://www.unetstack.net/javadoc/org/arl/unet/phy/RxFrameNtf.html)
* More accurate timestamps, if the modem provides a µs accuracy clock for timestamping frames
* Optional `TIMED_TX` and `TIMESTAMPED_TX` capability of the [Physical](https://www.unetstack.net/svc-10-phy.html) service
* Optional `PRIORITY`, `TTL` and `CANCELATION` capabilities of the [Datagram](https://www.unetstack.net/svc-02-datagram.html) service
* [Baseband](https://www.unetstack.net/svc-12-baseband.html) service, if the modem supports acoustic recording or arbitrary signal transmission
* [Ranging](https://www.unetstack.net/svc-11-ranging.html) service, if the modem supports acoustic ranging

And if your modem supports new functionality and parameters, you can define your own parameters to expose and requests, responses and notifications to offer.
