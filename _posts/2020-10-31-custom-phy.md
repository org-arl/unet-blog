---
layout: post
comments: true
title: Developing your own acoustic PHY with UnetStack
date: 31/10/2020
author: Mandar Chitre
categories: howto
feature-img: "assets/img/custom-phy.png"
thumbnail: "assets/img/custom-phy.png"
tags: [howto, unetstack, modems, phy, agents]
---

UnetStack enables software-defined open architecture modems (SDOAMs). While such modems come with one or more implementations of physical layers (PHY) for your use, there are times when you may wish to develop your own PHY. Perhaps it is because you have a special environment that demands a unique PHY, or because you want to interoperate with another modem. Or maybe you just want to try your hands at implementing communication techniques. Whatever the reason, I have often been asked for advise on how to go about writing a custom PHY. In this article, I will walk you through the process of implementing a simple PHY from scratch.

### Background

In an acoustic communication system, the PHY is responsible for converting data bits into an acoustic signal to be transmitted through the channel, and the received signal back into data bits. In UnetStack based modems, this functionality is usually provided by the `phy` agent. The `phy` agent implements the [PHYSICAL service](https://unetstack.net/handbook/unet-handbook_physical_service.html), and other agents such as `uwlink`, `mac` and `ranging` use this service to provide communication and navigation services to the user (and to others agents in the network stack).

At this point, it may be useful to fire up a [Unet audio](https://unetstack.net/#downloads) instance, or connect to a UnetStack powered modem if you're lucky enough to have one handy.

```bash
$ bin/unet -c audio
Modem web: http://localhost:8080/
> ps
node: org.arl.unet.nodeinfo.NodeInfo - IDLE
phy: org.arl.yoda.Physical - IDLE
ranging: org.arl.unet.localization.Ranging - IDLE
uwlink: org.arl.unet.link.ReliableLink - IDLE
  ⋮
```

We see the `phy` agent among all the agents running on the modem. The Unet audio community edition, as well as most UnetStack based underwater modems (e.g. [Subnero M25M series modems](https://subnero.com/products/modem.html)), use Yoda PHY (`org.arl.yoda.Physical`) as the default PHY. The Yoda PHY not only provides the [PHYSICAL service](https://unetstack.net/handbook/unet-handbook_physical_service.html), but also the [BASEBAND service](https://unetstack.net/handbook/unet-handbook_baseband_service.html) and a signal detection capability that we'll be using shortly.

Just typing `phy` on the shell tells us more about the active PHY:
```bash
> phy
« Physical layer »

Provides software-defined physical layer communication services (including error detection & correction).

[org.arl.unet.DatagramParam]
  MTU ⤇ 31
  RTU ⤇ 31

[org.arl.unet.bb.BasebandParam]
  basebandRate ⤇ 12000.0
  carrierFrequency = 12000.0
  maxPreambleID ⤇ 4
  maxSignalLength ⤇ 2147483647
  signalPowerLevel = -42.0

[org.arl.unet.phy.PhysicalParam]
  busy ⤇ false
  maxPowerLevel ⤇ 0.0
  minPowerLevel ⤇ -138.0
  propagationSpeed = 1500.0
  refPowerLevel ⤇ 0.0
  rxEnable = true
  rxSensitivity ⤇ 0.0
  time = 20157105
  timestampedTxDelay = 1.0

[org.arl.yoda.ModemParam]
  adcrate ⤇ 48000.0
  dacrate ⤇ 96000.0
  downconvRatio = 4.0
  fullduplex = false
  upconvRatio ⤇ 8.0
    ⋮
```

There are a lot more parameters, but I've only reproduced the ones that might interest us here.

If we check the `uwlink`, `mac` and `ranging` agents, we'll see that they are using this `phy` agent as their PHY:
```bash
> uwlink.phy
phy
> mac.phy
phy
> ranging.phy
phy
>
```

Our aim is to write our own custom PHY agent (we'll call it `phy2`), load it on the modem, and then ask `uwlink`, `mac` and `ranging` to use it instead!

Our `phy2` will use the [BASEBAND service](https://unetstack.net/handbook/unet-handbook_baseband_service.html) provided by Yoda PHY (`phy`) to transmit and record acoustic signals. We will also use `phy` to sense the acoustic channel, accurately timestamp transmissions and receptions, and continuously monitor the acoustic channel for incoming signals. However, we will implement our own frame format and modulation scheme in `phy2`.

We'll be writing our `phy2` agent here in Groovy, but you could choose to write yours in Java if you wish. While our example here will be 100% pure Groovy for illustration, you may prefer to [develop complex signal processing components in Julia]({% post_url 2020-11-01-custom-phy-in-julia %}) or C (invoked via [JNI](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/)) if you need higher performance or access to GPUs.

### Modulation and demodulation

The core component of a PHY implementation is the modulator and demodulator. The modulator converts a sequence of bits into an acoustic signal for transmission through the channel. The demodulator converts a received acoustic signal (noisy distorted version of the transmitted signal) back into the sequence of bits. In UnetStack, the acoustic signals are represented as sampled complex baseband signals. The `basebandRate` and `carrierFrequency` of the signal were shown when you looked up the parameters of `phy` earlier. For Unet audio, these are 12 kSa/s and 12 kHz respectively (but they may be different on other modems).

The focus of this article is to understand how the PHY agent is developed, and so we won't spend much time on the signal processing. For the purposes of illustration, we will develop a simple low-rate uncoded binary frequency-shift keying (BFSK) scheme. In reality, you'd probably want to use a more performant communication technique, and also include forward error correction coding (FEC).

For the simple BFSK scheme, we'll use 150 baseband samples for each bit (symbol). We'll use frequency _f0_ to represent a bit 0, and _f1_ to represent a bit 1:

_f0_ = `carrierFrequency` + 1/15 × `basebandRate`<br>
_f1_ = `carrierFrequency` - 1/15 × `basebandRate`

For Unet audio, this will translate to _f0_ and _f1_ being 12.8 kHz and 11.2 kHz respectively, and a signaling rate of 80 bps.

The modulator function `bytes2signal()` takes in a byte array and converts it into a float array representing the baseband acoustic signal. Alternate entries in the float array are real and imaginary parts of each sample. The implementation is fairly straightforward:
```groovy
private final int SAMPLES_PER_SYMBOL = 150
private final float NFREQ = 1/15

private float[] bytes2signal(byte[] buf) {
  float[] signal = new float[buf.length * 8 * SAMPLES_PER_SYMBOL * 2]   // 8 bits/byte, 2 floats/sample
  int p = 0
  for (int i = 0; i < buf.length; i++) {
    for (int j = 0; j < 8; j++) {
      int bit = (buf[i] >> j) & 0x01
      float f = bit == 1 ? -NFREQ : NFREQ
      for (int k = 0; k < SAMPLES_PER_SYMBOL; k++) {
        signal[p++] = (float)Math.cos(2 * Math.PI * f * k)
        signal[p++] = (float)Math.sin(2 * Math.PI * f * k)
      }
    }
  }
  return signal
}
```

The demodulator function `signal2bytes()` takes in a float array with the received baseband acoustic signal and returns a byte array containing the decoded bits. Bit decisions are taken by running two matched filters for _f0_ and _f1_ frequencies, and comparing the output:
```groovy
private byte[] signal2bytes(float[] signal, int start) {
  int n = (int)(signal.length / (2 * SAMPLES_PER_SYMBOL * 8))       // number of bytes
  def buf = new byte[n]
  int p = start
  for (int i = 0; i < buf.length; i++) {
    for (int j = 0; j < 8; j++) {
      double s0re = 0                 // real path of matched filter for f0
      double s0im = 0                 // imaginary path of matched filter for f0
      double s1re = 0                 // real path of matched filter for f1
      double s1im = 0                 // imaginary path of matched filter for f0
      for (int k = 0; k < SAMPLES_PER_SYMBOL; k++) {
        float re = signal[p++]
        float im = signal[p++]
        float rclk = (float)Math.cos(2 * Math.PI * NFREQ * k)
        float iclk = (float)Math.sin(2 * Math.PI * NFREQ * k)
        s0re += re*rclk + im*iclk
        s0im += im*rclk - re*iclk
        s1re += re*rclk - im*iclk
        s1im += im*rclk + re*iclk
      }
      if (abs2(s1re, s1im) > abs2(s0re, s0im))
        buf[i] = (byte)(buf[i] | (0x01 << j))
    }
  }
  return buf
}

private double abs2(double re, double im) {
  return re*re + im*im
}
```

The second argument `start` tells the function where in the `signal` array to start demodulating. This is required because the recorded signal that we will receive from `phy` contains an additional detection preamble that we'll need to skip over.

### Writing the agent

Now that we have our modulator and demodulator functions, we are ready to put together our `phy2` agent (we call the agent class `MyPhy`). If you're not familar with developing agents, now would be a good time to [familiarize yourself](https://unetstack.net/handbook/unet-handbook_developing_your_own_agents.html) with the key concepts.

Any PHY agent needs to implement the [PHYSICAL service](https://unetstack.net/handbook/unet-handbook_physical_service.html) and the [DATAGRAM service](https://unetstack.net/handbook/unet-handbook_datagram_service.html). We'll limit ourselves to the basic functionality and honor the `TxFrameReq` (subclass of `DatagramReq`), `TxRawFrameReq` and `ClearReq` requests. We'll generate `RxFrameNtf` (subcalss of `DatagramNtf`) and `BadFrameNtf` notifications. The other `TxFrameStartNtf`, `RxFrameStartNtf` and `CollisionNtf` are generated by the Yoda PHY automatically, and we do not need to generate those. We will also need to implement all the parameters in both services.

Let's start by registering the services we provide, as well as the parameters we support:
```groovy
void setup() {
  register Services.DATAGRAM
  register Services.PHYSICAL
}

protected List<Parameter> getParameterList() {
  return allOf(DatagramParam, PhysicalParam)
}

protected List<Parameter> getParameterList(int ndx) {
  if (ndx == Physical.CONTROL || ndx == Physical.DATA)
    return allOf(DatagramParam, PhysicalChannelParam)
  return null
}
```

When we transmit data, we need to add a header to indicate the source node address, destination node address, data length and protocol number. Additionally, we also include a parity byte for error detection (in practice you may want to use a CRC, but we stick to parity byte for simplicity). We define the header:
```groovy
private final int HDRSIZE = 5           // bytes

private PDU header = new PDU() {
  void format() {
    length(HDRSIZE)
    uint8('parity')
    uint8('protocol')
    uint8('from')
    uint8('to')
    uint8('len')
  }
}
```

We fix the number of user data bytes in a frame (`MTU` and `RTU`). These are DATAGRAM service parameters, and we mark them as read-only through the use the `final` modifier:
```groovy
final int MTU = 8
final int RTU = MTU
```

We'll be needing the Yoda PHY (`phy`) agent often, so we save a reference to it in an attribute `bbsp` (baseband service provider). We subscribe to notifications from Yoda PHY, and also configure it to provide us acoustic signals when it detects a frame:
```groovy
private final AgentID bbsp = agent('phy')       // Yoda PHY

void startup() {
  subscribe bbsp
  int nsamples = (MTU + HDRSIZE) * 8 * SAMPLES_PER_SYMBOL
  set(bbsp, Physical.CONTROL, ModemChannelParam.modulation, 'none')
  set(bbsp, Physical.CONTROL, ModemChannelParam.basebandExtra, nsamples)
  set(bbsp, Physical.CONTROL, ModemChannelParam.basebandRx, true)
  set(bbsp, Physical.DATA, ModemChannelParam.modulation, 'none')
  set(bbsp, Physical.DATA, ModemChannelParam.basebandExtra, nsamples)
  set(bbsp, Physical.DATA, ModemChannelParam.basebandRx, true)
}
```

By setting the `modulation` parameters for both CONTROL and DATA channels to `'none'`, we have instructed Yoda not to process the received frames. By setting `basebandRx` parameter to true, we have asked Yoda PHY to send us the baseband signal each time a CONTROL or DATA frame is detected. The `basebandExtra` parameter is set to the number of samples in our frame, so that Yoda PHY knows how long a signal to record for us.

Yoda PHY detects acoustic signals in the channel by detecting unique preamble signals transmitted just before CONTROL and DATA frames. These signals are included in the recordings and therefore our modulated signal starts a few samples into the signal buffer. To find out exactly how long the preamble signals are (can be configured using Yoda PHY parameters), we ask Yoda PHY for a copy of the preamble and extract the length:
```groovy
private int getPreambleLength(int ndx) {      // ndx is Physical.CONTROL or Physical.DATA
  int prelen = 0
  def pre = request(new GetPreambleSignalReq(recipient: bbsp, preamble: ndx), 1000)
  if (pre instanceof BasebandSignal) prelen = ((BasebandSignal)pre).signalLength
  return prelen
}
```

Next, we implement all the PHYSICAL service parameters by delegating them to Yoda PHY:
```groovy
// Physical service parameters (read-only) delegated to Yoda PHY
Float getRefPowerLevel()    { return (Float)get(bbsp, PhysicalParam.refPowerLevel) }
Float getMaxPowerLevel()    { return (Float)get(bbsp, PhysicalParam.maxPowerLevel) }
Float getMinPowerLevel()    { return (Float)get(bbsp, PhysicalParam.minPowerLevel) }
Float getRxSensitivity()    { return (Float)get(bbsp, PhysicalParam.rxSensitivity) }
Float getPropagationSpeed() { return (Float)get(bbsp, PhysicalParam.propagationSpeed) }
Long getTime()              { return (Long)get(bbsp, PhysicalParam.time) }
Boolean getBusy()           { return (Boolean)get(bbsp, PhysicalParam.busy) }
Boolean getRxEnable()       { return (Boolean)get(bbsp, PhysicalParam.rxEnable) }
```

We also implement the PHYSICAL service indexed parameters:
```groovy
// Physical service indexed parameter (read-only)
int getMTU(int ndx)               { return MTU }
int getRTU(int ndx)               { return RTU }
int getFrameLength(int ndx)       { return MTU + HDRSIZE }
int getMaxFrameLength(int ndx)    { return MTU + HDRSIZE }
int getFec(int ndx)               { return 0 }        // no FEC
List<String> getFecList(int ndx)  { return [] }       // FEC not supported
int getErrorDetection(int ndx)    { return 8 }        // 8 bits
boolean getLlr(int ndx)           { return false }    // LLR not supported

// Physical service indexed dynamic parameters

void setPowerLevel(int ndx, float lvl) {
  if (ndx != Physical.CONTROL && ndx != Physical.DATA) return
  set(bbsp, BasebandParam.signalPowerLevel, lvl)
}

Float getPowerLevel(int ndx) {
  if (ndx != Physical.CONTROL && ndx != Physical.DATA) return null
  return (Float)get(bbsp, BasebandParam.signalPowerLevel)
}

Float getFrameDuration(int ndx) {
  if (ndx != Physical.CONTROL && ndx != Physical.DATA) return null
  def bbrate = (Float)get(bbsp, BasebandParam.basebandRate)
  if (bbrate == null) return 0f
  int prelen = getPreambleLength(ndx)
  return (float)((prelen + (MTU + HDRSIZE) * 8 * SAMPLES_PER_SYMBOL) / bbrate)
}

Float getDataRate(int ndx) {
  if (ndx != Physical.CONTROL && ndx != Physical.DATA) return null
  return (float)(8 * getFrameLength(ndx) / getFrameDuration(ndx))
}
```
The `powerLevel` parameter is delegated to Yoda PHY `signalPowerLevel` since we will ask Yoda PHY to transmit signals for us.

We often require our node address. Rather than ask the `node` agent each time, we use the UnetStack utility to request and cache the node address:
```groovy
private NodeAddressCache addrCache = new NodeAddressCache(this, true)
```

We also need to keep a cache of pending transmission requests, so that when Yoda PHY informs us that the transmission is complete, we can inform our client (agent who sent us the transmission request) that the transmission was completed:
```groovy
private Map<String,Message> pending = [:]
```

To process various requests, we override the `processRequest()` method:
```groovy
Message processRequest(Message req) {
  if (req instanceof DatagramReq) return processDatagramReq(req)
  if (req instanceof TxRawFrameReq) return processTxRawFrameReq(req)
  if (req instanceof ClearReq) {
    send new ClearReq(recipient: bbsp)
    pending.clear()
    return new Message(req, Performative.AGREE)
  }
}
```
We don't need an `if` condition for `TxFrameReq`, as it is a subclass of `DatagramReq` and therefore `processDatagramReq()` will be called when a `TxFrameReq` is received.

The `processTxRawFrameReq()` simply delegates the transmission to `transmit()`:
```groovy
private Message processTxRawFrameReq(TxRawFrameReq req) {
  if (transmit(req.type, req.data, req)) return new Message(req, Performative.AGREE)
  return new Message(req, Performative.FAILURE)
}
```

The `processDatagramReq()` also delegates transmission to `transmit()` after composing a data frame (PDU) with the required header prepended:
```groovy
private Message processDatagramReq(DatagramReq req) {
  def from = addrCache.address
  byte[] buf = composePDU(from, req.to, req.protocol, req.data)
  int ch = req instanceof TxFrameReq ? req.type : Physical.DATA     // default to DATA if DatagramReq
  if (transmit(ch, buf, req)) return new Message(req, Performative.AGREE)
  return new Message(req, Performative.FAILURE)
}

private byte[] composePDU(int from, int to, int protocol, byte[] data) {
  if (data == null) data = new byte[0]
  def hdr = header.encode([
    parity: 0, from: from, to: to, protocol: protocol, len: data.length
  ] as Map<String,Object>)
  def buf = new byte[HDRSIZE + MTU]
  System.arraycopy(hdr, 0, buf, 0, HDRSIZE)
  System.arraycopy(data, 0, buf, HDRSIZE, data.length)
  int parity = 0
  for (int i = 1; i < buf.length; i++)
    parity ^= buf[i]    // compute parity bits
  buf[0] = (byte)parity
  return buf
}
```

The `transmit()` method simply converts the buffer into a signal and makes a `TxBasebandSignalReq` request to Yoda PHY to do the transmission. It adds the transmission request to the cache so that a notification can be sent to the requester when the transmission is completed.

```groovy
private boolean transmit(int ch, byte[] buf, Message req) {
  def signal = bytes2signal(buf)
  def bbreq = new TxBasebandSignalReq(recipient: bbsp, preamble: ch, signal: signal)
  def rsp = request(bbreq, 1000)
  if (rsp?.performative != Performative.AGREE) return false
  pending.put(bbreq.messageID, req)
  return true
}
```

Incoming transmit notifications and signal receptions are processed by overriding the `processMessage()` method:
```groovy
void processMessage(Message msg) {
  addrCache.update(msg)
  if (msg instanceof TxFrameNtf) handleTxFrameNtf(msg)
  else if (msg instanceof RxBasebandSignalNtf) handleRxBasebandSignalNtf(msg)
}
```
The `addrCache.update()` call ensures that any node address changes are update to the address cache.

When a transmission is completed by Yoda PHY, it sends us a `TxFrameNtf`. We in turn send a `TxFrameNtf` to our client:
```groovy
private void handleTxFrameNtf(TxFrameNtf msg) {
  def req = pending.remove(msg.inReplyTo)
  if (req == null) return
  def ntf = new TxFrameNtf(req)
  ntf.type = msg.type
  ntf.txTime = msg.txTime
  ntf.location = msg.location
  send ntf
}
```

When a baseband signal is received from Yoda PHY, we process it and convert it to bits. If the parity bits suggest that the frame is error-free, we send a `RxFrameNtf` for the received frame. In case of errors, we send a `BadFrameNtf` instead. The `RxFrameNtf` is published on the agent's default topic if the frame is a BROADCAST or intended for our node address. Otherwise it is published on the agent's SNOOP topic.

```groovy
private void handleRxBasebandSignalNtf(RxBasebandSignalNtf msg) {
  def buf = signal2bytes(msg.signal, 2 * getPreambleLength(msg.preamble))
  int parity = 0
  for (int i = 1; i < buf.length; i++)
    parity ^= buf[i]        // compute parity bits
  if (buf.length >= HDRSIZE && buf[0] == parity) {
    def hdr = header.decode(buf[0..HDRSIZE-1] as byte[])
    int len = (int)hdr.len
    def rcpt = topic()
    if (hdr.to != Address.BROADCAST && hdr.to != addrCache.address)
      rcpt = topic(agentID, Physical.SNOOP)
    byte[] data = null
    if (len > 0) {
      data = new byte[len]
      System.arraycopy(buf, HDRSIZE, data, 0, len)
    }
    send new RxFrameNtf(
      recipient: rcpt, type: msg.preamble, rxTime: msg.rxTime, location: msg.location,
      rssi: msg.rssi, from: (int)hdr.from, to: (int)hdr.to, protocol: (int)hdr.protocol, data: data
    )
  } else {
    send new BadFrameNtf(
      recipient: topic(), type: msg.preamble, rxTime: msg.rxTime, location: msg.location,
      rssi: msg.rssi, data: buf
    )
  }
}
```

That's it!

The complete implementation (with a few additional error checks) is available from the [unet-contrib repository](https://github.com/org-arl/unet-contrib/blob/master/contrib/MyPhy/MyPhy.groovy).

### Testing our custom PHY

Now that we've implemented `phy2` agent, it is time to try it out on Unet audio or your modem. Copy the [`MyPhy.groovy`](https://github.com/org-arl/unet-contrib/blob/master/contrib/MyPhy/MyPhy.groovy) file to the `classes` folder in Unet audio or the modem. Then on the shell:
```bash
> phy.fullduplex = true
true
> container.add 'phy2', new MyPhy()
phy2
> subscribe phy2
```
We turn on `fullduplex` so that we can transmit and receive on the same device. We subscribe to the `phy2` agent's topic so that we see the `RxFrameNtf` when data is received.

> **TIP**
>
> Writing agents in Groovy in the `classes` folder of UnetStack is often convenient since Groovy can load the class directly from source, without needing explicit compilation. However, if there are errors in the code, Groovy's classloader sometimes gives a cryptic "`BUG! exception in phase 'semantic analysis' in source unit`" error message. If you encounter this, use `groovyc` to get a clearer error report:
>
> `$ groovyc -cp lib/unet-framework-3.2.0.jar:lib/fjage-1.8.0.jar:lib/unet-yoda-3.2.0.jar classes/MyPhy.groovy`
>
> and remember to delete off the resultant `MyPhy.class` file to avoid a stale class file being used later accidentally.

To test the agent, we make a transmission:
```bash
> phy2 << new TxFrameReq(data: [1,2,3])
AGREE
phy2 >> TxFrameNtf:INFORM[txTime:19013099]
phy2 >> RxFrameNtf:INFORM[type:CONTROL from:1 rxTime:19039936 rssi:-49.1 (3 bytes)]
```
If you are using Unet audio, you should have been able to hear the transmission on your speaker. After a short delay, you'd see the reception (`RxFrameNtf`). We can check the contents to ensure that we got the correct data back:
```bash
> ntf.data
[1, 2, 3]
```
If the frame had any errors, you'd have gotten a `BadFrameNtf`. In that case, you may want to try adjusting your computer's volume setting (for Unet audio) or transmit power (`plvl` command on Unet audio or modem), and try again.

Now that we can transmit and receive correctly, we can enable the rest of the network stack to use our new PHY:
```bash
> uwlink.phy = 'phy2'
phy2
> mac.phy = 'phy2'
phy2
> ranging.phy = 'phy2'
phy2
```

We can send a text message via UnetStack's remote agent:
```bash
> tell 0, 'hi'
AGREE
phy2 >> RxFrameNtf:INFORM[type:DATA from:1 protocol:3 rxTime:96861353 rssi:-48.7 (3 bytes)]
[1]: hi
```
This resulting datagram goes down the layers of the stack, passed through our new PHY to yield an acoustic signal, gets received by the PHY again to be converted to a datagram, which then goes back up the stack all the way to the remote agent who sends it to the shell for display!

### Conclusion

In this article, we have seen how to write a simple custom PHY agent. We intentionally kept the implementation simple by using an uncoded BFSK communication scheme, as the focus of this article was to illustrate how to implement a custom PHY.

In a practical system, you may wish to replace the communication scheme (`bytes2signal()` and `signal2bytes()` methods) with something more sophisticated, including FEC coding. You may also want to use a stronger error detection scheme (CRC rather than parity bits). You'd perhaps also want to consider supporting variable `MTU` and some of the optional features of the PHYSICAL service (e.g. timed transmission, timestamping, etc).

If you find that Java or Groovy doesn't meet your signal processing needs, you may consider writing the `bytes2signal()` and `signal2bytes()` methods in C (using [JNI](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/)) or [in Julia]({% post_url 2020-11-01-custom-phy-in-julia %}) (my preferred choice!).

> **TIP**
>
> With Unet audio, C or Julia calls from Java work seamlessly. However, if you're running on a real modem, chances are that the modem's JVM sandbox won't let you run non-JVM code directly. If you have a coprocessor on your modem, you can run the `phy2` agent on the coprocessor in a fjåge slave container, and you will have no JVM sandbox restrictions. Alternatively you can run the `phy2` agent even on your laptop, as long as the laptop is connected over Ethernet to thr modem. To start a slave container, just install Unet audio on the coprocessor/laptop, and start Unet with `bin/unet sh <ipaddr> 1100` where `<ipaddr>` is replaced by the IP address of your modem, and port 1100 is the API port set on the modem.
