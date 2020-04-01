---
layout: post
comments: true
title: Exploiting Dsitributed Spatial Diversity Using UnetStack
date: 30/03/2020
author: Prasad Anjangi
categories: howto
feature-img: "assets/img/sd-unet.jpg"
thumbnail: "assets/img/sd-unet.jpg"
tags: [howto, spatial diversity, cooperative diversity, robustness, data rate, performance boost]
---

Though it has been a buzzword over the past several years in the terrestrial radio frequency (RF) based wireless networks, much is not talked about practical spatial diversity systems in underwater wireless networks. It has proved and delivered tangible benefits to the end-user in the terrestrial wireless networks. Can we exploit this technique to make underwater wireless networks faster and more reliable and make that long-range communication link "just work" ? With the capability to exploit distributed spatial diversity, yes you can!

### What's the key idea involved in distributed spatial diversity ?

*Multiple communication nodes deployed at spatially distinct locations can receive independent copies of the same information. This group of receiver nodes can act as a combined spatial diversity receiver when they cooperate by sharing copies of information. We term this distributed spatial diversity. The framework supporting this patent-pending technique is implemented in UnetStack 3.1 and is referred to as `Unity`.*

![Overview](../assets/img/sd.png)

An illustration of the general overview of such a receiver system is shown above and few terminologies might help for further discussion:

- *Transmitter:* A node which transmits information
- *Main receiver:* A node that acts as the main receiver in a group of receiver nodes. It is the main receiver's responsibility to decode the information.
- *Assisting receiver:* A node that acts as an assisting receiver in a group of receiver nodes. It is the assisting receiver's responsibility to forward the relevant information to the main receiver.

The two assisting receiver nodes are in cahoots with the main receiver to cooperatively share the information! This sharing of information usually happens over a short-range wired or wireless network (e.g., WiFi, TCP/IP, UDP/IP). Although, nothing stops one from using a different technology for sharing information.

### What's the immediate practical advantage one can see ?

Consider a case where you are on a ship with a modem deployed and you've been receiving status updates from a deployed AUV every few minutes. The AUV moves into an area where the connectivity is poor, and you can no longer successfully receive the status reports. We've all experienced being in that situation where the underwater communication link breaks, haven't we?

If you have a second modem available on the ship, you deploy it from another part of the ship. Or maybe there is a gateway buoy deployed nearby with a modem, and you can connect to its modem. Either way, the distributed spatial diversity technique (`Unity`) magically uses the information from both modems to recover connectivity to the AUV!

### So how to use `Unity` in UnetStack 3.1?

`Unity` is available as a premium agent and requires UnetStack 3.1 and higher.

Configuring and using the `Unity` agent to exploit spatial diversity is easy with just two simple steps:

1. Setup the receiver nodes to cooperate.
2. Add the `Unity` agent on the main receiver.


#### 1. Set up for receiver nodes to cooperate (an example):

To set up the group of receivers to cooperate over a short-range network, we use [`Wormhole`](https://unetstack.net/handbook/unet-handbook_preface.html)  agent provided in the latest release UnetStack 3.1.  Transmitter node makes a transmission that is heard at all the receiver nodes. However, none of the nodes are able to successfully recover the information received, as the communication link is noisy.  In order to share the received noisy signals among the receivers, we can connect the receiver nodes using a `Wormhole`. A UDP connection between the two receiver nodes, over any IP based network (Ethernet, WiFi), can be established by adding just a few lines of code on the receiver nodes as shown below:

```groovy
container.add 'udp', new UdpLink()
container.add 'wormhole', new WormHole()
wormhole.dsp = 'udp'
```
Line (1) adds a [`UdpLink`](https://unetstack.net/handbook/unet-handbook_wired_and_over_the_air_links.html) agent that implements a link protocol over UDP/IP for use over wired/wireless IP networks. 

Line number (2) adds a `Wormhole` agent which allows the [fjåge](https://fjage.readthedocs.io/en/latest/) messages to be sent between containers over a [Unet link](https://unetstack.net/handbook/unet-handbook_introduction.html).

Line number (3) tells the `Wormhole` agent to utilize the `UdpLink` as the Unet link to share information. For more details on the `Wormhole` agent, please refer to this [link](https://unetstack.net/handbook/unet-handbook_preface.html).

*Additional set up on the assisting receiver* :

We may not want to share the information from all agents, instead, we are interested in messages that are published on the Physical agent's topic on the main receiver.
```groovy
wormhole.broadcast = [topic(phy), topic(phy, Physical.SNOOP)]
```
The above line of code is added only on the assisting receivers to forward only the messages received on the `Physical` agent's topic to be sent over the `Wormhole` link.

#### 2. Add the `Unity` agent on the main receiver:

Now that the receiver nodes are ready to cooperate, we can go ahead and add the `Unity` agent on the main receiver node.

```groovy
container.add 'unity', new Unity()
```
If a user wishes to take a look at the parameters of the `Unity` agent after loading the agent, type `unity` on the node's web shell interface:
```
> unity
« Spatial diversity agent »

Combines copies of information received from multiple
receivers to decode packets.

[org.arl.unet.unity.UnityParam]
  assisters = []
  enable = false
  maxAssisterRange = 100.0
  phy = phy
```
The `assisters` parameter is used to store the node addresses of the assisting receivers that are assisting the main receiver. The user might also want to change the default value of `maxAssisterRange` if the furthest assisting receiver to the main receiver is at a distance larger than 100 m.

```groovy
unity.assisters = [< first_assister_address >, <second_assister_address>]
assister.enable = true
```
Once the assisters node addresses are set, as shown above, the `Unity` agent is enabled. And voila, you are ready to see the benefits of cooperating receivers in terms of reliability and effective data rate.


**NOTE**: We will be sharing white papers and material detailing the protocol implemented once it is available. Until then, for keen readers and folks interested in knowing more details on learning and using this technology, please get in touch by emailing at [info@subnero.com](https://subnero.com/contact/).
