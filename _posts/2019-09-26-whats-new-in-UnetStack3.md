---
layout: post
comments: true
title: What's new in UnetStack3?
date: 26/9/2019
author: Mandar Chitre
categories: info
feature-img: "assets/img/unetstack3.jpg"
thumbnail: "assets/img/unetstack3-banner.jpg"
tags: [unetstack]
---

Since the first public release of UnetStack in 2013, we have been steadily adding features and improving ease of use. UnetStack3 is a major milestone in the evolution of UnetStack, debuting a software-defined modem that can run on your laptop or on an embedded computer, and adding new features such as web-based development tools, easy-to-use application programming interfaces (APIs), support for languages such as Python, Javascript, C and Julia, higher performance networking protocols, and many under-the-hood architectural enhancements. Alongside UnetStack3, we also released the Unet handbook -- a resource to help you master underwater networking and harness the full power of UnetStack3.

![UnetStack](https://unetstack.net/img/UnetStack3.png){:class="img-responsive" width="1024"}

Let's take a brief look at some of the new features:

#### 1. Unet audio

Unet audio is a software-defined open-architecture acoustic modem (SDOAM) that runs on your laptop, or on any Linux-based embedded computer with a sound card. It uses the sound card to transmit and receive sound, transforming your computer into a full-fleged acoustic modem! You get the full flexibility of UnetStack on the modem, allowing you to experiment with novel communication techniques, as well as developing and testing acoustic networking protocols with ease.

#### 2. UnetSocket API

The newly introduced [UnetSocket API](https://unetstack.net/handbook/unet-handbook_unetsocket_api.html) provides an easy-to-use software interface to integrate your applications with UnetStack. Those of you familiar with socket programming will find the API a breeze to learn. While providing simplicity, the API also offers you access to all the features in UnetStack, from transfer data files over multihop Unets to controlling the timings of transmissions accurately.

The UnetSocket API is not only available to Java or Groovy programmers, but also to Python users, enabling access to UnetStack-based modems directly from Python applications. You can now design your signals in a Jupyter notebook, transmit them straight from the cell, and receive and plot the signals in an output cell! Julia, Javascript and C programmers can leverage the fjåge gateways to integrate their applications with UnetStack.

![Jupyter](assets/img/jupyter.png){:class="img-responsive"}

#### 3. Portals

UnetStack3 introduces [portals](https://unetstack.net/handbook/unet-handbook_portals.html) to create tunnels that can transparently carry TCP connections, UDP packets, or RS232 data across an underwater network. Portals are easy to setup and configure on demand, with just a couple of commands on the shell.

#### 4. Customizable address space

As underwater bandwidth is scarce, it is important that we use it sparingly. UnetStack3 can customize your network headers to suit your deployments, using less bandwidth for small networks that require a modest address space, and switching to multibyte addresses only in large networks.

#### 5. Short-circuiting

In a traditional network stack, every layer adds it own headers and takes up valuable bandwidth. UnetStack3 agents are much smarter! Agents recognize when their functionality is not required for a specific transaction, and use a technology we call [_short-circuiting_](https://unetstack.net/handbook/unet-handbook_datagram_service.html#_short_circuit_delivery) to avoid the overhead of their headers. This not only saves bandwidth, but also processing power in energy-sensitive applications!

![Short-circuit](assets/img/shortcircuit.png){:class="img-responsive" width="700"}

#### 6. Powerful error correction

For improved reliability of acoustic links in challenging environments, UnetStack-based modems use powerful error correction codes such as LDPC. These codes are generated on-the-fly, allowing you to optimize datarate based on channel conditions.

The new ECLink agent in UnetStack provides improved performance and reliability of underwater links by utilizing techniques such as multi-ACKs and rateless erasure codes.

#### 7. Web-based IDE and simulator

The Unet simulator now comes with a web-based [integrated development environment](https://unetstack.net/handbook/unet-handbook_writing_simulation_scripts.html#_integrated_development_environment) (IDE) to help you develop and test your networking protocols interactively. The simulator can be switched to a discrete-event simulation mode to run hundreds of hours of simulation time in minutes, enabling you to collect statistics on your protocol performance rapidly.

![IDE](assets/img/ide.png){:class="img-responsive"}

#### 8. Physical-layer geotagging

If your Unet mobile node is integrated with a positioning system, every frame transmitted or received by your node is automatically geotagged.

#### 9. Time-to-live and priority

All UnetStack agents now propagate the time-to-live and priority attributes in datagrams, enabling implementation of delay tolerant network (DTN) protocols and Quality-of-Service (QoS).

#### 10. Web-based management & scripting

UnetStack-based modems provide a web-based management console so that you can manage your network in the field from your browser. The console features a [powerful shell](https://unetstack.net/handbook/unet-handbook_unetstack_basics.html) to automate repeated and error-prone operations in the field.

![IDE](assets/img/scripting.png){:class="img-responsive"}

#### 11. Shell extensions

UnetStack also leverages the new fjåge [shell extension](https://fjage.readthedocs.io/en/latest/shell.html#shell-extensions) mechanism to provide users with powerful easy-to-use commands, and on-modem documentation that can be accessed in the field. Shell extensions also enables users of legacy interfaces, such as AT commands, to access the full functionality of UnetStack.

#### 12. Connector framework

UnetStack leverages the new fjåge connector framework to connect to sensors and host applications via Ethernet, RS232 or other communication interfaces.

#### 13. Web-based agent development

Writing Groovy agents for UnetStack is easy! You can develop directly in the web interface of the node -- no need for development toolchains on your computer, no need for compilation, simply write your code in the web interface of your node and it magically runs!

![Agent](assets/img/ping.png){:class="img-responsive"}

#### 14. Lifecycle management

Newly introduced lifecycle management messages enable Unet agents to support plug-and-play discovery of ad hoc services, as new agents are loaded or unloaded from the stack.

#### 15. Unet handbook

There's so much that UnetStack can do, that we had to write a whole book about it! This free e-book provides a comprehensive hands-on guide for you to learn all about UnetStack3. Check out the [Unet handbook](http://unetstack.net/handbook) today!
