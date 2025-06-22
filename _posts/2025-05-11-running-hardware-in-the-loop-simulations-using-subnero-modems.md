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

For researchers, engineers, and system integrators working on underwater networks, simulation is an essential first step. It enables protocol design and debugging, visualizes network behavior, and allows performance evaluation under varying conditions. Most importantly, simulation helps reduce risk before committing to expensive deployments.

## Why Hardware-in-the-Loop (HIL)?

While pure software simulation (where all nodes run on a single computer) is useful, it falls short in certain cases, particularly when real-time behavior, hardware driver integration, and system compatibility are important.

Imagine you are a researcher developing a large scale underwater network. You want to validate not only your algorithms but also the performance of the modems you plan to use in the field. Before investing time and money into an offshore campaign, you want confidence that your system behaves correctly, both in logic and in timing. You also want to try out multiple configurations quickly.

This is where HIL simulations shine. By keeping your real hardware in the loop, you:

- Test the actual modem hardware, drivers, and firmware.
- Verify timing behavior and interface compatibility of your algorithms in the modems.
- Run real world network software with simulated acoustic links.

If your modem is software-defined and open-architecture, such as Subnero's modems, HIL offers a development experience that closely mirrors actual deployment.

## The Foundation: Subnero Modems + Virtual Acoustic Ocean

Subnero’s modems run UnetStack, a fully software-defined, open-architecture modem framework. This enables users to customize physical and network layers, extend built-in components, and use the exact same software stack in both simulated and real-world deployments.

[Virtual Acoustic Ocean (VAO)](https://github.com/org-arl/VirtualAcousticOcean.jl) is an open-source acoustic channel simulator. It supports standard propagation models, and allows users to define node positions, protocol stack parameters, and environmental conditions. Simulations can be run in interactive mode, making VAO suitable for everything from basic tests to complex protocol validation.

With a Subnero modem running UnetStack v5 onwards and VAO, users are now able to unlock scalable, reproducible HIL simulations that can closely mirror real-world underwater communication scenarios while enabling rapid, repeatable testing without going to sea.

## Typical Use Cases

- **Researchers** testing new communication algorithms (e.g. physical layer, network layer etc.) with realistic conditions.
- **Commercial users** simulating data harvesting from sensors or AUVs in unknown environments.
- **Defense teams** validating mission scenarios where real-world testing is restricted or classified.

## Step-by-Step Guide to HIL Simulation

Before beginning the simulation, ensure you have the following setup:

- Two Subnero M25M series modems running UnetStack v5.
- A laptop or mini-PC with Julia installed, capable of running the Virtual Acoustic Ocean (VAO) simulator.
- An Ethernet switch to connect all devices to the same network.

All components — modems and the VAO-running machine — should be on the same subnet to be able to reach each other using their IP address.

> **TIP:** Use an isolated network switch (without internet access) to avoid interference from unrelated network traffic during simulation.

> Note: This example uses Subnero M25M (MF-band) modems, but the same steps apply to Subnero's LF and HF modems. The simulation script provided is just one example — please refer to the VAO GitHub repository for the latest examples, which may differ. This guide shows how to connect two Subnero modems, but more nodes can be added by extending the script with additional addnode! lines.

---

### 1. Install VAO and Packages

At a Julia terminal:

```julia
using Pkg
Pkg.add("VirtualAcousticOcean")
Pkg.add("UnderwaterAcoustics")
Pkg.add("Sockets")
```

---

### 2. Add Example Scenario

Copy the `2-node-network.jl` file from the [GitHub repo](https://github.com/org-arl/VirtualAcousticOcean.jl) examples folder to your working directory.

**Example content:**

```julia
using VirtualAcousticOcean
using UnderwaterAcoustics
using Sockets

env = UnderwaterEnvironment(seabed=SandyClay, bathymetry=40.0)
pm = PekerisRayTracer(env)
sim = Simulation(pm, 24000.0)
addnode!(sim, (0.0, 0.0, -10.0), UASP2, 9809, ip"0.0.0.0")
addnode!(sim, (1000.0, 0.0, -10.0), UASP2, 9819, ip"0.0.0.0")
run(sim)

println("Simulation running with these nodes:")
for (idx, node) in enumerate(sim.nodes)
    println("  - Node $(idx) at position $(node.pos) receiving on UDP port $(node.conn.port)")
end

wait()
```

**Run it from the terminal:**

```bash
> julia 2-node-network-1.jl
```

---

### 3. Configure Subnero Modems

Access each modem’s web UI and upload this `modem.toml` to the Scripts folder:

```toml
[input]
analoginterface = "UASP2DAQ"
ip = "192.168.42.10"
port = 9809
```

> Ensure this matches the VAO machine's IP and each modem uses the correct port (9809 and 9819).

**Verify the setup via modem shell:**

```shell
bb
```

**Expected output:**

```
> bb
« Baseband »

Baseband service for UASP2DAQ.AnalogInterface
...
```

Also check modem logs for an entry similar to:

```
1750584190212	INFO	UASP2DAQ@27:UASP2DAQ@1:57	Connecting to UASP2 DAQ at 192.168.42.10:9809...
```

---

### 4. Set Transmit Power

Since the modems are deployed 1km apart, set full transmit power:

```shell
plvl 0
```

---

### 5. Test the Link

Send a test message from either of the modem's shell:

```shell
tell 0 "Hello Sea"
```

You should see the message on the receiving modem’s shell.

---

## UnetStack OEM Edition + VAO

If you do not have Subnero modems, you can still simulate the system using UnetStack OEM Edition on single-board computers (e.g., Jetson Orin Nano). The simulation behavior will be the same, enabling rapid prototyping.

Contact [info@subnero.com](mailto:info@subnero.com) for more information.

---

## Additional Resources

- [VAO GitHub Repository](https://github.com/org-arl/VirtualAcousticOcean.jl)  
- [UnetStack](https://unetstack.net)  
- [Subnero](https://subnero.com)
