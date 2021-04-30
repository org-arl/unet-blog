---
layout: post
comments: true
title: Frequency band control using UnetStack
date: 21/04/2021
author: Shiraz S
categories: howto
feature-img: "assets/img/freqBandControl/title.png"
thumbnail: "assets/img/freqBandControl/title.png"
tags: [howto, unetstack, modems, phy, frequency, band, fdma]
---

## The basics

An underwater acoustic modem essentially sends out sound signals underwater to transmit information. The typical transmit processing takes in user's binary data and after error correction encoding, modulates a carrier according to some modulation scheme such as OFDM or FHBFSK, the details of which the reader can understand from other sources. 

For readers using Unet audio, the centre frequency C = 12 kHz, the complex baseband rate R = 12000 and the total bandwidth B = 12 kHz. So it goes from 6 kHz to 18 kHz.

For readers using a UnetStack-based modem such as Subnero standard medium frequency modems, the fundamental centre frequency C = 24 kHz. The baseband complex signals are clocked out via the DAC (Digital to Analog Converter) at the rate of R = 24000 samples/s, which translates to a total bandwidth of B = 24 kHz (we shall omit the details of wireless communication theory in this blog). So the band goes from 12 kHz to 36 kHz. 

For the illustrations in this blog we shall use Unet audio mainly. Change C, R and B according to the modem applicable to the reader.

The reader may wish to install Unet and Unet audio and try out some basic examples to make sure it is working. The following sections can be tried out in Unet audio.

### The need to control centre frequency and bandwidth 

Acoustic modems transmit physical sound waves via a transducer, typically a piezo electric device. Such sound emitters have an ideal resonance frequency F and a Q factor of the order of 0.3. This means that the efficient region of the frequencies it can transmit centres around the resonance frequency with a bandwidth of about 0.3 x F. Q may be higher or lower depending on the exact transducer.

The transducer in medium range Subnero modem (M25M) has a transducer with a resonance close to 26 kHz. The computationally possible bandwidth is 24 kHz as mentioned earlier, but not all of this bandwidth is feasible for the transducer. Thus the recommended default bandwidth is B = 12 kHz, which is half of the total posible. Thus an effective transmit modulation scheme can be set such that the centre C = 26 kHz and B = 12 kHz.

Another reason may be due to acoustic underwater channel characteristics. A most basic property is that higher frequencies get absorbed more and in general have lower transmission range. For this or other reasons related to the channel, the modem user may want to customize the frequencies transmitted by the modem. 

Multiple Access is another case where users may want to control the band used in each modem. One common multiple access method is Frequency Domain Multiple Access (FDMA). In this scheme, different modems or modem pairs may be allocated a different frequency band for transmission to avoid collision. Simultaneous transmission-reception by two or more different and colocated modem pairs are possible using FDMA. 

Sometimes, there may be a frequency band the user may want to exclude from usage, due to it being occupied by other sources, noise etc. 

## Understanding baseband signal generation, transmission 

Readers may skip this section if you only want to know how to adjust FH-BFSK or OFDM parameters of 
a UnetStack-based modem.

The purpose of this section, is to provide a basic understanding of how baseband signals are created and their frequency content. We can try out how it works in UnetStack-based modems using some examples.

We shall use Binary Phase Shift Keying (BPSK) for this exercise.

Create a baseband complex signal as follows. A complex baseband signal point [1,0] refers to the real and imaginary components of one baseband sample. So in the following signal, all imaginary values are 0.
```
> s = [1,0]*12000
[1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 <<snip>> 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]

```

Transmit this 1s long signal (12000 samples at a sample rate of 12 kHz).

```
> phy << new TxBasebandSignalReq(signal: s)
AGREE
phy >> TxFrameStartNtf:INFORM[txTime:100610682 txDuration:1000416]
phy >> TxFrameNtf:INFORM[txTime:100593099]
```
You should hear a tone sent out by the Unet audio running in the laptop.

