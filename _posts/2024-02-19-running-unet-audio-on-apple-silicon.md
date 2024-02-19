---
layout: post
comments: true
title: Running Unet audio on Apple silicon
date: 14/02/2024
author: Chinmay Pendharkar
categories: howto
feature-img: "assets/img/mbp.jpg"
thumbnail: "assets/img/mbp.jpg"
tags: [howto, unetaudio, unetstack]
---

[Unet audio](https://unetstack.net/handbook/unet-handbook.html#_transmitting_and_recording_arbitrary_acoustic_waveforms) is a great tool for using and testing Unet implementations using UnetStack. Unet audio uses your computer's sound card as an acoustic modem. Almost the entire functionality of UnetStack is available in Unet audio, so you can easily [develop and test Unet Agents](https://unetstack.net/handbook/unet-handbook.html#_developing_your_own_agents), try out [communications algorithms](https://blog.unetstack.net/custom-phy), and even test your scripts and programs written to interact with UnetStack without needing any extra hardware.

![Unet audio](/assets/img/unetaudio.png)

Unet audio binds to your computer's operating system and uses the built-in audio services to send and receive audio from the sound card. This means that some of the libraries used by Unet audio need to be compiled for the specific operating system and architecture.

Until UnetStack 3 Community release v3.4.3, Unet audio was only supported on Linux and macOS on the Intel **x86** architecture. However, with the release of Apple Silicon, and the popularity of Mac computers with the M1/2/3 chips, we have been working to make Unet audio available on the **ARM** architecture.

We are happy to announce that Unet audio is now available on macOS running on Apple Silicon, from [Unet Community v3.4.4](https://unetstack.net/#downloads) onwards.

## Setup Unet audio on Macs with Apple Silicon

Unet audio comes as a part of UnetStack 3 Community releases. You can download the latest release from the [UnetStack 3 downloads section](https://unetstack.net/#downloads).

### Pre-requisites

UnetStack 3 requires Java 8 to be installed on your computer. With the macOS on Apple Silicon, you can run Java 8 compiled for x86 architecture using [Rosetta 2](https://support.apple.com/en-sg/HT211861) or run Java 8 compiled for ARM (aarch64) architecture natively.

Unet audio additionally requires [portaudio](https://www.portaudio.com/) to be installed on your computer. [Homebrew](https://https://brew.sh/) is a great package manager for macOS, and you can use it to install portaudio.

The architecture of the Java 8 (`x86` or `aarch64`) that you have installed on your computer will determine which version of portaudio you need to use. The following table shows the compatibility between the architecture of the Mac, Java 8, and portaudio:

|       Computer CPU       | Java 8 Architecture | Portaudio Architecture |
|:------------------------:|:-------------------:|:----------------------:|
|         Intel x86        |        x86          |         x86            |
| Apple Silicon (aarch64)  |       aarch64       |       aarch64          |
| Apple Silicon (Rosetta)  |        x86          |         x86            |


**Java**

We recommend using the `aarch64` version of Java 8 and other dependencies on your Apple Silicon Mac. [Azul Systems](https://www.azul.com/) provides a great build of Java 8 for ARM, and you can download it from [here](https://www.azul.com/downloads/zulu-community/?os=macos&architecture=arm-64-bit&package=jdk). If you use the [sdkman](https://sdkman.io/) tool, you can install the ARM version of Java 8 using the following command:

```bash
sdk install java 8.0.322-zulu
```

To check which version of Java 8 you are using, you can run the following command:

```bash
> java -version
openjdk version "1.8.0_`XXX`"
OpenJDK Runtime Environment (Zulu 8.`A`.`B`.`C`-CA-macos-aarch64)
```

**Homebrew and Portaudio**

The version of portaudio installed by Homebrew will depend on the version of Homebrew that was installed on your computer. By default, Homebrew installs the native (ARM) version, but it is possible to have an x86 version of Homebrew installed (with Rosetta 2). Check which version of Homebrew you are using by running the following command:

```bash
> which brew
/opt/homebrew/bin/brew
```

An x86 version of Homebrew will return `/usr/local/bin/brew` instead. If you are running an x86 version of Homebrew, we recommend that you switch to the native version of Homebrew.

Once you are using the native version of Homebrew, you can install portaudio using the following command:

```bash
> brew install portaudio
```

You can ensure that the correct version of portaudio is installed by running the following command:

```bash
> file /opt/homebrew/lib/libportaudio.dylib
/opt/homebrew/lib/libportaudio.dylib: Mach-O 64-bit dynamically linked shared library arm64
```

Note the `arm64` in the output.

### Running Unet audio

Once you have installed the correct version of Java 8 and portaudio, you can run Unet audio by unzipping the UnetStack 3 Community release and running the following command in the `unet-v3.4.4` directory:

```bash
bin/unet audio
```

## Accepting Security Permissions on macOS for running Unet audio

When you run Unet audio for the first time, macOS will flag the dynamic libraries that Unet audio uses as being from an unidentified developer.

![Unet audio Security](/assets/img/unetaudio-security.png){: width="50%" }

You will need to be permitted to run these libraries. You can do this by going to `System Preferences` -> `Security & Privacy` -> `General` and clicking on `Allow Anyway` next to the message that says that the libraries were blocked from running.

![Unet audio Security](/assets/img/unetaudio-security-allow.png){: width="70%" }

When you run Unet audio again, you will be prompted to permit to run the libraries. Click on `Open` to permit to run the libraries.

![Unet audio Security](/assets/img/unetaudio-security-open.png){: width="50%" }

You might have to run the `bin/unet audio` command again after permitting the libraries to run. You should only have to do this once, and Unet audio will run without any issues in the future.

---

<small> Photo by <a href="https://unsplash.com/@alesnesetril?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Ales Nesetril</a> on <a href="https://unsplash.com/photos/gray-and-black-laptop-computer-on-surface-Im7lZjxeLhg?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a> <small>

