---
layout: post
comments: true
title: Converting your laptop to a JANUS modem using Unet audio
date: 06/12/2020
author: Manu Ignatius, Mandar Chitre
categories: howto
feature-img: "assets/img/unetaudio/unetaudio.jpg"
thumbnail: "assets/img/unetaudio/unetaudio.jpg"
tags: [howto, unetaudio, unetstack, modems, phy, janus]
---

Imagine you are developing an application for an underwater use case such as message or file transfer and you intend to eventually deploy the app on a network of [JANUS](http://www.januswiki.com/) compliant modems in the field. Or you may be developing a new routing protocol that is intended to work on a network of JANUS compliant modems. Or you might be a university Professor designing an exercise for your students to learn about underwater communications and networking.

Along with developing the app or the protocol, a common step is to simulate its performance using simulators like UnetSim. However, before deploying the app on actual modems and going to the field for testing, you want to make sure it works on actual devices as intended. If you are in a classroom, having a hardware component that can actually transmit and receive the frames would be extremely useful. This is where [Unet audio](https://unetstack.net/) comes handy.

## What is Unet audio?

![](../assets/img/unetaudio/Unetaudio-logo.png)


**Unet audio** is one of the software-defined open architecture modems (SDOAMs) that is built using UnetStack technologies that let users convert their computers to an acoustic modem. It uses a computer's sound card along with the speaker and microphone as the hardware to transmit and receive data or signals as instructed by the user.

![](../assets/img/unetaudio/Unetaudio-block.png)

**Unet audio Block Diagram**

## Running Unet audio
1. Make sure your computer meets all the prerequisites as listed in below:
- Operating system: OS X / Linux (x86_64)
- Software: Java 8 runtime environment
- Driver: [PortAudio](http://www.portaudio.com/)
- Browser: Chrome 61+ / Firefox 60+ / Safari 10.1+
2. Head to [www.unetstack.net](www.unetstack.net) and download a copy of the UnetStack community edition.
3. Untar the zip file, open a terminal in the download's root folder and type:
```
> bin/unet audio
Modem web: http://localhost:8080/
```
4. This should start up the SDOAM and open a browser with a command shell accessing the modem. If the browser does not automatically open, just enter the modem web URL shown above in your browser. At the command shell, you can try transmitting a message:
```
> tell 0, 'hello sea!'
AGREE
```

![](../assets/img/unetaudio/Unetaudio-webif.png)

You should hear the transmission from your computer speaker! If you don’t, check your speaker volume and try again.

## Transmitting & receiving using JANUS standard

Unet audio has the ability to transmit and receive using JANUS frames. You can verify this by typing the following on the terminal.

```
> phy[3].janus
true
```

This means that physicial layer scheme 3 supports JANUS functionality.

> NOTE: Unet audio supports various physical layer modulation/demodulation and FEC schemes. Details are available in the [Unet handbook](https://unetstack.net/handbook/unet-handbook.html).

The JANUS-specific messages supported are:
- `TxJanusFrameReq` — AGREE / REFUSE / FAILURE — transmit a JANUS frame
- `RxJanusFrameNtf` — sent to agent’s topic when a JANUS frame is received

In order to transmit a JANUS encoded message directly from physical later, the user can type:

```
> phy << new TxJanusFrameReq()
AGREE
phy >> TxFrameNtf:INFORM[type:#3 txTime:503786432]
```

This broadcasts an empty frame of type JANUS. You should hear the actual transmission through the laptop/computer speaker.

TODO:


## Advantages of using Unet audio
### Portability
Even if you happen to own some UnetStack-compatible acoustic modems, testing with a modem means setting up a dedicated test setup, equipment etc. in a confined water body and dealing with the logistics. With Unet audio, you can test from the comfort of your seat. When you are ready to deploy in a modem, all you have to do is simply copy the code over to the UnetStack-compatible modem and the UnetStack framework takes care of the rest for you.

### Educational tool
Even the cheapest of the underwater acoustic modems comes at a cost and may not be the best option to invest in, if the intended purpose is teaching. Unet audio community edition is free for academic and research use. Students can use their laptops as modems to learn about underwater communications and networking.

### JANUS compatibility
Since we use a sound card as the base hardware, Unet audio provides as acoustic modem that has a centre frequency of 12 kHz. This is the band of operation where the current JANUS specifications are defined. You can check the various details of the modem by typing the following in the webshell:

```
> phy
```
![](../assets/img/unetaudio/Unetaudio-phy.png)



## Conclusion

Unet audio provides an easy method for users to convert their computers to an acoustic modem and get a feel of how things actually happen during a real deployment without incurring any additional cost. It is a great tool for researchers, teachers and students to learn about underwater communications and networking.
