---
layout: post
comments: true
title: What's new in UnetStack 3.1?
date: 30/3/2020
author: Mandar Chitre
categories: info
feature-img: "assets/img/unetstack3.1.jpg"
thumbnail: "assets/img/unetstack3.1.jpg"
tags: [unetstack]
---

UnetStack 3.0, released at the end of September last year, was a major milestone in the evolution of UnetStack. We are now excited to release the next installment of features and performance enhancements in the form of UnetStack 3.1. Apart from performance enhancements and bug fixes, UnetStack 3.1 brings significant feature upgrades to the link, ranging and routing services, new concepts such as _wormholes_ and distributed spatial diversity, a new fragmentation-reassembly framework, and improved user interface in the form of _dashboards_.

Let's take a brief look at some of the new features:

#### 1. Dashboards

While UnetStack's command shell provides an advanced user with limitless power, it takes time for a new user to master it. To enable users to perform common tasks quickly and easily, we added dashboards to UnetStack. Dashboards leverage modern web technology to present a nice user interface, backed by the power of the software-defined network stack.

![Dashboards](assets/img/dashboard.png){:class="img-responsive" width="1024"}

UnetStack 3.1 ships with several pre-configured dashboards for modem nodes:

- **Overview** dashboard provides a quick view of various configuration options in UnetStack.
- **Diagnostic Scope** is a real-time software oscilloscope to visualize incoming signals, and demodulation results.

![Diagnostic Scope](assets/img/diagscope.png){:class="img-responsive" width="600"}

- **Speed Test** enabled you to quickly measure link performance.
- **Configurations** dashboard (beta version) provides a visual way to configure various options and agents in the stack.

In addition to the pre-configured dashboards, users may develop their own dashboards easily. Watch out of an upcoming blog article on developing your own UnetStack dashboard!

#### 2. Localization framework and a new ranging agent

Underwater acoustic modems are used not only communication, but often also for acoustic ranging. The introduction of a localization framework in UnetStack eases the development of underwater positioning and tracking networks, enabling ranging, navigation, and tracking of underwater sensor, robots, and even divers. The framework not only supports UnetStack-based modems in the underwater network, but also treats other devices such as commercial off-the-shelf (COTS) transponders and pingers as Unet nodes. This enables legacy and low-power nodes to be easily integrated into an underwater positioning network. UnetStack now also supports broadcast ranging, allowing multiple underwater nodes to be localized with a single query transmission.

While underwater positioning networks may be used for many applications, we highlight a few examples to excite your imagination:

- Autonomous Underwater Vehicle (AUV) navigation with moving beacons.
- AUV navigation against a constellation of fixed transponders.
- Cooperative navigation of a team of AUVs.
- Remotely Operated Vehicle (ROV) tracking.
- Simultaneous communication & navigation for a team of divers.

#### 3. Redefined routing service

The routing service in UnetStack has served us well for the past decade. However, as our networks become more heterogenous, and the demands on routing more complex, we felt the need to rethink how routing works. With the emergence of underwater disruption-tolerent networks (DTNs)[^1], routers need to make decisions based on the time-to-live (TTL) of datagrams being routed. Cross-layer optimization often requires routing information to be generated or consumed in parts of the network stack not traditionally involved in routing.

The new routing service allows dynamic creation, maintainence, query, and consumption of routes by other agents, and helps meet complex demands from optimized underwater network protocols.

#### 4. Link state information

Dynamic routing and DTNs often require link state information to make optimal decisions. The link service in UnetStack has now been updated to enable link agents to publish link state (up/down) and link quality information. The default set of link agents in UnetStack have also been upgraded to publish link state/quality information when available.

In addition to basic link state information, the `ECLink` agent in the premium stack now provides[^2] data transfer progress details for each peer node as indexed parameters. Since `ECLink` datagrams are often very large, this functionality enables client agents to closely monitor the progress of their data transfers.

#### 5. Enhanced UDP links

The `UDPLink` agent provides Unet links over an UDP/IP network. In UnetStack 3.0, the UDP links were based on the UDP multicast functionality of IP networks. While this functionality worked well with wired networks, many WiFi routers implement UDP multicast poorly. As a result, on many WiFi networks, we saw high packet loss for UDP multicast packets, and consequently large retransmission overhead for UDP links.

