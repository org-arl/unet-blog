---
layout: post
comments: true
title: Basic modem operations using UnetStack
date: 12/11/2018
author: Prasad Anjangi
categories: howto
feature-img: "assets/img/basicoperations.jpg"
thumbnail: "assets/img/basicoperations.jpg"
tags: [howto, modems, basic operations, transmission, reception, recording]
---

The ease of implementation and development of applications as needed by researchers or in industry using underwater acoustic modems is crucial today. In order to realize the potential of advancements made in the underwater communication and networking technology, the applications should be easy to implement and test. Implementation of few basic operations such as transmission of packets carrying information from one node to another or transmission/recroding of signals are simple tasks using which complex useful applications/protocols can be developed. Therefore, a detailed explanation on implementation of these basic tasks in [UnetStack](https://www.unetstack.net/) (an underwater network stack and simulator) is presented here.

## UnetStack overview
The UnetStack architecture defines a set of software agents that work together to provide a complete underwater networking solution. *Agents* play the role that layers play in [traditional network stacks](https://en.wikipedia.org/wiki/OSI_model). However, as the agents are not organized in any enforced hierarchy, they are free to interact in any way suitable to meet application needs. This promotes low-overhead protocols and cross-layer information sharing. The stack runs on a Java virtual machine and [fjage](https://org-arl.github.io/fjage/doc/html/introduction.html) source agent framework. A detailed documentation of UnetStack is [here](https://www.unetstack.net/docs.html).

## UnetSocket to interact with modem
UnetStack provides *UnetSocket* class. The UnetSocket class internally utilizes the  *Gateway* class provided by fjage. The UnetSocket interface is very similar to the standard socket interface that can be found in TCP/IP networking and provides the user an easy to to transmit datagrams using the modem. Gateway class which can be accessed using UnectSocket provides the user to communicate with the agents running in UnetStack on the modem. This class is utilized and the APIs are developed for the user to build their application upon. The APIs to interact with the modem from any computer are available in `Java/Groovy`, `C` and `Python`.

In order to open a connection to the modem (assuming the computer and modem are on a TCP/IP network) using UnetSocket class, the modem’s IP address and the port number are needed. The UnetStack runs on port number 1100 by default. An example in `Groovy` to open this connection is as shown below:

```java
sock = new UnetSocket(ip_address, 1100)
modem = sock.getGateway()
```
The `sock` object created can be used to send datagrams and receive datagrams. A more detailed explanation can be found in the [unet handbook](https://unetstack.net/handbook/unet-handbook_unetsocket_api.html).
The instance `modem` created can be used to access all the methods provided of the Gateway class to interact with the agents running on the modem. The Gateway class methods are documented [here](http://org-arl.github.io/fjage/javadoc/).

Note that the same interfaces are also available in `Python` and `C`. For example, to open a connection to the modem using `Python`:

```python
sock = UnetSocket(ip_address, 1100)
modem = sock.getGateway()
```

and in `C`:

```c
modem_t modem = modem_open_eth(ip_address, 1100);
```

## Examples of basic operations
Once a connection is open to the modem, the user can write code to develop their own applications. Sample code in `C`, `Python` and `Groovy/Java` on how to connect to the modem and perform basic operations are available [here](https://github.com/org-arl/unet-contrib/tree/master/contrib/Examples) for reference. Few basic operations are listed below and explained if the code is developed in `Groovy`:

1. **Transmit a frame containing data using FH-BFSK modulation (default CONTROL) scheme.**

    The first step in transmitting a packet is to figure out which agent running in UnetStack provides a Physical service. The piece of code

    ```java
    // Look for agents providing physical service
     def phy = modem.agentForService Services.PHYSICAL
    ```

    looks for such agent and returns the AgentID. Now, the second step is to create a message supported by this agent to transmit data. The TxFrameReq is one such message which supports transmission of data using either CONTROL or DATA modulation scheme. In order to transmit, first the message is created

    ```java
    // Create a message containing data
    def msg = new TxFrameReq(type: Physical.CONTROL, data: ’hello’ as byte[])
    ```

    and then the recipient of the message is set to the AgentID which provides the Physical service. We set it as recipient of the message, since that is the agent which can transmit the packet.

    ```java
    // set the appropriate recipient of the message
    msg.recipient = phy
    ```

    Finally, the message is sent to the UnetStack running on the modem which transmits the packet:

    ```java
    // send the message
    modem.send(msg)
    ```

2. **Transmit a frame containing data using OFDM modulation (default DATA) scheme.**

    ```java
    // Look for agents providing physical service
    def phy = modem.agentForService Services.PHYSICAL
    def msg = new TxFrameReq(type: Physical.DATA, data: ’hello’ as byte[])
    msg.recipient = phy
    modem.send(msg)
    ```

    This code is similar to the one explained above for the CONTROL scheme, except that the message is created with the type DATA instead of CON- TROL.

3. **Transmit a baseband signal.**

    Sometimes a user might want to create their own signal with custom modulation scheme and transmit using the modem. This is possible with the modem running UnetStack. The user can create a baseband signal as an array with alternate real and imaginary values and the standard Unet API can be used to transmit this baseband signal. An example code for performing such an operation is as shown below:

    The first step again in transmitting a signal is to look for agent in UnetStack which provides Baseband service. The following piece of code

    ```java
    // Look for agents providing baseband service
    def bb = modem.agentForService Services.BASEBAND
    ```

    looks for such an agent and returns the AgentID.

    The next step is to generate a baseband signal. In order to generate the baseband signal, the only thing to keep in mind for the user is to use a baseband sampling rate fd = 24000 Hz. The carrier frequency of the modem by default is set at fc = 24000 Hz. A sample code to generate a baseband signal is as shown below:

    ```java
    // Generate a baseband signal
    float freq = 5000
    float duration = 1000e-3
    int fd = 24000
    int fc = 24000
    int n = duration*fd
    def sig = []
    (0..n-1).each { t ->
        double a = 2*Math.PI*(freq-fc)*t/fd
        sig << (int)(Math.cos(a))
        sig << (int)(Math.sin(a))
    }
    ```

    Note that the real and imaginary values of each sample are placed alternately in the signal array.

    Next step is to create the message with the signal. This can be performed as shown below:

    ```java
    // Create a message containing the signal
    def msg = new TxBasebandSignalReq(preamble: 3, signal: sig)
    ```

    This example is using a specific preamble already available in the modem. In case, the user wants to include their own preamble they can do so and include it in the baseband signal generated.

    Finally, the appropriate recipient for the message is set and the message is sent to the UnetStack which instructs the modem to transmit this signal as shown below:

    ```java
    // set the recipient and send the message
    msg.recipient = bb
    modem.send(msg)
    ```

4. **Record a baseband signal.**

    Finally, it is also possible to record a baseband signal. Upon a request to record the baseband signal, the modem records a passband signal and converts it to the appropriate baseband signal and returns it to the user. This operation is as shown below:

    ```java
    // Record a baseband signal
    def msg = new RecordBasebandSignalReq(recLen: 24000)
    msg.recipient = bb
    modem.send(msg)
    ```

    The above code should be easy to understand now. A message is created with recording length of 24000 baseband samples, i.e., this message requests the modem to record 24000 baseband samples from the current time.

    Once the modem is instructed to record the baseband signal and the modem agrees to do so, a `RxBasebandSignalNtf` message will be sent out by the agent providing Baseband service notifying that the recording was performed successfully and it also contains the recorded signal. Therefore, a user can look for the reception of this message and extract the received signal from it as shown below:

    ```java
     // Receive the notification when the signal is recorded
    def rxntf = modem.receive(RxBasebandSignalNtf, 5000)
    if (rxntf != null) {
        // Extract the recorded signal
        def rec_signal = rxntf.signal
        println ’Recorded signal successfully!’
    }
    ```
