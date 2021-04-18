---
layout: post
comments: true
title: What's new in UnetStack 3.3?
date: 1/4/2021
author: Mandar Chitre
categories: info
feature-img: "assets/img/unetstack3.3.jpg"
thumbnail: "assets/img/unetstack3.3.jpg"
tags: [unetstack]
---

It is April again, and that means it is time for the next release of UnetStack! We are excited to bring several new features to you -- a new JSON event logging framework for automated analysis of multi-agent protocols, support for signal strength and ambient noise level reporting in the Unet simulator, and experimental support for Julia agents! In addition, UnetStack 3.3 also incorporates numerous enhancements, bug fixes and performance improvements.

<!--p style="text-align: center;"><a href="https://youtu.be/qFEYA1DlffI" target="_blank" style="font-size: 20px; text-decoration: none;">[ Watch a short video about what's new in UnetStack 3.3 ]</a></p-->

Let's take a brief look at the key new and exciting features:

#### 1. JSON event tracing framework

When Unet simulator was first developed, we adopted the `trace.nam` file format from NS2 for event logging, since many users in the community were already familiar with it. While it served its purpose in the initial days, as agents became more sophisticated and interactions between agents more complicated, we received feedback from many users that they wanted a richer trace format that can be used for automated analysis of multi-agent protocols. We are happy to announce a new JSON trace format that provides a much richer trace that can be easily analyzed using most modern languages with JSON support.

When running a simulation, a JSON trace file `trace.json` is automatically generated in the `logs` folder. This file contains a detailed trace for every event in the network stack, on each node. You can even enable trace file generation on real modems and other Unet nodes (using `EventTracer.enable()`), and later combine the traces from multiple nodes to analyze network protocol operation and performance.

A small extract from a typical trace file is shown below:

```json
{"version": "1.0","group":"EventTrace","events":[
 {"group":"SIMULATION 1","events":[
  {"time":1617877446718,"component":"arp::org.arl.unet.addr.AddressResolution/B","threadID":"0bfb305d-4920-4df0-af95-5282b048b5ec","stimulus":{"clazz":"org.arl.unet.addr.AddressAllocReq","messageID":"0bfb305d-4920-4df0-af95-5282b048b5ec","performative":"REQUEST","sender":"node","recipient":"arp"},"response":{"clazz":"org.arl.unet.addr.AddressAllocRsp","messageID":"3e421e28-89ca-44ec-bc65-16cc404d3703","performative":"INFORM","recipient":"node"}},
  {"time":1617877446718,"component":"arp::org.arl.unet.addr.AddressResolution/A","threadID":"04f5b1b9-9178-4e27-aae7-e2a0c4ffcd89","stimulus":{"clazz":"org.arl.unet.addr.AddressAllocReq","messageID":"04f5b1b9-9178-4e27-aae7-e2a0c4ffcd89","performative":"REQUEST","sender":"node","recipient":"arp"},"response":{"clazz":"org.arl.unet.addr.AddressAllocRsp","messageID":"e0fe806d-625d-4261-b24c-6655b90cc06a","performative":"INFORM","recipient":"node"}},
      :
      :
 ]}
]}
```

The trace is organized into a hierarchy of groups, each describing a simulation run or the execution of specific commands. A group consists of a sequence of events, with each event providing information on time of event, component (agent running on a node), thread ID, stimulus and response. The stimulus is typically a message received from another agent, and response a message sent to another agent. The thread ID ties multiple events, potentially across multiple agents and nodes, but with the same root cause together.

Integrating the event tracing framework into your own agents is simple. All you need to do is to wrap messages that you generate in response to a stimulus with a `trace()` call. Some examples:

```groovy
send trace(stimulus, new DatagramDeliveryNtf(stimulus))
request trace(stimulus, req), timeout
```

All the default agents in UnetStack 3.3 are now compliant with the JSON event logging framework.

#### 2. Automated trace analysis tool (experimental)

To illustrate the power of the event logging framework, we have built a simple [viztrace tool](https://github.com/org-arl/unet-contrib/tree/master/tools/viztrace) to automatically draw sequence diagrams from a JSON trace file. The tool is written in Julia, and will require a working installation of [Julia](https://julialang.org/downloads/) along with packages `ArgParse` as well as `JSON` on your machine to run.

To illustrate the power of the tool, let us simulate a simple [2-node network](https://unetstack.net/handbook/unet-handbook_getting_started.html) and make a range measurment from node A to B. On node A:

```
> range host('B')
999.99976
```

If you look in the `logs` folder in the simulator, you'll find a `trace.nam` file. We can analyze it using the `viztrace` tool:

```sh
$ julia --project viztrace.jl trace.json
Specify a trace:
1: 1617881734525 [B] AddressAllocReq ⟦ node → arp ⟧ (1 events)
2: 1617881734525 [A] AddressAllocReq ⟦ node → arp ⟧ (1 events)
3: 1617881734531 [A] AddressResolutionReq ⟦ websh → arp ⟧ (1 events)
4: 1617881734595 [A] RangeReq ⟦ websh → ranging ⟧ (23 events)
```

So the tool tells us that there are 4 event traces in the `trace.json` file. The first 2 traces are related to address allocations on nodes B and A. The third trace is an address resolution for node B, when we called `host('B')`. The final trace is the actual ranging event, consisting of 23 individual sub-events. Let's explore that in more detail:

```sh
$ julia --project viztrace.jl -t 4 trace.json > event4.mmd
```

This generates a [mermaid](https://mermaid-js.github.io/) sequence diagram for all the events in trace 4:

```
sequenceDiagram
  participant websh_A as websh/A
  participant ranging_A as ranging/A
  participant mac_A as mac/A
  participant phy_A as phy/A
  participant phy_B as phy/B
  participant ranging_B as ranging/B
  websh_A->>ranging_A: RangeReq
  ranging_A-->>websh_A: AGREE
  ranging_A->>mac_A: ReservationReq
  mac_A->>ranging_A: ReservationRsp
  mac_A->>ranging_A: ReservationStatusNtf
  ranging_A->>phy_A: ClearReq
  phy_A-->>ranging_A: AGREE
  ranging_A->>phy_A: TxFrameReq
  phy_A-->>ranging_A: AGREE
  phy_A->>ranging_A: TxFrameNtf
  phy_A->>phy_B: HalfDuplexModem$TX
  phy_B->>ranging_B: RxFrameNtf
  ranging_B->>phy_B: ClearReq
  phy_B-->>ranging_B: AGREE
  ranging_B->>phy_B: TxFrameReq
  phy_B-->>ranging_B: AGREE
  phy_B->>ranging_B: TxFrameNtf
  phy_B->>phy_A: HalfDuplexModem$TX
  phy_A->>ranging_A: RxFrameNtf
  ranging_A->>websh_A: RangeNtf
  ranging_A->>mac_A: ReservationCancelReq
  mac_A-->>ranging_A: AGREE
  mac_A->>ranging_A: ReservationStatusNtf
```

We can easily convert this to a nice sequence diagram using the [mermaid command-line interface](https://github.com/mermaid-js/mermaid-cli) or the [mermaid online live editor](https://mermaid-js.github.io/mermaid-live-editor):

![](assets/img/mermaid-diagram-20210408195013.svg)

#### 3. Signal strength and ambient noise level reporting

While most UnetStack-based modems support reporting of ambient noise level and received signal strength indicator (RSSI), the simulated `HalfDuplexModem` in UnetStack did not previously provide this information. With UnetStack 3.3, it does!

With the simulated [2-node network](https://unetstack.net/handbook/unet-handbook_getting_started.html), for example:

```
> phy.noise
96.1236
```

tells us that the ambient noise level is 96.1 dB. If we subscribe to the `phy` agent on node B and transmit a frame from node A, we see RSSI of 112.4 dB in the notification on node B:

```
phy >> RxFrameStartNtf:INFORM[type:CONTROL rxTime:973249369]
phy >> RxFrameNtf:INFORM[type:CONTROL from:232 rxTime:973249369 rssi:112.4]
```

This information may be useful to agents that automatically adapt transmit power or other link parameters based on signal strength or signal-to-noise ratio.

#### 4. Julia agents (experimental)

As we have seen in two previous blog articles ([part I]({% post_url 2020-08-28-harnessing-the-power-of-julia-in-unetstack %}), [part II]({% post_url 2020-11-01-custom-phy-in-julia %})), the power of Julia can be harnessed by UnetStack agents via [UnetSockets.jl](https://github.com/org-arl/UnetSockets.jl) or the [Java-Julia bridge](https://github.com/org-arl/jajub). While this is great, wouldn't it be even better if we could write UnetStack agents fully in Julia?

Well, now you can! We now have experimental support for first-class Julia agents in UnetStack via [Fjage.jl](https://github.com/org-arl/Fjage.jl). Stay tuned for an upcoming blog article on how to write a custom PHY as a first-class Julia agent!

#### 5. Numerous other improvements

There are many other enhancements, bug fixes and performance improvements in UnetStack 3.3. While we won't list of of them explicitly, there are a few enhancements that are worth a passing mention:

- Added `NodeInfo` service parameters for `roll` and `pitch`, allowing UnetStack on autonomous underwater vehicles (AUVs) to use orientation information in making intelligent decisions.
- On modems supporting low power _sleep mode_, an `AboutToSleepNtf` message is broadcasted before a modem goes to sleep, enabling agents to do housekeeping before taking a nap.
- Add `eternity` as an alias for `forever` for sleep scheduling shell commands.
- Improved communication performance for UdpLink and acoustic OFDM links.
- Added support for 32x upsampling and 16x decimation to support additional frequency bands of operation.