To improve the performance of UDP links over WiFi networks, we have now reimplemented the UDP link agent to use a combination of UDP broadcast and unicast. UDP links now also support fragmentation/reassembly, data compression, and erasure correction coding. As a result, UDP links now support large MTUs, and retain good performance over WiFi networks and wired networks. As a bonus, Unet nodes now benefit from IP routing functionality, allowing Unet nodes to be transparently distributed across the Internet.

#### 6. Wormholes

The fjåge agent framework forms the backbone of a Unet node, enabling communication between intelligent agents that cooperate to provide the network and application functionality for that node. All agents in one Unet node live in one fjåge _universe_, and can seamlessly communicate with each other. However, agents in diffent nodes live in different fjåge universes, and typically only communicate with peer agents on other nodes using protocols implemented over Unet links. UnetStack 3.1 introduces the concept of _wormholes_ that connect multiple fjåge universes over a Unet link, allowing all agents in multiple nodes to transparently talk to each other!

Sounds cool, but why would I want to do this? The usefulness of this is best understood with a couple of real-world examples:

![Wormholes](assets/img/wormhole.png){:class="img-responsive" width="800"}

**Diver tracking**: Imagine a network with gateway node G (a standalone buoy), surface node B (deployed from a boat), and an underwater node D (diver). Nodes G and B have underwater acoustic modems and in-air WiFi connectivity. Node D is fully submerged, and only has acoustic connectivity to nodes G and B. An application agent A on node B wishes to track the location of node D. Agent A (on node B) can ask the ranging agent on the same node for a range to node D (since both agents live in the same fjåge universe). Agent A also requires the range from node G to node D, but is normally unable to ask the ranging agent on node G directly (since they live in different fjåge universes). The traditional approach to this problem would be to deploy a peer agent Ā on node G that communicates with agent A on node B through a custom protocol over a UDP link over WiFi. Agent Ā then makes the request to the ranging agent on node G on behalf of agent A, and relays the information back. With wormholes, none of this complexity is required! Connect nodes B and G using a wormhole over the UDP link over WiFi. Now agent A on node B can directly ask the ranging agent on node G for range to node D, and use this information to track the diver D.

**Cooperative communication**: Let's take the same network with nodes G, B and D, but consider a different application. Diver node D makes a transmission that is heard at nodes G and B. However, neither node is able to successfully recover the transmission, as the area of operation is noisy and the packet checksum (CRC) does not match after decoding. In a traditional network, the transmitted packet is considered lost. With UnetStack 3.1, we can connect nodes B and G using a wormhole over a UDP link over WiFi. An agent U on node B now hears the `BadFrameNtf` from the physical layer of node B. It also hears the `BadFrameNtf` from the physical layer of node G through the wormhole. It can combine the log-likelihood ratios of bits in each `BadFrameNtf`, creating a new set of bit estimates that contain the information from both nodes. The combined packet may decode successfully, recovering the transmitted information from node D at node B. Although each node (B and G) has a single hydrophone, agent U is able to exploit the spatial diversity across the two nodes to effectively decode the combined packet!

#### 7. Unity (distributed spatial diversity)

The cooperative communication example above is not just a _gedanken_ experiment, but a patent-pending technique that has been demonstrated to work well in practice. The _Unity agent_ is a premium agent, available on UnetStack 3.1, that implements a refined version of the above cooperative communications strategy. It allows users to transparently implement spatial diversity with a set of COTS UnetStack-based underwater acoustic modems, each with only a single-receiver.

What does it mean in practice? Say, you're on a ship, you have an AUV deployed in an area, and you've been receiving status updates from the AUV every few minutes. The AUV moves into an area where the connectivity is poor, and you can no longer successfully receive the status reports. If you have a second modem available on the ship, you deploy it from another part of the ship. Or maybe there is a gateway buoy deployed nearby with a modem, and you can connect to it's modem. Either way, Unity magically uses the information from both modems to recover connectivity to the AUV!

If you happen to be lucky enough to have more than two modems, Unity can use the information from all available modems to improve communication performance.

#### 8. New fragmentation/reassembly framework

