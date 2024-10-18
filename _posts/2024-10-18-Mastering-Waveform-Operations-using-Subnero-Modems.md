---
layout: post
comments: true
title: Mastering Waveform Operations using Subnero Modems.md
date: 18/10/2024
author: Manu Ignatius
categories: howto
feature-img: "assets/img/modems-2024.jpg"
thumbnail: "assets/img/modems-2024.jpg"
tags: [howto, modems, baseband]
---

In underwater communication, where environmental factors such as noise, multipath, Doppler etc. significantly influence performance, it becomes crucial to understand the channel conditions. To gain insights, users often need to record the channel and transmit pilot signals that are not typical communication signals. Additionally, some users may have custom communication signals different from those provided by vendors, requiring flexibility in transmission. This need is prevalent in fields like scientific research and defense, where the ability to transmit and receive arbitrary waveforms within the available frequency band is essential. Subnero modems address these needs by offering multiple methods for both recording and transmitting user-defined signals, providing versatile solutions for various use cases. This article explores the different approaches Subnero modems support for recording and transmitting arbitrary waveforms.

## Recording Incoming Waveforms
There are multiple methods for capturing incoming waveforms, each catering to specific use cases:

### 1. Recording a Set Number of Samples
This method is ideal when you need to capture a specific number of samples. You can trigger the recording immediately or schedule it for a specific time using the `bbrec` command. For example, `bbrec 1000` will record 1000 baseband samples. The samples recorded are in the baseband format.

Subnero modems utilize the UnetStack framework, which employs internal messages for communication among different UnetStack agents. The bbrec command internally utilizes the `RecordBasebandSignalReq` to record the samples. `bbrec 1000` is analogous to `bb << new RecordBasebandSignalReq(1000)`.

The recorded samples are returned as part of the `RxBasebandSignalNtf` notification and are not written to a file. To do that, you may send the notification to the baseband monitor agent as follows.

```
bbmon.enable = true
bbmon.send ntf
```

Note that this method does not support recording of passband samples.

### 2. Continuous Sample Reception (Streaming)
This method is designed for scenarios where a user application (e.g., a physical layer running on a coprocessor) requires a continuous stream of incoming waveform data for processing. Users have the flexibility to stream either passband or baseband data. The `bbscnt` and `pbscnt` parameters in the baseband agent control this capability.

Setting `bb.bbscnt` or `bb.pbscnt` to 1 will record a single block of baseband or passband data respectively. The block size can be configured using the `bb.bbsblk` or `bb.pbsblk` parameter. Setting `bb.bbscnt` or `bb.pbscnt` to -1 will initiate continuous streaming.

This action generates an `RxBasebandSignalNtf`, which the user application can listen to in order to extract the signal recording.

It is important to note that while users can stream both passband and baseband data, baseband sampling is the preferred approach due to smaller messages, lower computational load on the modem, and less storage/memory requirements. Overloading the modem CPU could lead to dropped samples.

### 3. Recording to Storage
This method lets you directly store captured passband waveform data on the modem's storage for later analysis or retrieval. This is useful for diagnostic purposes. To enable this feature, use the command `bb.record=true`. The modem will then create a binary file named `rec-<timestamp>.dat` containing the passband data. This file can later be downloaded from the modem for analysis.

### 4. Capturing detected signals to a file
The bbmon agent (baseband monitor agent) offers a valuable tool for capturing a specific number of samples following a trigger detection (`RxBasebandSignalNtf`) from the baseband agent. When enabled, `bbmon.enable=true`, all detections (`RxBasebandSignalNtf`) from the baseband agent will be recorded to a file named `signals-<timestamp>.txt`, allowing for later retrieval. This file can be loaded later using utilities provided in the [arlpy package](https://arlpy.readthedocs.io/en/latest/) for ease of processing.

It is to be noted that option 3 is the suggested choice for data storage of streaming data over a long duration. The `rec-<timestamp>.dat` file produced by this option is smaller as it stores information in binary format. Furthermore, it offers file rotation support.

Storing streaming data over long term to the `signals-<timestamp>.txt` file is not recommended as the file size can get large. However, if this is required, the user can get the bbmon agent to subscribe to the baseband or passband streaming topic using the `command container.getAgent(bbmon).subscribe topic(bb, 'bbstream')` or `container.getAgent(bbmon).subscribe topic(bb, 'pbstream')`. Once this is done, the bbmon agent will record all `RxBasebandSignalNtf` from streaming to the signals file.

## Transmission of Arbitrary Waveforms
Users can transmit baseband or passband data by employing the `bbtx` or `pbtx` commands respectively. These commands internally utilize the `TxBasebandSignalReq` message. The commands enable users to transmit a specified number of samples at a specified time.

More on the baseband service can be found here: https://unetstack.net/handbook/unet-handbook_baseband_service.html