Passband PSD plot from the diagnostics scope shows this carrier only signal at nearly 12 kHz.

(settings used: plvl = -25, plot trigger set to -60, you can experiment with power and trigger to get a snapshot depending on your environment)

<p align="center"><img src="../assets/img/freqBandControl/tone.png" style="zoom:50%;"/></p>

The following will send out a 1s BPSK signal with constellation (-1, 1) at the highest rate possible, i.e., every alternating complex sample is (+1,0) followed by (-1,0). 

```
> s = [1,0, -1, 0]*6000
[1, 0, -1, 0, 1, 0, -1, 0, 1, 0, <<snip>> -1, 0, 1, 0, -1, 0, 1, 0, -1, 0]

> phy << new TxBasebandSignalReq(signal: s)

```

Passband PSD plot from the diagnostics scope showing the main frequencies at 6 kHz and 18 kHz implying full use of the band 6 to 18 kHz.
<p align="center"><img src="../assets/img/freqBandControl/bpsk-high.png" style="zoom:50%;"/></p>


The following will send out a 1s BPSK signal at a half the highest rate possible. 

```
> s = [1,0, 1, 0, -1, 0, -1, 0]*3000
[1, 0, -1, 0, 1, 0, -1, 0, 1, 0, <<snip>> -1, 0, 1, 0, -1, 0, 1, 0, -1, 0]

> phy << new TxBasebandSignalReq(signal: s)

```

Passband PSD plot from the diagnostics scope showing the main frequencies at 9 kHz and 15 kHz implying use of 6 kHz bandwidth
<p align="center"><img src="../assets/img/freqBandControl/bpsk-low.png" style="zoom:50%;"/></p>

Note that in the strict sense, unless a band limiting RRC (Raised Root Cosine) filter or equivalent is used, the effective bandwidth does not reduce correctly for BPSK with random binary data. The proper implementation of BPSK or general PSK is not aimed in this blog.

The above is intended to give the reader a flavour of how frequency band used changes with signals. The reader no doubt will be interested in testing different types of modulation schemes, and using the PSD scope, the frequency band used can be visualized. Surely it can also be estimated from communication theory.

## OFDM frequency band control

OFDM is one of the main modulation schemes provided with UnetStack-based modems. It is the default DATA channel in UnetStack modems. Controlling the bandwidth and centre of the frequency band used is very simple for this scheme.

OFDM uses a number of carriers to modulate the baseband data and the number is specified via `phy[2].nc`. These carriers span the total available bandwidth (24 kHz for Medium Frequency Subnero modem variants), i.e., from 12 kHz to 36 kHz. 

The parameter `phy[2].bw`. controls a reduction in the usage of this total bandwidth. I.e., if we specifiy phy[2].bw = 0.5, it reduces the bandwidth used by half, i.e, 24 kHz / 2 = 12 kHz. 

The other parameter involved in bandwidth control is `phy[2].dc0`. This controls the starting carrier number. 

`dc0 >= -nc/2 || dc0 <= nc/2`

This can be used to shift the centre of the frequency band "left" or "right". 

As mentioned above, to set the band to match the transducer, we need C = 26 kHz and B = 12 kHz.

The default modem parameters are set as follows to achieve this.
```
> phy[2]
  ...
  bw = 0.5
  dc0 = 85
  nc = 1024
```

`phy.dc0=85` shifts the centre by approximately 2000 Hz. Carriers go from -512 to +512 to span the band 12 kHz to 36 kHz. 85/512 ~= 1/6, so the centre will shift roughly by 1/6 of 12 kHz = 2000 Hz (
the positive half band) to 26 kHz from 24 kHz.


phy[2].bw = 0.5 will reduce the active carriers by half, so a bandwidth of 12 kHz. Thus together, the used bandwidth will go from 20kHz to 32kHz.