Fragmentation and reassembly is often needed by many protocol agents in a network stack. Rather than have each of the agents implement the functionality individually, UnetStack now provides a fragmentation/reassembly framework that makes implemeting protocols with large MTUs easy. For example, to fragment a large byte array `data` into fragments of size `FRAGMENT_SIZE`, we simply do:
```java
Fragmenter frag = new SimpleFragmenter(data, FRAGMENT_SIZE);
while (frag.hasMoreFragments()) {
  byte[] fragment = frag.nextFragment();
  // add code here to transmit fragment
}
```

To reassemble on the other side is easy too:
```java
// add code here to get DATAGRAM_SIZE and FRAGMENT_SIZE through initial handshake
Reassembler reasm = new SimpleReassembler(DATAGRAM_SIZE, FRAGMENT_SIZE);
while (!reasm.hasFinishedReassembly()) {
  // add code here to receive a fragment
  reasm.addFragment(fragment);
}
byte[] dgram = reasm.getData();
// dgram is the reassembled datagram
```

Here, we used the `SimpleFragmenter` that breaks the data into a series of shorter data chunks for transmission. To reassemble the data, we require all fragments to be successfully received.

**Erasure correction coded fragmentation/reassembly**: A more powerful fragmentation/reassembly method using erasure correction (EC) coding allows some fragments to be lost, and yet the data to be reassembled without needing retransmissions. Implementing EC code based fragmentation/reassembly from scratch is a daunting task, but with UnetStack 3.1 (premium edition), you can easily implement EC fragmentation/reassembly by simply replacing `SimpleFragmenter` in the above code by `ECFragmenter`, and `SimpleReassembler` by `ECReassembler`.

#### 9. Adoption of fjåge parameters

UnetStack introduced the concept of [parameters](https://unetstack.net/handbook/unet-handbook_developing_your_own_agents.html) to allow easy configuration and status reporting of agent. Since fjåge 1.7, the fjåge agent framework also adopted the concept of parameters. To provide seamless operation with other fjåge-based frameworks (e.g. [fjåge sentuator](https://github.com/org-arl/fjage-sentuator)), UnetStack 3.1 adopts the parameter implementation provided by fjåge.

**Breaking change**: The adoption of fjåge parameters by UnetStack means that every UnetStack agent that uses parameters must explicitly import `org.arl.fjage.param.*`.

While this breaking change may be a small inconvenience, this is a small one-time cost to pay for the benfits this provides in terms of compatibility with other projects. Additionally, fjåge parameters provide some useful functionality beyond the older UnetStack parameters. For example, when listing parameters, you can now easily differentiate between read-write (denoted with `=`) and read-only (denoted with `⤇`) parameters:
```
> uwlink
« Erasure coded link »

Link protocol based on erasure coding, for fast large data transfers over a single hop.

[org.arl.unet.DatagramParam]
  MTU ⤇ 7863960
  RTU ⤇ 1450

[org.arl.unet.link.ECLinkParam]
  compress = true
  controlChannel = 1
  dataChannel = 2
  mac = mac
  maxBatchSize = 65533
  maxPropagationDelay = 3.0
  maxRetries = 2
  minBatchSize = 3
  phy = phy
  reliability = false
  reliableExtra = 0.2
  unreliableExtra = 0.3

[org.arl.unet.link.LinkParam]
  dataRate ⤇ 690.38605
```

#### 10. Performance enhancements

Other than the major features listed above, UnetStack 3.1 has many under-the-hood changes. Some of these changes manifest as significant performance improvements:

- `ECLink` now supports data compression, requiring less bandwidth, and yielding faster data transfers.
- `ECLink` protocol improvements now allow larger MTUs, and more robust data transfers.
- `CSMA` MAC agent now works closely with many agents in the stack to anticipate responses and re-transmissions by peer nodes, thus reducing collisions and improving communication performance.
- `Ranging` agent now works more closely with MAC to reserve the channel for two-way time-of-flight ranging and broadcast ranging.

---

##### Footnotes:

[^1]: While projects such as [Underwater DTN](https://github.com/shortstheory/underwater-dtn) have successfully implemented DTNs using UnetStack, the official DTN support for UnetStack is still under development, and should be available in an upcoming release soon.
[^2]: The link data transfer progress functionality is provided by `ECLink` on an experimental basis, and not part of the link service definition at present. As the use cases for the consumption of this information mature, we expect to add this functionality to the link service definition. This will allow other agents to provide similar functionality in a uniform way.
