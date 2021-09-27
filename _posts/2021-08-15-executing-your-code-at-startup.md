---
layout: post
comments: true
title: Executing your code at startup in UnetStack
date: 15/8/2021
author: Chinmay Pendharkar
categories: howto
feature-img: "assets/img/begining.jpg"
thumbnail: "assets/img/begining.jpg"
tags: [unetstack, startup]
---

A very common usecase with UnetStack, be it on a simulator, or a physical device, is to execute your code at startup. This could be useful in a number of scenarios, including deploying physical devices in places where you may not have network connection to them to run your code, or with simulators where you might want to run many simulations in parallel with slightly different parameters.

UnetStack provides various hooks to execute your code at the different points in the startup process to support the various usecases. Certain hooks (for e.g. `startup` property in the simulator DSL) are designed to be used for executing short running code, like setting Agent parameters, or adding/removing Agents to the stack. However, executing long running code (for e.g. waiting for a message from another node in the underwater network) in such hooks, may cause the startup process to be delayed (potentially infinitely)

So let us look at the various hooks provided by UnetStack to execute your code at startup and how we can run short and long running code through them.

## Simulator

The simulation script is also standard Groovy script which is executed at the start of the simulator. The Groovy based [DSL](http://docs.groovy-lang.org/docs/latest/html/documentation/core-domain-specific-languages.html) is used to define the simulation, but standard Groovy code can also be added to the simulation script to be executed at various points.

### Simulate

Hence, the simplest way to execute code at startup is to write it as Groovy code inside the `simulate` block.

Here is an example [we looked at in a previous blog post](/motion-models), where we set up the `motionModel` property of the simulated node. 

```
simulate {
    def n = node 'B', location: [ 0.m, 0.m, 0.m], stack: "$home/etc/setup", mobility: true
    n.motionModel = [
        [time:     0.minutes, heading:  0.deg, speed:   1.mps],
        [time:     1.minutes, heading:  -90.deg, speed: 1.mps],
        [time:     2.minutes, heading:  180.deg, speed: 1.mps],
        [time:     3.minutes, heading:  90.deg, speed:  1.mps],
    ]
}

```

This code will get executed just before the start of the simulation. However, that does mean that if instead of just setting the `motionModel` property of the simulated node we try to run some long running code here, it will delay the startup startup of the simulation.

So something a simulation script like this will delay the start of the simulation by a 30 seconds:

```
simulate {
    def n = node 'B', location: [ 0.m, 0.m, 0.m], stack: "$home/etc/setup", mobility: true
    sleep 30000 // 30s - simulates some code that takes 30s to run
}
```

So, adding long running code in `simulate` block might not be a ideal, this hook is useful for setting up the simulation nodes and motion models.

### Stack

Similar to adding code in the `simulate` block, we can also add code in a couple of places in the simulation script. Firstly, we can assign a Closure to the `stack` keyword during creation of a node as shown below.

```
simulate {
    def n = node 'B', location: [ 0.m, 0.m, 0.m], mobility: true. stack: { container ->
        sleep 30000 // 30s - simulates some code that takes 30s to run
    }
}
```

Once again this Closure will be run at the begining of the simulation, and adding long running code in it (as we have done above) will delay the startup of the simulation. So it might not be a great hook to run long runnng code, but `stack` allows a user to customise the Agents to be run in each of the Simulated node.

### Startup

Finally we can also execute code at the beginning of the simulation using the `startup` property of a node as shown below.

```
simulate {
    def n = node 'B', location: [ 0.m, 0.m, 0.m], stack: "$home/etc/setup", mobility: true
    n.startup = {
        sleep 30000 // 30s - simulates some code that takes 30s to run
    }
}
```

This code is executed in the context of an Agent (`SimulationAgent`), which is responsible for doing some basic housekeeping (for e.g. run the motion model) in each node of the simulation. But being inside a [fjåge Agent](https://fjage.readthedocs.io/en/latest/behaviors.html) gives us access to Behaviours which allows us to very run our code in a background thread and hence not block the startup process.

Hence the above code will NOT delay the startup of the simulation. However, while the long running code is running, the `SimulationAgent` itself will be blocked from running and may not be able perform it's housekeeping duties.

### Agents

The most 


> NOTE: We can also create 



## UnetAudio and Modems