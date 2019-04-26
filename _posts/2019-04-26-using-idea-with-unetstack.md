---
layout: post
comments: true
title: Using IntelliJ IDEA with UnetStack
date: 26/4/2019
author: Arnav Dhamija
categories: howto
feature-img: "assets/img/electronics.jpg"
thumbnail: "assets/img/electronics.jpg"
tags: [howto, agents, unetstack]
---

UnetStack is bundled with the UnetIDE for developing agents. While the UnetIDE is well integrated with UnetStack, using a more feature rich IDE can be instrumental in boosting productivity when working with larger projects. In this tutorial, we will go through the steps required to create a UnetAgent using the powerful [IntelliJ IDEA](https://www.jetbrains.com/idea/) Java IDE.

## Installation

IntelliJ IDEA Community edition can be downloaded for free from the [IntelliJ downloads page](https://www.jetbrains.com/idea/download/#section=linux). Alternatively, if you're on Ubuntu 16.04+, you can download the snap package instead for automatic updates:

`sudo snap install intellij-idea-community --classic`

Following this, download the latest copy of UnetStack for your operating system from [here](https://www.unetstack.net/downloads.html). Extract the files in a directory of your choice.

From here, we can look at how we can create a new `UnetAgent` using IntelliJ.

## Setting up your project

On the first run of IDEA, you will be presented with the following Welcome Screen:

![](assets/img/idea-setup/0.png)

Click on create a new project and choose "Java" project on the following screen. Leave the Groovy and Kotlin/JVM options unselected. We will be adding our own libraries later on.

![](assets/img/idea-setup/1.png)

Leave the "Create project from template" option unselected on the following screen.

![](assets/img/idea-setup/2.png)

In the next screen you will have to choose the name of your project. Let's call it `MyAwesomeAgent` for the purpose of this tutorial. This name doesn't really need to follow any convention as we won't be using it later on.

![](assets/img/idea-setup/3.png)

Once you've completed all these steps, you will notice that IDEA has created a new directory with they name of your project with the following directories:

```
src/
MyAwesomeAgent.iml
```

We need to create all of source files in the `src/` directory. Before doing so, let's add the Unet JARs to our projects.

Go to __File > Project Structure__ in the toolbar. Open the __Libraries__ pane as shown in the left hand column. You will be presented with the following screen:

![](assets/img/idea-setup/4.png)

Select Java project library and look for the Unet JARs you extracted in the Installation step of this tutorial. The exact location depends on the version of Unet and OS you're using. For example, in `unetsim-1.4-linux`, these JARs are available in `unetsim-1.4-linux/UnetIDE/app/lib` and in the pre-release build of UnetStack3, these JARs can be found in `UnetStack3/lib`. Either way, you will only need to select the top-level directory where all the JARs are present. IDEA will automatically add all the JARs in this directory to your project.

![](assets/img/idea-setup/1.png)

After doing this, your Project settings screen should look like this:

![](assets/img/idea-setup/6.png)

We can now start writing our agent.

## Writing the Agent

Create a new Groovy in the `src/` directory of your project by right-clicking the `src` directory in Project pane in IDEA.

![](assets/img/idea-setup/project.png)

In this example, the agent we're writing will be called `AwesomeAgent`. The code for the same is below. For more information about writing agents, refer to the Unet [documentation](https://www.unetstack.net/unet-agents.html).

```
import org.arl.fjage.Message
import org.arl.unet.UnetAgent

class AwesomeAgent extends UnetAgent {
    void setup() {
        log.info("Hello world!")
    }

    void startup() {
        // this method is called just after the stack is running
        // look up other agents and services here, as needed
        // subscribe to topics of interest here, to get notifications
    }

    Message processRequest(Message msg) {
        // process requests supported by the agent, and return responses
        // if request is not processed, return null
        return null
    }

    void processMessage(Message msg) {
        // process other messages, such as notifications here
    }

}
```

This is a simple `UnetAgent` which will print "Hello world!" on setup and do nothing else.

__NOTE:__ If you have source files in directories other than `src/` you will NEED to inform IDEA about this by right-clicking the other directories and then going to __Mark Directory as > Sources Root__. Otherwise, IDEA will not be able to correctly add these files to the module's classpath.

After doing so, we need to write a simulation script to check if everything is working. For keeping the code organised, create a new `sim/` directory and create a new Groovy script in this directory. Let's call it `simple_sim.groovy`. We will write a very simple simulation script as shown below:

```
import org.arl.unet.link.ReliableLink
import org.arl.unet.sim.channels.ProtocolChannelModel

platform = RealTimePlatform
channel.model = ProtocolChannelModel

simulate {
    node '1', address: 1, location: [0, 0, 0], shell: true, stack: { container ->
        container.add 'da', new AwesomeAgent()
        container.add 'link', new ReliableLink()
    }
}
```

## Running Simulations

Now we will have to configure our IDE to run this script by adding a new configuration. For doing so, click the "Add New Configuration" button at the top-right of the IDE:


![](assets/img/idea-setup/7.png)

Select "Application" on the following screen.

![](assets/img/idea-setup/config.png)

After choosing a suitable name for this configuration, set the "Main class" to `GroovyBoot`. The "Program arguments" will need to be set according to the path of your simulation script. As our simulation script is located in the `sim/` directory, we will need to fill in `cls://org.arl.unet.sim.initrc sim/simple_sim.groovy` over here.

Take note of the "Working directory" path as we will need this later.

In the end, your configuration window should look like this:

![](assets/img/idea-setup/8.png)

Great! Now let's try to run our simulation by pressing the play button in the top right! 

If you've been following all the steps perfectly so far, you should be greeted with the following error:

```
Can't load log handler "java.util.logging.FileHandler"
java.nio.file.NoSuchFileException: logs/log-0.txt.lck
java.nio.file.NoSuchFileException: logs/log-0.txt.lck
```

This happened because we haven't yet created a logs directory for the simulator to write log and trace files. Hence, we will need to create an empty `logs` directory right under the "Working directory" path we found in the configuration window.

After creating this `logs/` folder, your project directory will have the following structure:

```
src/AwesomeAgent.groovy
sim/simple_sim.groovy
logs/
MyAwesomeAgent.iml
```

Now, you should be able to run the simulation and interact with the agent in the integrated console in IDEA.

![](assets/img/idea-setup/9.png)

This concludes our tutorial!

## Using IDEA's Visual Debugger

Refer to the instructions available [here](https://www.jetbrains.com/help/idea/debugging-code.html).