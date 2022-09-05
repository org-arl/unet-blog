---
layout: post
comments: true
title: Project Sabine - Low-cost DIY underwater modem using COTS components and Unet audio
date: 20/9/2022
author: Manu Ignatius, Sukanta K. Hazra
categories: howto
feature-img: "assets/img/stdma/stdma-unet.jpg"
thumbnail: "assets/img/stdma/stdma-unet.jpg"
tags: [howto, unetaudio, unetstack, modems, phy, janus, sabine]
---

## Introduction
A true Software-Defined Open Architecture Modem (SDOAM) can easily be extended to run on various hardware platforms with minimal efforts to address different use cases. In the article titled [Converting your laptop into a JANUS modem using Unet audio](https://blog.unetstack.net/converting-your-laptop-into-a-janus-modem-using-unetaudio), we saw how UnetStack, a true SDOAM, can be used to turn your laptop into an acoustic modem. In this article, we will show how you can build a low-cost, DIY underwater acoustic modem using only COTS components and Unet audio. The goal of this article is to demonstrate the approach and basic steps one can use to build an acoustic modem using Unet audio We encourage the user to use the principles illustrated to build other versions that improves the build quality or performance.

## Motivation and proposed solution
Most commercially available modems are beyond the reach of a technology enthusiast or a hobbyist underwater roboticist, due to their price point. However, applications such as DIY AUVs (e.g. [The Singapore AUV Challenge](https://sauvc.org/)), low-cost swarms, etc. need low-cost underwater acoustic modems to realize their true potential. While there have been projects like the [AHOI modem](https://dl.acm.org/doi/10.1145/3376921), [SeaModem](https://ieeexplore.ieee.org/document/7271721), [Seatrac](https://ieeexplore.ieee.org/document/7271578), all of them has a hardware component associated with it. This means the user needs to spend time building the hardware, which can be cumbersome and time-consuming. Adding additional hardware to a micro-AUV can be challenging due to space and power limitations. Ensuring long-term support for these can also be tricky, depending on the author's prior commitments.

All of the above constitute a large barrier of entry for anyone looking to use one of the existing projects to build on.

Project Sabine addresses these by using Unet audio in a commonly available hardware platform such as Raspberry Pi and using its sound card to transmit and receive using an underwater speaker and mic. This approach allows the user to run Unet audio in their single board computer (SBC) thereby avoiding the need for a dedicated digital hardware. The analog electronics can then be chosen based on the application. By using UnetStack, the user gets access to all the developer tools and the extendability to build their own protocols on top of the acoustic modem. Long term support is guaranteed due to the use of UnetStack community edition.

## Hardware selection

The overview of the modem architecture is as shown in figure 1.

TODO: Image



### Digital Hardware

One of the most important hardware component of an SDOAM is the digital hardware that runs the software. We have selected a Raspberry Pi (3b+) due to its popularity, low cost, ease of availability and community support to be the digital hardware to run Unet audio. A USB sound card connected to the Rapberry Pi is used as the data acquisition system. The speaker output acts as the digital-to-analog (DAC) convertor and the mic (or line in? TODO) in acts as the analog-to-digital convertor (ADC). Based on the sound cards specification, our modems bandwidth will be from TODO to TODO.

> NOTE: The internal audio output was not used as it is disabled by default during setup.

<p align="center"><img width="50%" src="../assets/img/sabine/rpi.png"/></p>
<p align="center"><em>Raspberry Pi</em></p>



<p align="center"><img width="50%" src="../assets/img/sabine/sc.png"/></p>
<p align="center"><em>USB soundcard</em></p>

### Transmit Chain

The next step is the selection of the power amplifier and the transducer. In order to keep the costs down, we have decided to use an underwater speaker [JH001](http://www.jiaxiangwang.com/spen/product.htm) along with a COTS power amplifier.

<p align="center"><img width="50%" src="../assets/img/sabine/tx.png"/></p>
<p align="center"><em>JH001 Underwater Speaker</em></p>

Since the JH001 can output up to 30 W of power, we have used both TODO and TODO with success. Most standard TDA series (e.g. TDA2030) mono amplifiers should work fine. The user may choose the power amplifier depending on your application.



<p align="center"><img width="50%" src="../assets/img/sabine/pa.png"/></p>
<p align="center"><em>Power Amplifier</em></p>



### Receive Chain

For the input chain, we use an electret microphone connected to the sound card.

<p align="center"><img width="50%" src="../assets/img/sabine/mic.png"/></p>
<p align="center"><em>Electret Microphones</em></p>

Before deploying these underwater, we will need to waterproof them. The items we need to waterproof the mic are as follows.

1. Chair bush: To be used as the backing for the mics. choose a size that fits the electret microphone tightly. Usually available in local hardware stores.
2. Cling wrap: For waterproofing the front of the electret microphone. The thinner the better.
3. Glue gun with glue stick: Used for waterproofing.
4. 3.5mm mono audio jack: Connector for the sound card. If unable to find a mono jack, we can use a standard stereo jack as well. Either use only the left channel or short both the channels. Both schemes work.
5. Wires: To connect the mic to sound card.

<p align="center"><img width="70%" src="../assets/img/sabine/comp.png"/></p>
<p align="center"><em>Components for waterproofing</em></p>

### Waterproofing

One of the terminals of the electret microphone is connected to the case, and is the ground terminal. Connect that to the audio jack ground. The other terminal is output and is connected to the other two (or one in case of mono) connectors of the audio jack.

<p align="center"><img width="40%" src="../assets/img/sabine/connect.png"/></p>
<p align="center"><em>Mic pinout</em></p>

<p align="center"><img width="50%" src="../assets/img/sabine/cd.png"/></p>
<p align="center"><em>Connection diagram</em></p>



To waterproof the microphone, use a chair bush of size that fits tightly around it. Make a hole in the closed part of the bush just large enough for the wire. Put the wire through the hole and then pour a sufficient quantity of hot glue to create a good seal and push in the microphone. The microphone should be pushed in in a way that it protrudes out a bit, just enough for the black diaphram at the front to protrude out a bit from the bush. Let the hot glue dry.

Next wrap some cling wrap to waterproof the front portion. You can pour some hot glue on the outside surface of the bush and then wrap the cling wrap over the front of the microphone making sure that there is no gap between the cling wrap and the black diaphragm. If there is air gap, then the performance might be affected.

<p align="center"><img width="50%" src="../assets/img/sabine/hydrophone1.png"/></p>
<p align="center"><img width="50%" src="../assets/img/sabine/hydrophone2.png"/></p>
<p align="center"><em>Waterproofed mic</em></p>



## Putting them all together

### Transmit chain

Connect the speaker output from the USB audio adapter to the amplifier module input and the amplifier output to the underwater speaker. Depending on the power amplifier used, it can be powered using the USB output of the RPi or a 12V motorcycle battery.

<p align="center"><img width="70%" src="../assets/img/sabine/txc.png"/></p>
<p align="center"><em>Transmit chain</em></p>

### Receive chain

The electret microphone is connected to the USB audio adapter plugged into the RPI.

<p align="center"><img width="70%" src="../assets/img/sabine/rxc.png"/></p>
<p align="center"><em>Receive chain</em></p>

### Bill of materials

| Item                                    | Qty  | Cost |
| --------------------------------------- | ---- | ---- |
| Raspberry Pi                            | 1    |      |
| USB sound card for RPi                  | 1    |      |
| Power amplifier                         | 1    |      |
| Underwater speaker                      | 1    |      |
| Electret microphone                     | 1    |      |
| 3.5mm audio jack                        | 2    |      |
| Bush, glue gun, glue stick, cling wrap, | 1    |      |

> NOTE: It is recommended to get more than 1 for the electret microphone, audio jacks etc. in case of damage during assembly

## Software installation

### Requirements

- Raspberry Pi 3+
- USB Sound Card
- Headphones/Loudspeaker
- Microphone

### Setup

#### OS 

1. Install the latest [Raspbian](https://www.raspberrypi.org/software/operating-systems/) on your Raspberry Pi

#### Audio

1. Plug-in a USB Audio Card into your Raspberry Pi
2. Power-on your Raspberry Pi
3. Ensure that the USB Audio Card is detected using `aplay -l`

```
> aplay -l
card 0: ...
card 1: Audio [USB Audio], device 0: USB Audio [USB Audio]
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```
4. Disable the RaspberyPi onboard sound card , by commenting out the line `dtparam=audio=on` in `/boot/config.txt`

```
> sudo nano /boot/config.txt

# Enable audio (loads snd_bcm2835)
# dtparam=audio=on
```

5. Make the USB Audio card the default device in alsa by updating `defaults.ctl.card` and `defaults.pcm.card` to `1` in `/usr/share/alsa/alsa.conf`

```
defaults.ctl.card 1
defaults.pcm.card 1
```

6. Reboot your Raspberry Pi and verify that `card 0:` is not enumerated by `aplay -l`

```
> aplay -l
card 1: Audio [USB Audio], device 0: USB Audio [USB Audio]
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```

7. You can test if your audio setup works properly using  `speaker-test -c2`

### Dependencies

1. Install Java8

```sh
wget https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u265-b01/OpenJDK8U-jdk_arm_linux_hotspot_8u265b01.tar.gz
tar xzf OpenJDK8U-jdk_arm_linux_hotspot_8u265b01.tar.gz
rm jdk8u265-b01/src.zip
sudo mkdir -p /usr/lib/jvm/java-8-openjdk-armhf
mv jdk8u265*/* /usr/lib/jvm/java-8-openjdk-armhf/
rm -r jdk8u265*
rm OpenJDK8U-jdk_arm_linux_hotspot_8u265b01.tar.gz
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-armhf" >> $HOME/.bashrc
echo "export PATH=\$PATH:/usr/lib/jvm/java-8-openjdk-armhf/bin" >> $HOME/.bashrc
```

2. Download [portaudio for Linux](http://files.portaudio.com/download.html)
3. Build and install [Portaudio](http://files.portaudio.com/docs/v19-doxydocs/compile_linux.html)

```sh
sudo apt-get install libasound-dev

...

./configure && make

...

sudo make install

...

sudo ldconfig

```

### Run UnetStack

1. Get the UnetAudio Community distribution for RaspberryPi
2. Copy the `unet-community-3.1.0.tgz` file to the Raspberry Pi
3. Unzip the file `tar -xvzf unet-community-pi-3.1.0.tgz`
4. Go to the `~/unet-3.1.0` directory
5. Run UnetAudio `bin/unet -c audio`

Once `Unet audio` is running, user can access the web interface by typing the IP address of your RPi on a browser.

## Testing and results

A simple test setup was created as shown below with two Raspberry Pis, one was configured as a transmitter and the other as a receiver.

TODO: Figure

The following commands were used to transmit data.

```
> tell, "hello unet"
```

It was received at the receiver as shown below:

```
TODO
```

TODO: Tonal transmission, arbitrary waveform transmission and rx using TC4013.



## Conclusion

Using Unet audio, we have illustrated how to build a simple DIY acoustic modem that is of low cost. 


