---
layout: post
comments: true
title: What's new in UnetStack 7?
date: 14/09/2026
author: Mandar Chitre
categories: info
feature-img: "assets/img/unetstack7.jpg"
thumbnail: "assets/img/unetstack7.jpg"
tags: [unetstack, julia, agents, phy, simulation]
---

It has been a while since our last community release. UnetStack 3.3 came out in April 2021, and things may have seemed quiet since then. But we have been busy upgrading UnetStack!

The big change after UnetStack 3 came in v4, with support for Julia containers. This mattered a lot, because it meant that signal processing and physical-layer (PHY) algorithms could be written in a high-level language like Julia, instead of in C. Synchronization, detection, equalization, channel estimation, modulation, demodulation -- all of these become much easier to implement and debug when you can write them in a few lines and run them straight away. We had already explored some of this in previous blogs -- [Harnessing the power of Julia in UnetStack -- Part I](https://blog.unetstack.net/harnessing-the-power-of-julia-in-unetstack) and [Part II](https://blog.unetstack.net/custom-phy-in-julia), and in [Developing your own acoustic PHY with UnetStack](https://blog.unetstack.net/custom-phy). But, at that time, we required some awkward Java-Julia bridge glue to make it work. Now Julia agents are first-class citizens of UnetStack!

As we expanded UnetStack this way, people were able to do a lot more with it. However, we found that many parts of the stack could be improved. Service contracts were loose in places. Some APIs had grown inconsistent over the years. Performance needed attention. Documentation had fallen behind. UnetStack 5 and 6 were largely about fixing all of that: cleaning up APIs, adding regression tests, improving performance, and rewriting the service contracts so that what they say and what the code does are the same thing. UnetStack 4--6 made it to various modems, but were never released to the community.

UnetStack 7 brings all of that work to the community release, and to several commercial offerings from Subnero.

There is a lot more in v7 than we can fit into one article. So we'll look at the things we think matter most, mention a few smaller ones in passing, and leave the rest for you to find in the [new handbook](https://org-arl.github.io/unet/handbook/).

Given that UnetStack 7 is a major release, some of your UnetStack 3 code may need porting. We did not make breaking changes lightly. The way UnetStack works is unchanged -- agents talk to each other using messages, agents provide services, and you can access the stack from the shell, from scripts, or through UnetSockets. What has changed is that several APIs and message contracts have been tidied up, so that agents and applications can depend on consistent behavior rather than provider-specific quirks. A few new services have been added to support exciting new features. If you have existing code, start with the [What's changed since v3?](https://org-arl.github.io/unet/handbook/A1_porting.html) chapter in the handbook.

## What changed, at a glance

The [default stack](https://org-arl.github.io/unet/handbook/301_stack.html) looks a little different now:

| | v3 (community / OEM) | v7 (community / OEM) |
|---|---|---|
| Link | `ReliableLink` / `ECLink` | `ECLink` |
| Transport | `SWTransport` | `CaddyLite` / `Caddy` |
| Remote access | `RemoteControl` | provided by `Caddy` |
| State persistence | `StateManager` | removed; agents use fjåge's `Store` |

So, `ECLink`, which was previously only available to OEM users, is now available to all users. `Caddy` is a brand new agent that provides production-grade transport and remote access services, with `CaddyLite` being a community version with a few QoS-related features trimmed down.

There are also three new services -- [`LINK_TUNING`](https://org-arl.github.io/unet/handbook/308_tuner.html), [`DEVICE_INFO`](https://org-arl.github.io/unet/handbook/316_device.html) and [`DOA`](https://org-arl.github.io/unet/handbook/314_doa.html) -- and a number of smaller changes:

- Datagrams addressed to a node are now published on the global `Topics.DATAGRAM` topic, while provider topics only carry overheard traffic (previously on `Physical.SNOOP`) and other informational notifications (e.g. bad receptions).
- Some messages, parameters and fields have been renamed for consistency. For example, `DatagramCancelReq` is now `CancelReq`, and `DatagramProgressNtf` is now `ProgressNtf`. Node orientation uses `yaw` and `yawRate` instead of `heading` and `turnRate`, with 0° = East, measured anticlockwise.
- Sleep scheduling has been redesigned around `SleepReq`, `StayAwakeReq` and `AddScheduledTaskReq`, with `cronadd`, `crontab` and `cronrm` in the shell.
- The web interface has a much more modern look and feel, and is also a lot more informative and nicer to use.
- The web IDE is gone (users can use their favorite IDE/editor instead), but the command line simulator (`bin/unet <script.groovy>`) works exactly as it used to.

But more importantly, let's look at the bigger changes:

## 1. Julia agents

While UnetStack 7 based modems ship with several Julia agents, the UnetStack 7 community release does not. Everything in the table above is written in Java or Groovy, and runs on the JVM under fjåge. However, if you want to write your own Julia agents, UnetStack 7 supports that out of the box.

The pieces you need are [Fjage.jl](https://github.com/org-arl/Fjage.jl), the Julia port of fjåge, and [UnetSockets.jl](https://github.com/org-arl/UnetSockets.jl), which adds the UnetSocket API and predefines the Unet messages on the Julia side. Talking to a node from a Julia script through a gateway is the familiar approach, and it works well. But with UnetStack 7, we can do better than that -- we can write an agent in Julia, run it in a slave container, and have it join a running Unet as a peer of every other agent in the stack.

Say we have a modem with several hydrophones, and a `compute_doa()` function that estimates the direction-of-arrival (DoA) of a signal using some fancy algorithm (the kind of function that is a pleasure to develop in Julia, and a pain in C). About twenty lines turn it into a `DOA` service in your modem:

```julia
using Fjage, UnetSockets

@agent struct MyDoaAgent end

function Fjage.setup(a::MyDoaAgent)
  register(a, "org.arl.unet.Services.DOA")
end

function Fjage.startup(a::MyDoaAgent)
  bb = agentforservice(a, "org.arl.unet.Services.BASEBAND")
  subscribe(a, topic(bb))
end

function Fjage.processmessage(a::MyDoaAgent, msg::RxBasebandSignalNtf)
  azimuth, elevation = compute_doa(msg.signal)
  send(a, BearingNtf(
    recipient = topic(AgentID(a)),
    rxStartTime = msg.rxStartTime,
    azimuth = azimuth, elevation = elevation
  ))
end

c = SlaveContainer("127.0.0.1", 1100)  # ip address & port of modem/simulator
add(c, "mydoa", MyDoaAgent())
start(c)
```

Three things are worth pointing out here. The agent registers the `DOA` service, so any other agent can find it using `agentForService` and use it, without knowing or caring that it is written in Julia. It receives complex baseband signals from the modem as a Julia array, along with carrier frequency `fc`, sampling rate `fs`, start time `rxStartTime` and signal strength `rssi`. And it publishes a standard `BearingNtf` on its own topic, so subscribers get bearings in exactly the form the rest of the stack expects.

The service contracts are now stable enough that a Julia agent can implement one properly, and the message definitions on the Julia side are complete enough that you don't have to write them yourself. Two things to keep in mind: `Fjage.jl` supports standalone and slave containers, but not master containers, so the JVM node stays in charge. And on modem hardware, sandboxing usually means running the Julia container on a companion computer (co-processor) next to the modem or on a laptop connected to it, rather than on the modem itself. This is the same arrangement we described in [Part II](https://blog.unetstack.net/custom-phy-in-julia).

## 2. PHYSICAL and BASEBAND services

An agent like the one above is only easy to write because UnetStack 7 draws a much clearer line between the [`PHYSICAL`](https://org-arl.github.io/unet/handbook/305_phy.html) and [`BASEBAND`](https://org-arl.github.io/unet/handbook/315_bb.html) services. If you have ever wondered where framing ends and signal processing begins, this release answers the question.

`PHYSICAL` deals with frames, and it does so on four named channels: `CONTROL` is a low-rate but robust channel for signalling and small control messages, `DATA` is a higher-rate channel for bulk transfers, `AUX` is for standardized schemes, and `CUSTOM` is yours to use as you please. Each is an indexed parameter set, so you can simply ask for `phy[CONTROL].dataRate` or `phy[DATA].MTU` instead of having to know it. The messages are correspondingly tidy: `TxFrameReq` to transmit, `RxFrameNtf` when a frame is decoded, `BadFrameNtf` when a frame is detected but cannot be decoded, and `TxFrameStartNtf` and `RxFrameStartNtf` to mark exactly when transmission and reception started. Those last two are what ranging and navigation are built on.

Optional features are advertised through `CapabilityReq`. These include `TIMED_TX` for transmissions scheduled at a future `txStartTime`, `TIMESTAMPED_TX` for frames that carry their own transmit time, `JANUS` and `SWiG1` for standardized interoperable frames, `FEC_DECODING` for user-accessible forward error correction, and `SIGNALS` for user-accessible conversion between frames and signals. The last two are handy when you are developing agents that build on top of the signal processing and error correction already built into the modem.

SWiG support is new in v7, and `AUX` is now where both standardized frame formats live -- JANUS moved there from its own frame type, and SWiG joins it. The `AUX` channel provides a common home for new interoperable frame formats, as they are developed by the community and ratified.

`BASEBAND` looks after everything below the frame: transmitting arbitrary waveforms with `TxBasebandSignalReq`, recording with `RecordBasebandSignalReq`, delivering received signals as `RxBasebandSignalNtf`, and managing the detectors (`bb[n].preamble`, `bb[n].threshold`) that wake up the rest of the stack when something interesting is heard in the water. From the shell, `bbtx` and `bbrec` get you there interactively.

The practical result is that writing a custom PHY is now a well-defined job. You know which service you are providing, which messages you owe your callers, which capabilities you should advertise, and where the raw signals come from. That was a lot less clear in v3.

## 3. ECLink and Router

`ECLink` is not new -- premium users have had it for some time. What is new is that it is now the default underwater acoustic [link](https://org-arl.github.io/unet/handbook/306_link.html) in the community release, replacing `ReliableLink`. It is still accessed as `uwlink`, and provides the same services, but it behaves rather better.

The problem it solves is that stop-and-wait does not suit the ocean. If you acknowledge each fragment before sending the next, every fragment costs a round trip, and underwater a round trip is seconds rather than milliseconds. Most of your airtime is spent waiting for sound to travel.

`ECLink` takes a different approach. It encodes a datagram into a set of coded fragments and transmits more of them than are strictly needed, so that the receiver can rebuild the datagram as soon as it has collected enough fragments. It does not matter which ones arrive. How much extra to send is up to you: `reliableExtra`, `unreliableExtra` and `robustExtra` set the redundancy for each mode. More redundancy gives a better chance of getting the data through on the first attempt, at the cost of more airtime.

`ECLink` was also designed with adaptive modulation in mind, and the hooks it needs are already in place. More on that in a future article.

The stack is also a lot more forthcoming about what it knows. `uwlink[peer]` tells you about the transfer currently in progress with that neighbour -- `to`, `from`, `size`, `progress` and `status` -- so a monitoring agent or a user interface can just ask, instead of working it out from notifications.

The [router](https://org-arl.github.io/unet/handbook/309_router.html) does the same for each destination. Every route carries a `metric`, along with `hops`, `dataRate`, `reliability`, `MTU` and `RTU`, so choosing a route is a decision based on more than just a hop count. If our default trade-off between hops and data rate isn't the one you want, you can supply your own metric as a closure. Routes marked `auto` enable and disable themselves as `LinkStatusNtf` messages report links coming up and going down. Disabled routes with a non-zero `poll` are re-checked periodically with small reliable datagrams, so a link that comes back is noticed without anyone having to ask. When a `DatagramFailureNtf` arrives, the router will try an alternative route and retransmit, up to `retryTimeout`. And when you want to know what actually happened rather than what should have, `DatagramTraceReq` traces the path and reports every node along the way.

Each of these seems like a small change on its own. But together, they are the difference between a network that recovers by itself and one that needs someone to go and manually fix it.

## 4. Caddy and the new DATAGRAM service

`caddy` is new, and it is not simply a rename. It replaces two agents at once -- `SWTransport` and `RemoteControl` -- and does a good deal more than the two of them did together. It provides the `TRANSPORT`, `REMOTE` and `DATAGRAM` services from a single agent.

Fragmentation, end-to-end acknowledgement (`ackTimeout`, `retry`), compression, mailboxes, routing rules and file transfers are all decisions about the same queue of data waiting to go out, and one agent that can see all of them makes better decisions than three agents negotiating with each other. The most useful consequence is that a large file transfer can run in the background while short, time-sensitive messages continue to flow in the foreground. Bulk data no longer holds up the network when your vehicle or sensor has something urgent to say.

A good place to start is with two new shell commands. `dtx` sends a datagram with whatever attributes you specify, and `dshow` controls which protocols you see arriving. Between them, you can drive and watch the whole [datagram service](https://org-arl.github.io/unet/handbook/304_datagram.html) from the shell:

```
> dtx host('B'), [1,2,3]
AGREE
caddy >> DatagramTransmissionNtf:INFORM[id:019a1738-6e0a-77e0-f271-e6cb98762ffa to:31]
> dtx host('B'), [1,2,3], reliability: true
AGREE
caddy >> DatagramDeliveryNtf:INFORM[id:019a1738-8d46-7c98-b549-81bb78c3ed2b]
```

The datagram service itself is not new, and neither are most of its attributes -- v3 already had `reliability`, `priority`, `ttl`, `MTU` and `RTU`. What v7 adds is `robustness`, `route` and `shortcircuit`, a `FAIRNESS` capability, the topic convention we mentioned earlier, and a definite outcome for unreliable datagrams. An unreliable `DatagramReq` now always produces a `DatagramTransmissionNtf` once it has been sent, where previously you got nothing and had to assume. Ask for reliability, and you get a `DatagramDeliveryNtf` or a `DatagramFailureNtf`. Three possible outcomes, no more, and the same three whether you are talking to `phy`, `uwlink`, `router` or `caddy`.

`robustness` is worth a moment, because it is not the same as reliability. Reliability is about acknowledgement. Robustness chooses the communication scheme, trading data rate against the chance that a fragment survives at all. The handbook gives a nice illustration: the same 32-byte datagram goes out as a single DATA frame at about 1004 bps in roughly a second, or as several CONTROL frames at about 247 bps over roughly 3.5 seconds. Same data, same reliability setting, quite a different bet on the channel.

The rest of what you can ask for is [covered in detail in the handbook](https://org-arl.github.io/unet/handbook/205_qos.html) -- `priority` at five levels, `ttl` for time-sensitive data, `progress` for long transfers, and `route` and `shortcircuit` for control over the path and the headers.

Much of what makes `caddy` useful shows up in [remote messaging](https://org-arl.github.io/unet/handbook/312_remote.html). Set `ttl: RemoteMessageReq.TTL_MAILBOX` along with `mailbox: 'STATUS'`, and a queued status message is replaced by the next one instead of piling up. A vehicle that has been busy communicating sensor data sends its latest status, rather than the six it had queued up minutes ago. `mimeType` lets an application say what kind of data it is sending, and `RemoteTextReq` (chat messages, packed as 7-bit for ASCII) and `RemoteExecReq` (`rsh`, which now returns its output by default) are proper message types rather than conventions. File transfers can be resumed, so an interrupted `fget` picks up where it left off once the vehicle surfaces again.

And with `messageClass`, routing policy becomes something you can write down:

```groovy
container.getAgent(caddy).addRule({ msg, routes ->
  if (msg.messageClass == 'STATUS2') {
    for (r in routes)
      if (r.link == udplink) return r
  }
})
```

Tag your bulky telemetry as `STATUS2`, and it waits for the WiFi link when the vehicle surfaces, while short status messages continue to go acoustically. No one has to write "am I on the surface yet" logic into the application.

## 5. The Virtual Acoustic Ocean

This one needs a modem at the other end, so it isn't something you can try with the community simulator (UnetSim) alone. But if you build systems that eventually get wet, it may be the most useful thing in v7.

The [Virtual Acoustic Ocean](https://org-arl.github.io/unet/handbook/403_vao.html) (VAO) is a realtime acoustic simulator. It replaces the analog front-end of each node, propagates transmitted signals through an acoustic propagation model, adds ambient noise, and streams the received signals back to each node over Ethernet.

VAO replaces the power amplifier, the transducer, the hydrophone and the ocean. Everything above that is real: real modem processors, real firmware, real physical layer signal processing, real agents, real timing. It connects at the data acquisition level using the UASP2 protocol, with commands sent as JSON over TCP and received signals streamed as timestamped UDP packets, so the PHY has no idea that it isn't in the water. That is quite different from a channel model in UnetSim, which abstracts away the PHY and lumps all the details of the real ocean into a probability of packet loss.

The ocean itself comes from [UnderwaterAcoustics.jl](https://github.com/org-arl/UnderwaterAcoustics.jl), and VAO will accept any propagation model that follows that API. Setting up a scenario takes about ten lines of Julia:

```julia
using VirtualAcousticOcean, UnderwaterAcoustics, Sockets

env = UnderwaterEnvironment(seabed=SandyClay, bathymetry=40.0)
pm = PekerisRayTracer(env)
sim = Simulation(pm, 24000.0)
addnode!(sim, (0.0, 0.0, -10.0), UASP2, 9809, ip"0.0.0.0")
addnode!(sim, (1000.0, 0.0, -10.0), UASP2, 9819, ip"0.0.0.0")
run(sim)
```

That is two nodes a kilometre apart, ten metres deep, in forty metres of water over sandy clay. On the modem side, you add a short `modem.toml` section pointing the analog interface at the ocean host's IP address and port, and reboot. After that, the modems simply talk to each other, and `range` tells you they are a thousand metres apart, because that is where you put them. For a step-by-step walkthrough of this setup, see [Running Hardware-in-the-Loop Simulations Using UnetStack Modems](https://blog.unetstack.net/running-hardware-in-the-loop-simulations-using-unetstack-modems).

Change `PekerisRayTracer` to something else, and the physics changes underneath your unmodified firmware. You can use mode solvers, general ray or Gaussian beam tracers, or Bellhop and Kraken through wrapper packages. Or you can use `ReplayChannelModel`, which replays measured impulse responses and noise recordings from real experiments. There is a curated library of these, from sea trials around the world, at [uwa-channels](https://uwa-channels.github.io/). Testing a modulation scheme against the actual channel from a past deployment is a rather different proposition from testing it against Rayleigh fading.

Adding more nodes is one `addnode!` per node. Since the model computes the paths between every pair of nodes, you get overhearing, interference and hidden terminals, just like in the real world. Nodes can also have several hydrophones, positioned using `relpos`, so array processing and direction-of-arrival work -- our Julia agent from earlier, for example -- can be developed and tested against a virtual ocean before anyone books boat time.

Doppler caused by platform motion during a transmission is currently not modelled, so motion is treated as quasi-static. Effects in the analog chain, such as saturation and cavitation, are not exercised. Fidelity is only as good as the propagation model you choose. And the number of acoustic paths grows with the square of the number of nodes, so a large network needs a faster machine or a simpler model. Within those limits, you get repeatable, controllable and realistic acoustics whenever you want them, which is exactly what regression testing and mission rehearsals need.

Since this is hardware-in-the-loop, VAO needs modem firmware at the other end. Real modems provide it, and so do **[UnetCube](https://subnero.com/products/wnc/unetstack/unetcube)**, a modem without the analog electronics that is built for exactly this, and **[UnetCloud](https://subnero.com/products/wnc/unetstack/unetcloud)**, which offers cloud-hosted UnetStack modems with a virtual ocean already attached.

## Numerous other improvements

There is a lot more in UnetStack 7 that we won't cover here, but a few things are worth a passing mention:

- **`unet.js` has matured.** Version 4 is a well-documented library. `UnetMessages` mirrors the UnetStack class hierarchy, so `rxNtf instanceof UnetMessages.DatagramReq` does what you would expect. It works over WebSockets in the browser and over TCP under Node, and it includes a `CachingGateway` that fetches an agent's parameters together and serves them back with a `maxage` that you control. If you have ever watched a web dashboard send forty parameter requests over an acoustic link, you will appreciate this.
- **Acoustic navigation is now a stack service.** The [`DOA`](https://org-arl.github.io/unet/handbook/314_doa.html) service reports `BearingNtf` and `PeerLocationNtf` in the body frame, and in the world frame when the node's orientation is known. This is what turns a multi-receiver modem into a USBL transceiver, as we described in [Turning a Multi-Receiver Modem into a USBL Transceiver](https://blog.unetstack.net/turning-a-multi-receiver-modem-into-a-usbl-transceiver).
- **Nodes provide hardware/platform information.** [`DEVICE_INFO`](https://org-arl.github.io/unet/handbook/316_device.html) provides vendor, model, serial number, health, temperature, voltage, storage and uptime, using the same parameter mechanism as everything else. A small thing, until you are trying to work out what is wrong with a node at sea.
- **Agents can document themselves.** The [`DOCUMENTATION`](https://org-arl.github.io/unet/handbook/319_doc.html) service is how `help` in the shell knows about an agent's parameters and commands. The reference tables in the handbook are generated from the same source, so the documentation and the code cannot drift apart. If you write agents, give them a `__doc__`.
- **On modems**, the [`LINK_TUNING`](https://org-arl.github.io/unet/handbook/308_tuner.html) service measures link quality using test frames and picks a scheme that gives good throughput while keeping errors low -- just type `tune 74` and wait. The `profiles` agent saves and switches between named PHY configurations, and `speedtest` measures what you are actually getting. On the transport side, `CaddyLite` provides reliable multi-hop transport, remote access and file transfer, while the licensed `Caddy` adds quality of service (priority, TTL and fairness), user-defined routing rules, and resumable file transfers. The handbook marks which is which, and `CapabilityReq` will tell you at runtime what a provider actually supports.

## Closing thoughts

UnetStack 7 is a big release, but it is not a new stack. It is the same agent-based, service-oriented, scriptable system it always was, with a decade of accumulated inconsistency cleaned out of it, a link layer that suits the medium much better, a transport agent that lets applications say what they need, and a Julia story that now runs all the way from the ocean up to the agent.

Some of the tidying up may look fussy if you read the porting guide on its own. It isn't. For the stack to make good decisions below the application layer, it needs to know what it is carrying, what its links are doing, and what the application actually wants. Most of what changed in v7 is about making those three things knowable. We will have more to say about what that enables before long.

If you have UnetStack 3 code, start with the [porting guide](https://org-arl.github.io/unet/handbook/A1_porting.html). Most of what you have will move across with modest changes. If you are new to all this, the [handbook](https://org-arl.github.io/unet/handbook/) has been rewritten for v7, and there is a lot in there that we have not even mentioned here.

We are delighted to finally get all of this into your hands. Do let us know how you get on with it!
