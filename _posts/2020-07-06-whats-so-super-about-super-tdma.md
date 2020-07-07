---
layout: post
comments: true
title: What's so "super" about Super-TDMA ?
date: 06/07/2020
author: Prasad Anjangi
categories: howto
feature-img: "assets/img/stdma/stdma-unet.jpg"
thumbnail: "assets/img/stdms/stdma-unet.jpg"
tags: [howto, tdma, medium access control, long propagation delays, throughput, performance boost]
---

Needless to say that underwater acoustic (UWA) networks might play a key role in many areas including marine, offshore and subsea industries in the future. There have been tremendous and impressive technological advances in underwater acoustic communications and networking field. The one that caught my attention and brought about a clear difference in the novel approaches that are needed to deal with challenges in UWA networks was the "exploitation" of large propagation delays that exist in UWA networks. Do you know that it is possible to achieve as much as 50% higher network throughput with specific network geometries and protocols in UWA networks when compared to radio-frequency (RF) based terrestrial wireless networks? It is an interesting and surprising fact that has led to further exploration of such techniques in practical settings. In this blog, without delving too much into the nitty-gritty details, let's try and understand; where that advantage comes from, through an example technique (*Super-TDMA*). We will try and understand the key idea behind this technique  and let's see why it is "super".

### Long propagation delays

![Overview](../assets/img/stdma/stdma-lpd.png)

Let us first understand what is meant by a long propagation delay. Specifically, how "long" it has to be? If the propagation delay in a medium is larger (or in the same order) in comparison to the message duration, i.e., the time it takes when a signal/message is transmitted is much larger in comparison to the signal/message duration, then the propagation delay is considered long. This is quite easy to understand if we look at an example. Consider a transmitter and a receiver node placed at say 750 m apart. When placed in water, an acoustic signal carrying information will take approximately 500 ms to reach the receiver, whereas, in air, an RF signal for the same setup will take approximately 2.5 microseconds. If the message duration is in the order of milliseconds, it is easy to see that the long propagation delay exists in the UWA setup where the propagation delay of 500 ms is much larger.

### Traditional TDMA

It is easiest to show how the long propagation delay can be harnessed to achieve higher throughput using a simple contention-free medium access control technique called Time Division Multiple Access (TDMA). In traditional TDMA protocols, every node in the network is assigned a fixed time slot in which it can transmit information. Appropriate amounts of guard time in each time slot must be left to make sure the intended receiver node receives the message successfully. As you can imagine, this protocol may not be great in networks that suffer from long propagation delays, right ?

![Overview](../assets/img/stdma/stdma-ttdma.png)
Consider a large 10 km network, i.e., the farthest distance between a transmitter and receiver node is 10 km. In this case, for a message to reach the farthest receiving node, it may take approximately ~ 7 seconds (see above figure). If the message duration is 1 second long, the channel utilization efficiency is 1/8 which is 12.5% and not very impressive.

### Super TDMA

The key idea involved in Super-TDMA is visualized in the figure below. Since the message duration is much shorter than the propagation delay, a natural question arises. 

*Can a message be scheduled to be transmitted in one slot and be received in a different slot ?* 

If the transmissions and receptions are carefully scheduled to occur in different slots, it turns out that much higher throughput is achievable.

![Overview](../assets/img/stdma/stdma-stdma.png)
Note that in traditional TDMA protocol a significant amount of time in each slot is left vacant, however, in protocols employing the exploitation of large propagation delays, such large guard times are not needed.

#### Example network geometry - an equilateral triangle

Let us consider an example network geometry and work out a high throughput schedule to inculcate this key point in our mind. For this example, let us consider 3 nodes in a network forming an equilateral triangle.

![Overview](../assets/img/stdma/stdma-equi-2.jpeg)

In such a network, the amount of time taken for a message to reach from any one node to another node will be the same. It is shown, that in such special networks, a throughput that is 50% higher than what can be achieved in RF-based terrestrial wireless networks can be achieved. Here is an example of such a schedule [1]:
![Overview](../assets/img/stdma/stdma-schedule-1.png)
The actions that each node in the network needs to take are represented by rows. For example, according to the schedule above node 1 transmits to node 2 in the first time slot, node 1 transmits to node 3 in the second time slot, and so on. Note that the schedule is presented only until four-time slots and this fully describes the schedule since these networks have properties of having periodic schedules where the same schedule is repeated again. 
![Overview](../assets/img/stdma/stdma-schedule-2.png)
This can be easily visualized [2][3]. Take a look at the figure below where the above-mentioned schedule is repeated for 12-time slots or 3 periods. The line segments in black represent transmissions whereas the line segments in blue represent receptions. The line segments in dotted red are the interfering packets. It is interesting to see that most of these interfering packets are aligned in a time slot and such time slots are utilized for transmissions. This is an essential principle using which algorithms can be developed for much more complex network geometries. This idea opens up tremendous possibilities in designing practical techniques for medium access control in networks with large propagation delays.

### Can we simulate such a schedule in UnetSim ?

Yes, of course, let's do that next. It is easy to implement a 3 node equilateral network geometry with the above-mentioned high throughput schedule in UnetSim. The sample code as `e3-network.groovy `is provided here. Let us go through the code a bit to try and understand how it is implemented.

