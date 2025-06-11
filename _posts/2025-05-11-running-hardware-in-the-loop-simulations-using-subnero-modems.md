---
layout: post
comments: true
title: Running Hardware-in-the-Loop Simulations Using Subnero Modems
date: 11/06/2025
author: Manu Ignatius
categories: howto
feature-img: "assets/img/search-map.jpg"
thumbnail: "assets/img/search-map.jpg"
tags: [howto, modems, simulation]
---

Underwater wireless communication is difficult to design, test, and deploy. The ocean is an unforgiving test environment, with dynamic and often unpredictable propagation characteristics. Access to vessels, dive teams, and favorable weather windows often restrict testing frequency, making rapid iteration nearly impossible.

For researchers, engineers, and system integrators working on underwater networks, simulation is an essential first step. It allows:
- Protocol design and debugging
- Performance evaluation under varying conditions
- Network behavior visualization
- Risk reduction before expensive deployments

## Why Hardware-in-the-Loop (HIL)?

While pure software simulation (where all nodes run on a single computer) is useful, it falls short in certain cases, particularly when real-time behavior, hardware driver integration, and system compatibility are important.

Imagine you are a researcher developing a large scale underwater network. You want to validate not only your algorithms but also the performance of the modems you plan to use in the field. Before investing time and money into an offshore campaign, you want confidence that your system behaves correctly—both in logic and in timing. You also want to try out multiple configurations quickly.

This is where HIL simulations shine. By keeping your real hardware in the loop, you:
- Test the actual modem hardware, drivers, and firmware
- Verify timing behavior and interface compatibility
- Run real world network software with simulated acoustic links

If your modem is software-defined and open-architecture, such as Subnero's modems, HIL offers a development experience that closely mirrors actual deployment.

## The Foundation: Subnero Modems + Virtual Acoustic Ocean

Subnero's modems run UnetStack, an open-architecture, software-defined acoustic modem (SDOAM) framework. This allows users to:
- Customize physical and network layer behaviors
- Deploy the exact same software in simulation and in the ocean
- Extend or override components with user-defined protocols

[Virtual Acoustic Ocean (VAO)] (https://github.com/org-arl/VirtualAcousticOcean.jl) is an open-source acoustic channel simulator developed in Julia. It allows users to:
- Simulate channel propagation using models like Bellhop, Kraken, Pekeris RAT
- Set up nodes with position, protocol stack, and acoustic properties
- Run interactive or batch-mode simulations over UDP/IP

Together, these tools unlock scalable, reproducible HIL simulations.

## Typical Use Cases
- **Researchers** testing new communication algorithms (e.g. physical layer, network layer etc.) with realistic conditions
- **Commercial users** simulating data harvesting from sensors or AUVs in unknown environments
- **Defense teams** validating mission scenarios where real-world testing is restricted or classified

## Step-by-Step Guide to HIL Simulation

Before beginning the simulation, ensure you have the following setup:
- Two Subnero modems running UnetStack v5
- A laptop or mini-PC with Julia installed, capable of running the Virtual Acoustic Ocean (VAO) simulator
- An Ethernet switch to connect all devices to the same network

All three components—both modems and the VAO-running machine—should be on the same subnet and able to reach each other via IP

> NOTE: It is strongly recommended to use an isolated network switch (without internet access) to avoid interference from unrelated network traffic during simulation.

Here is a reference block diagram of a typical HIL simulation setup:

TODO:

1. Install VAO

```
git clone https://github.com/org-arl/VirtualAcousticOcean.jl.git
cd VirtualAcousticOcean.jl
julia --project=.
```

Inside Julia's package manager:

```
pkg> instantiate
```

2. Add Example Scenario

Copy the `2-node-network-1.jl` file to the `examples/` folder of the cloned VAO repository.

Example content:

```
using VirtualAcousticOcean
using UnderwaterAcoustics
using Sockets

env = UnderwaterEnvironment()
pm = PekerisRayModel(env, 7)
sim = Simulation(pm, 24000.0)
addnode!(sim, (0.0, 0.0, -10.0), UASP2, 9800, ip"0.0.0.0")
addnode!(sim, (1000.0, 0.0, -10.0), UASP2, 9810, ip"0.0.0.0")
run(sim)

println("Simulation running with these nodes:")
for (idx, node) in enumerate(sim.nodes)
    println("  - Node $(idx) at position $(node.pos) receiving on UDP port $(node.conn.port)")
end

wait()
```

Run the simulation:

```
julia --project=. examples/2-node-network-1.jl
```

3. Configure Subnero Modems

Each modem needs to be configured to redirect its baseband interface to VAO. Access each modem's web interface and upload the following `modem.toml` to the Scripts folder:

[input]
analoginterface = "UASP2DAQ"
ip = "192.168.42.10"
port = 9810

[output]
ip = "192.168.42.10"

Ensure each modem uses the correct port as defined in the VAO simulation script—9800 for the first node and 9810 for the second.

After uploading, reboot the modem.

Check the setup using the modem shell:

bb

You should see:

Baseband service for SoundcardDAQ.AnalogInterface

If not, the configuration may be incorrect.

4. Set Transmit Power to Zero

plvl 0

5. Test the Link

This simulation script places two nodes 1 km apart. As such, full transmit power should be used:

plvl 7

To test the link, you can use the tell command from the shell of one modem to send a message to the other:

tell 9800 "Hello from Node B"

You should see the message received on the other modem's shell, confirming that the simulated link is working.

subscribe phy

Optional: OEM Configuration

If you do not have Subnero modems, you can still simulate the system using UnetStack OEM Edition on single-board computers (e.g., Jetson Nano). The simulation behavior will be the same, enabling rapid prototyping.

Visual Setup

Here's a sample setup diagram illustrating the components:



Additional Resources

VAO repository: https://github.com/org-arl/VirtualAcousticOcean.jl

UnetStack: https://unetstack.net

Subnero: https://subnero.com

For questions, contact the Subnero support team or check out additional examples in the VAO GitHub repository.