For Unet audio, the same settings will shift the centre by 1 kHz to 13 kHz with a bandwidth of 6 kHz. Therefore from 10kHz to 16kHz, this is seen below (plvl = -25, trigger -70, may vary for user).

<p align="center"><img src="../assets/img/freqBandControl/ofdm-psd.png" style="zoom:50%;"/></p>

Note that if there is a frequency band to be avoided, we can position the used band to the "left" or "right" of it by adjusting `nc`, `dc0` and `bw`. Note that going far away from the ideal transducer resonance region will reduce transmission efficiency. 

The usage and meaning of parameters can be found in [Command Reference](https://unetstack.net/handbook/unet-handbook.html#_command_reference)

## FHBFSK frequency band control

For FHBFSK scheme, the parameter `phy[3].fmin` specifies the starting frequency. `phy[3].fstep` specifies the frequency steps and  `phy[3].hops` the total number of frequencies used. 

By default you may see in the Unet audio modem 
```
> phy[3]
  ...
  fmin = 9520.0
  fstep = 160.0
  hops = 13
```

So it starts from 9520 Hz and goes to 9520 + 160 x (13-1) x 2  = 13360 Hz as seen below. 
The effective bandwidth can be roughly taken as fstep x hops x 2.


<p align="center"><img src="../assets/img/freqBandControl/fhbfsk-psd.png" style="zoom:50%;"/></p>


We can alter the above parameters to use a band anywhere between 6 kHz and 18 kHz, which is the computationally feasible band of the Unet audio modem. 

Note that just as in OFDM, if there is a frequency band to be avoided, we can position the used band to the "left" or "right" of it by adjusting `fmin`, `fstep` and `hops`.

The default CONTROL channel in UnetStack-based modems is such an FHBFSK scheme.

## Control of Preamble bandwidth

To complete the picture of bandwidth control, it must be noted that the signal that is transmitted not only has a data modulated portion, but also a detection preamble at the start. This is usually a pseudo random noise signal or m-sequences, hyperbolic chirp (HFM) etc that has good auto correlation properties. 

[Preamble class](https://unetstack.net/javadoc/3.3/org/arl/yoda/Preamble.html) provides both the above types of preambles via the methods such as mseq(..), hfmUpSweep(..), hfmDownSweep(..).
It allows controlling the bandwidth and centre frequency of the preamble.

Let's look at one of them
`public static Preamble hfmDownSweep(int len, int sps, float fc)`
- `len` is the number of baseband samples
- `sps` controls the bandwidth
  Preamble bandwidth = baseband bandwidth/sps. Note that sps must be an integer.
  Thus for Unet audio, sps = 4 creates a bandwidth of 12 kHz / 4 = 3 kHz.
- `fc` controls the centre frequency. This is normalized to the baseband rate. So for Unet audio, `fc = 0.25` will shift the carrier by 12 kHz x 0.25 = 3 kHz. i.e., from 12 kHz to 15 kHz. 

For e.g., the following creates an HFM down sweep signal with 1000 baseband samples, bandwidth of 3 kHz, centered at 15 kHz.
```
> phy[3].preamble = org.arl.yoda.Preamble.hfmDownSweep(1000, 4, 0.25)
(1000 samples)

```
To transmit this preamble alone (with no additional signal)

```
> phy << new TxBasebandSignalReq(preamble: 3)
```

In the diag scope, let us look at the passband PSD. With an appropriate trigger, you may get something as follows. It clearly shows the centre of 15 kHz and the bandwidth of 3 kHz.

<p align="center"><img src="../assets/img/freqBandControl/preamble.png" style="zoom:50%;"/></p>

The user can also generate and set custom preambles. 


## Conclusion

There is a need to control the frequency band of operation in acoustic modems and we have seen how easy it is to control it in both OFDM and FHBFSK schemes in the UnetStack-based modems. For other custom modulation schemes, the user can adopt methods based on the simple BPSK illustration provided above.