```groovy
//! Simulation: Equilateral triangle network
///////////////////////////////////////////////////////////////////////////////
///
/// To run simulation:
///   bin/unet samples/super-tdma/e3-network
/// OR
///   click on the Run button (▶) in UnetSim
///
/// Output trace file: logs/trace.nam
///
/// Reference:
/// [1] M. Chitre, M. Motani, and S. Shahabudeen, "Throughput of networks
///     with large propagation delays", IEEE Journal of Oceanic Engineering,
///     37(4):645-658, 2012.
///
///////////////////////////////////////////////////////////////////////////////

import org.arl.fjage.*
import org.arl.unet.*
import org.arl.unet.phy.*
import static org.arl.unet.Services.*

///////////////////////////////////////////////////////////////////////////////
// settings

def slot = 422.ms               // default packet length is about 345 ms
def range = 650.m               // about slot x 1540 m/s
def time = 15.minutes           // simulation time
def schedule = [[2, 3, 0, 0],   // schedule from [1]
                [0, 0, 1, 3],
                [0, 1, 0, 2]]

///////////////////////////////////////////////////////////////////////////////
// display documentation

println """
Equilateral triangle network
----------------------------
Internode distance:     ${range} m
Slot length:            ${(1000*slot).round()} ms
Simulation time:        ${time} s"""

///////////////////////////////////////////////////////////////////////////////
// simulate schedule

simulate time, {

  def n = []
  n << node('1', address: 1, location: [0, 0, 0])
  n << node('2', address: 2, location: [range, 0, 0])
  n << node('3', address: 3, location: [0.5*range, 0.866*range, 0])

  n.eachWithIndex { n1, i ->
    n1.startup = {
      def phy = agentForService PHYSICAL
      phy[Physical.DATA].frameLength = phy[Physical.CONTROL].frameLength
      add new TickerBehavior(1000*slot, {
        def slen = schedule[i].size()
        def s = schedule[i][(tickCount-1)%slen]
        if (s) phy << new TxFrameReq(to: s, type: Physical.DATA)
      })
    }
  }

}

// display statistics
println """TX:                     ${trace.txCount}
RX:                     ${trace.rxCount}
Offered load:           ${trace.offeredLoad.round(3)}
Throughput:             ${trace.throughput.round(3)}"""
```

First we set the distance between the nodes to be 650 m. With sound speed in water to be approximately 1540 m/s, the slot length turns out to be 422 ms which is set as can be seen in the code. The simulation time is set to 15 minutes and the high-throughput schedule is given as an input. The rest is pretty simple. The three network nodes are deployed at appropriate coordinates to form an equilateral triangle. The frame duration of the DATA channel packet is set to be smaller than the time slot length, i.e., we need to make sure that the frame length and data rate is such that the packet duration is smaller than 422 ms. Once we set this up, the packets are transmitted from each node in a `TickerBehavior` as per the schedule. Now, let's run this and look at the result:

```term
Equilateral triangle network
----------------------------
Internode distance:     650 m
Slot length:            422 ms
Simulation time:        900 s
TX:                     3198
RX:                     3011
Offered load:           1.375
Throughput:             1.295

1 simulation completed in 2.615 seconds
```
The network capacity as we learned earlier is 1.5 (see [1] for more details). Although, in this network, our offered load is less than that since the packet duration is slightly lesser than the time slot duration and hence they are not fully utilized. And therefore, we see a reduced throughput but still 29.5% larger than what can be achieved traditionally. The fact that the practical frame durations used in underwater networks are comparable to the propagation delays led to this gain in throughput. This is remarkable and we should aspire to harness such knowledge of propagation delays in networks when designing performant protocols for higher throughput.

There is much more to this topic and to learn about all that, the following are just a few references that scratch the surface.

*[1] M. Chitre, M. Motani, and S. Shahabudeen, “Throughput of networks with large propagation delays,” IEEE Journal of Oceanic Engineering, vol. 37, no. 4, pp. 645--658, 2012.*

*[2] P. Anjangi and M. Chitre, “Experimental Demonstration of Super-TDMA: A MAC Protocol Exploiting Large Propagation Delays in Underwater Acoustic Networks,” in Underwater Communications Networking (Ucomms 2016), (Lerici, Italy), September 2016.*

*[3] P. Anjangi and M. Chitre, “Design and Implementation of Super-TDMA: A MAC Protocol Exploiting Large Propagation Delays for Underwater Acoustic Networks,” in WUWNet'15, (Washington DC, USA), October 2015.*

*[4] P. Anjangi and M. Chitre, “Scheduling Algorithm with Transmission Power Control for Random Underwater Acoustic Networks,” in OCEANS 2015 MTS/IEEE, (Genoa, Italy), May 2015.*

*[5] S. Lmai, M. Chitre, C. Laot, and S. Houcke, “Throughput-efficient Super-TDMA MAC Transmission Schedules in Ad hoc Linear Underwater Acoustic Networks,” IEEE Journal of Oceanic Engineering, vol. 42, no. 1, pp. 156--174, 2017.*

*[6] . Noh, P. Wang, U. Lee, D. Torres, and M. Gerla, “DOTS: A propagation delay-aware opportunistic MAC protocol for underwater sensor networks,” inProc. 18th IEEE Int. Conf. Network Protocols, 2010, pp. 183–192.*
