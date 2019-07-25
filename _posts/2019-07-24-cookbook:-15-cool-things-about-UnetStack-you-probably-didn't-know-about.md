---
layout: post
comments: true
title: Cookbook\: 15 Cool things about UnetStack you probably didn't know about
date: 24/7/2019
author: Mandar Chitre, Manu Ignatius
categories: howto
feature-img: "assets/img/water.jpg"
thumbnail: "assets/img/water.jpg"
tags: [howto, agents, unetstack]
---

1. [Using agent names in shell](#head1)
2. [Accessing current simulation count](#head2)
3. [Accessing platform time and clock time](#head3)
4. [Suppressing simulation progress](#head4)
5. [Calculating distances between nodes](#head5)
6. [Programmatically stopping a simulation](#head6)
7. [Setting log level of the simulation agent](#head7)
8. [Specifying relative paths for files](#head8)
9. [Redefining closures in the shell](#head9)
10. [Working with GPS coordinates](#head10)
11. [Distributing nodes randomly](#head11)
12. [Encoding and decoding PDUs](#head12)
13. [Using MATLAB to plot results](#head13)
14. [Using a visual debugger in agent development](#head14)
15. [Using a groovy shell to create files](#head15)


## <a name="head1"></a>1. Using agent names in shell

Throughout the documentation, you find agents referred to as `phy`, `link`, etc. instead of `agent('phy')`, `agent('link')`, etc. This works simply because the shell initialization scripts assign the later to the former:

```
phy = agent('phy');
link = agent('link');
  :
  :
```

This allows for a simpler syntax in the shell, such as:
```
phy << new DatagramReq(...)
phy.MTU
  :
  :
```

rather than:
```
agent('phy') << new DatagramReq(...)
agent('phy').MTU
  :
  :
```

If you create and add your own agents to the stack, you may wish to add similar variables to the shell by adding the declarations to `etc/fshrc.groovy` (and ensuring that this file is added as an initialization script when the shell agent is created).

## <a name="head2"></a> 2. Accessing current simulation count
The current simulation `count` can be accessed using the count variable in a simulation script. For example:
```
//! Simulation: Demo of using simulation count

[...].each { p ->
  simulate 10.hours {
    println "Simulation #${count} for parameter = ${p}"
      :
      :
  }
}
```

## <a name="head3"></a> 3. Accessing platform time and clock time
The platform time (discrete event or real-time) can be accessed using the `time()` closure in a simulation script. The clock time can be accessed using the `clock()` closure. Both closures provide time in seconds from some arbitrary origin. For example:
```
//! Simulation: Demo of clock()

def t0 = clock()
simulate 10.hours {
    :
    :
}
println "10 hours worth of simulation completed in ${clock()-t0} seconds"
```

## <a name="head4"></a> 4. Suppressing simulation progress
By default, the simulation progress is displayed on the terminal for Mac OS X and Linux. For Windows, due to lack of support in Cygwin for ANSI terminal sequences, this is disabled. Should you wish to suppress the display of simulation progress, set the variable `showProgress` in your simulation script to be `false`:

```
showProgress = false
```

## <a name="head5"></a> 5. Calculating distances between nodes
A closure `distance()` is available in the simulation script to compute distance between two locations:
```
def location1 = [0, 0, 0]
def location2 = [300.m, 1.km, 0]
println distance(location1, location2)
```

## <a name="head6"></a> 6. Programmatically stopping a simulation
You can stop a simulation from your simulation agent by calling the `stop()` closure. For example:
```
//! Simulation: Demo of stop()

import org.arl.fjage.TickerBehavior

simulate {
  def n = node 'AUV', address: 1
  n.startup = {
    // stop simulation with a probability of 1% at every 10 second boundary
    add new TickerBehavior(10000, {
      if (rnd(0,1) < 0.01) stop()
    })
  }
}
```

## <a name="head7"></a> 7. Setting log level of the simulation agent
A simple way to change log level of the simulation agent is via the `logLevel` variable in the simulation script. For example:
```
logLevel = java.logging.Level.ALL
```

## <a name="head8"></a> 8. Specifying relative paths for files
When a simulation is run, a `home` variable is defined to point to the simulator installation directory. This is useful to refer to common files:
```
// set up node 1 with stack loaded from the common setup.groovy file
node '1', address: 1, stack: "$home/etc/setup.groovy"
```

Another variable `script` is defined to point to the simulation script file being executed. This can be used to find the directory containing the script file, if other files in the same directory need to be referenced:
```
// load a settings file from the same directory as the script
run "${script.parent}/settings.groovy"
```

## <a name="head9"></a> 9. Redefining closures in the shell
To avoid the mistakes from accidentally overwriting closures in the shell, by default, the shell disallows redefining previously defined closures. For example:
```
> host = 1
java.lang.RuntimeException: Closure host is read only
```
since `host` is a predefined closure that resolves host names to addresses. If we wanted to redefine the closure, we can do so by setting the `protection` variable in the shell to `false`:
```
> protection = false;
> host = 1
1
> println host
1
> protection = true;
```
## <a name="head10"></a> 10. Working with GPS coordinates
Sometimes it is useful to work with GPS coordinates for node locations, but the simulator uses a local coordinate frame. Here’s how to easily convert from one to another.

First create a local coordinate system with a specified origin:
```
> gps = new org.arl.unet.utils.GpsLocalFrame(1.289545, 103.849972);
```

Then convert node GPS coordinates to local frame (coordinates in meters):
```
> gps.toLocal(1.29, 103.85)               // decimal degrees
[3.1161606856705233, 50.311549937515956]
> gps.toLocal(1, 17.4, 103, 51)           // degrees, decimal minutes
[3.1161606856705233, 50.311549937515956]
```

or convert from local frame to GPS coordinates:
```
> gps.toGps(1000.m, 500.m)                // decimal degrees
[1.2940668245170857, 103.85895741597328]
> gps.toGpsDM(1000.m, 500.m)              // degrees, decimal minutes
[1.0, 17.64400947102514, 103.0, 51.53744495839675]
```

There are other options for GPS coordinate formats too (e.g. degrees, minutes, seconds).

## <a name="head11"></a> 11. Distributing nodes randomly
Often, in simulations, we wish to distribute nodes randomly in a given area. Here’s how to do that in a simulation script:
```
//! Simulation: Demo of randomly deployed nodes

platform = org.arl.fjage.RealTimePlatform

def n = 10          // number of nodes
def xsize = 1.km    // distribute nodes in a 1.km x 1.km box, within a depth of 20.m
def ysize = 1.km
def maxdepth = 20.m

simulate {
  n.times {
    node "${it+1}", location: [rnd(-xsize/2, xsize/2), rnd(-ysize/2, ysize/2), rnd(-maxdepth, 0)]
  }
}
```

## <a name="head12"></a> 12. Encoding and decoding PDUs
When implementing protocols, we often need to assemble and parse PDUs. To ease this task, we have a PDU utility class to help. We first define a class with our PDU format:
```
 import java.nio.ByteOrder
 import org.arl.unet.PDU

 class MyPDU extends PDU {
   void format() {
     length(16)                     // 16 byte PDU
     order(ByteOrder.BIG_ENDIAN)    // byte ordering is big endian
     uint8('type')                  // 1 byte field 'type'
     uint8(0x01)                    // literal byte 0x01
     filler(2)                      // 2 filler bytes
     uint16('data')                 // 2 byte field 'data' as unsigned short
     padding(0xff)                  // padded with 0xff to make 16 bytes
   }
}
```

We can then encode and decode PDUs easily using this class:
```
> pdu = new MyPDU();
> bytes = pdu.encode([type: 7, data: 42])
[7, 1, 0, 0, 0, 42, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
> pdu.decode(bytes)
[data:42, type:7]
```
In some cases, it is convenient to define a PDU without explicitly defining a new class. In that case, we can create an anonymous class with the standard Java syntax, or using the Groovy extensions syntax shown here:

```
def pdu = PDU.withFormat {
  length(16)                     // 16 byte PDU
  order(ByteOrder.BIG_ENDIAN)    // byte ordering is big endian
  uint8('type')                  // 1 byte field 'type'
  uint8(0x01)                    // literal byte 0x01
  filler(2)                      // 2 filler bytes
  uint16('data')                 // 2 byte field 'data' as unsigned short
  padding(0xff)                  // padded with 0xff to make 16 bytes
}
bytes = pdu.encode([type: 7, data: 42])
data = pdu.decode(bytes)
```
For further information, see PDU API documentation.

## <a name="head13"></a> 13. Using MATLAB to plot results
The samples provided with UnetStack show how to plot results (e.g. `samples/aloha/plot-results.groovy`) using a Groovy script. Sometimes you may wish to use other tools such as MATLAB to analyze the results. To do this, you’ll need to extract relevant results from the log file and then load them in MATLAB.

For example, let us assume that you just ran the `samples/aloha/aloha.groovy` simulation and have the log files in the `logs` directory. You can extract the relevant STATS lines from the log file and reformat into a CSV file that MATLAB can load:

```
bash$ grep STATS logs/trace.nam | sed 's/.=//g' | sed 's/^# STATS: //' > logs/results.txt
```

Then open MATLAB and load the data in MATLAB, and plot it:
```
>> load logs/results.txt
>> x = 0:0.05:2;
>> plot(x, x.*exp(-2*x))
>> hold all
>> plot(results(:,5),results(:,8),'*')
>> hold off
>> ylabel('Normalized Throughput');
>> xlabel('Offered Load');
```


The output should look like this:

![](assets/img/aloha-matlab.png)

## <a name="head14"></a> 14. Using a visual debugger in agent development
While the Unet IDE does not have an integrated debugger, it is possible to use a debugger from another IDE (e.g. [IntelliJ IDEA](https://www.jetbrains.com/idea/) or [Eclipse](https://eclipse.org/downloads/)) with UnetStack. The basic steps are outlined below, but the exact details depend on the IDE used:

- Downloaded and install the IDE with Groovy support.
- Create a Groovy project and added all UnetStack jars as external libraries. You should find the jars in the UnetIDE.app/Contents/Java folder on Mac OS X, or the app folder on Linux or Windows.
- Create a configuration with main class org.arl.fjage.shell.GroovyBoot and arguments cls://org.arl.unet.sim.initrc followed by the simulation script filename.
- Start a debugging session.
More details for using IntelliJ IDEA can be found [here](https://blog.unetstack.net/using-idea-with-unetstack).

## <a name="head15"></a> 15. Using a groovy shell to create files
There are times when you have access to a Groovy shell, but not direct access to the scripts folder or the filesystem to create a new Groovy script (or to modify an existing script). An example is, if you are out in the field, connected to a device running UnetStack using a primitive interface such as RS232. You can still use the Groovy shell to create a file in the scripts folder. The syntax is:

```
file("abcd.groovy").text="print 'hello sea 1'\\nprint 'hello sea 2'"
```

This will create (or modify if there is an existing file) a file with the content:
```
print 'hello sea 1'
print 'hello sea 2'
```
> NOTE: Make sure you use two '\\' for '\n'
