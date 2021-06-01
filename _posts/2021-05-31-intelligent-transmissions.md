---
layout: post
comments: true
title: Scheduling transmissions intelligently in UnetStack enabled modems
date: 31/5/2021
author: Manu Ignatius
categories: howto
feature-img: "assets/img/intelligent/feature.jpg"
thumbnail: "assets/img/intelligent/feature.jpg"
tags: [unetstack]
---

UnetStack powered acoustic modems provide extreme flexibility to the user to automate processes such as transmission of data frames (e.g. position updates) or signals, decision making after reception etc. enabling a hands-off approach to test various deployment scenarios. If you are using a program or a script to transmit and receive from your SDOAM, it is often good to know your location (latitude, longitude and depth), to make decisions such as when to transmit, what power level to use etc. This is not a big problem if your acoustic modem is deployed in a fixed location. However, if the modem is installed in a mobile underwater asset like an autonomous underwater vehicle (AUV), such decisions are crucial.

Since transducers are electromechanical devices, transmitting at high power closer to the water surface will cause cavitation that will result in a bad communication link. This may even damage the transducer. Additionally, if you are close to a receiving modem, transmitting at high power may saturate the receiver thereby causing the receiver to not being able to decipher your messages.

UnetStack enabled Subnero modems that are in the [standalone configuration](https://subnero.com/products/wnc-m25mss3.html) comes installed with a depth sensor. Additional sensors like [GPS, compass](https://subnero.com/products/sensors.html) etc. are available as optional upgrades. However, a depth sensor is not a standard sensor on an [embedded configuration](https://subnero.com/products/wnc-m25mse3.html) modem which is the typical configuration you will install in an AUV. That doesn't mean that the modem cannot have access to the location information. Let us a take a look at how a user would use this information to decide when to transmit and when not to do it, from a modem that is installed in an AUV.

<p align="center"><img src="../assets/img/intelligent/auv.png"></p>
<p align="center">Figure 1: AUV internal connection</p>


Figure 1 shows our assumptions on how the various components are connected within the AUV for the purpose of this article. A single board computer (SBC) in the AUV is connected to the modem over an Ethernet interface. Both the AUV's SBC and the modem are in the same network.

To start with, let us assume the user would like to send periodic updates from AUV as a broadcast message. There are mainly two ways to do this.

1. Run a program in the SBC and connect to the modem using a UnetStack Gateway to send periodic commands to the modem, using Unet socket APIs. This can be done using any of the programming languages supported by UnetStack such as C, Java, Groovy, Python, Julia etc as detailed [here](https://unetstack.net/handbook/unet-handbook_unetsocket_api.html). In this case, the user has access to various sensors of the AUV directly.
2. Running a groovy script in the modem to do the periodic transmissions. The advantage of this method is that you now have direct access to the modem and can deploy your own [fjåge](https://github.com/org-arl/fjage) agents. This is a lot more flexible as compared to what is offered by the APIs.

To send a simple broadcast message once, you can use the `tell` command as follows.

```groovy
tell 0, 'OK'
```

To execute this from a script, you can create a new file from the `scripts` tab in the UnetStack's web interface.

<p align="center"><img src="../assets/img/intelligent/script-ui.png"></p>
<p align="center">Figure 2. UnetStack's web interface</p>


To repeat this a 100 times, once every second, the script can be updated to:

```groovy
100.times {
  tell 0, 'OK'
  delay (1000)
}
```

The next step is to determine the current depth at which the device is, then decide whether to transmit or not.

In UnetStack, the `NODE_INFO` service provides a single place to collate node-related information that is commonly needed by many agents. One of the parameters of this service is the `location` which tracks the location of the modem are (x, y, z) in meters if the `origin` set, otherwise (latitude, longitude, z). If your modem has a depth sensor, the `z` value of `node.location` contains the depth information. You can update the script to transmit only at a depth less than -2 m, as follows.

```groovy
100.times {
    depth = node.location[2]
    if (depth < -2) tell 0, 'OK'
    delay(1000)
}
```

> NOTE: Depth is indicated as 0 (surface), -1 (1 m depth from surface), -2 (2 m depth from surface) and so on. See [Section 5.6](https://unetstack.net/handbook/unet-handbook_setting_up_small_networks.html#_node_locations_coordinate_systems) of the unet handbook for a discussion on origin, location and coordinate systems.

What if your modem does not have a depth sensor and you would like to use the sensor data from your AUV? In this case, you will have to run a program in the AUV's SBC to get the location data from AUV's sensors and use Unet socket APIs to update the `node.location` parameter, periodically. A pseudo code (in python) for doing this is as follows. This can easily be adapted in C or other languages.

```python
from unetpy import UnetSocket
import time

port = 1100
ip_address = 'modem IP'

sock = UnetSocket(ip_address, port)
while (1)
{
  depth = get_auv_depth()
  lat = get_auv_lat()
  lon = get_auv_lon()
  node = modem.agentForService(Services.NODE_INFO)
  node.location=[lat, lon, depth]
  time.sleep(1)
}
sock.close()
```
TODO: Verify the correctness of python pseudo code
