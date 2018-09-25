---
layout: post
title: Developing location agent for UnetStack
date: 14/09/2018
author: Manu Ignatius
categories: howto
feature-img: "assets/img/search-map.jpg"
thumbnail: "assets/img/search-map.jpg"
tags: [howto, modems, localization, location]
---

Imagine you are out at sea, doing underwater communications field experiments, with underwater acoustic modems deployed from a boat or a vessel. If you are a researcher, you might be interested in transmitting your custom designed signals to study the underwater channel. If you are commercial company manufacturing modems, you might be testing the localization performance of your modems. Regardless of the application, one of the most valuable metric that can be attached with each and every data frame or signal transmission and reception is the location information of the modems, i.e. geotagging the data (similar to time-stamping data).

![](assets/img/trial.jpg)

Since GPS doesn't work underwater, one obvious method is to note down the GPS location of the boat or vessel from where the modems are deployed. However, depending on the deployment scenario, the location of the vessel will change over time and hence this method is error prone. Another (slightly better) method is to use your phone to have a periodic GPS log and sync it with the timestamps of your transmissions, during post processing of your data. While this method gives you a log of your GPS coordinates, merging this with modem logs is an additional step, which we would like to avoid.

With UnetStack running in the modems, such an application is easy to develop. UnetStack comes equipped with `node` agent and [`NODE_INFO`](https://www.unetstack.net/svc-00-nodeinfo.html) service that will keep track of the modem location (as well as other parameters like speed, heading etc.), which can be used to geotag individual transmissions or receptions. All we have to do is develop a simple [Unet agent](https://www.unetstack.net/unet-agents.html) that will update the `location` parameter of the `node` agent, in a periodic manner.

## Setup
The agent can be developed for a variety of scenarios. For the purpose of this blog, we will use one of the test setups that we have used in the past where space was a constraint. We had a TCP/IP network to which all assets where connected and accessible. We used one of our smartphones as the GPS server and connected to the same network.

There are many apps that support running a GPS server in your smartphone. For our past trials, we have used [GPS Sharing for Windows Sensor](https://play.google.com/store/apps/details?id=com.michaelchourdakis.windows7gpssharing&hl=en) app, that will stream the GPS NMEA strings to a user specified TCP port.

## A simple location agent
The basic flow of the `Location Agent` will be as follows:
```
1. Connect to an available GPS server.
2. If available, read NMEA streams and look for $GPGGA or $GPRMC strings.
3. Parse them to retrieve latitude and longitude.
4. Update node agent.
5. Repeat steps 2 - 4 in user defined interval.
```

## Various components

### Basic structure & initialization
In the `startup()` method of UnetStack, the agent tries to connect to a GPS server. The _IP address_ and _port_ of the GPS server can either be preconfigured or let the user configure later. The `connectToServer()` method can also be called when there is a change in any of the parameters (e.g. _IP address_, _port_).

> NOTE: The code provided in this blog is a simple version for illustration. Error checks or retries/timeouts are omitted from the code to keep it clean.
> Full code is available in [Unet Contrib](https://github.com/org-arl/unet-contrib) repo [here](https://github.com/org-arl/unet-contrib/tree/master/contrib/Location).

```java
import org.arl.fjage.*;
import org.arl.unet.*;

public class MyLocation extends UnetAgent {

  String ip = null;
  int port = 0;
  int locationUpdatePeriod = 1;  // GPS location update period
  
  double latD = 0.0;    // Latitude in degrees
  double latM = 0.0;    // Latitude in minutes
  double longD = 0.0;   // Longitude in degrees
  double longM = 0.0;   // Longitude in minutes
  
  void startup() {
    connectToServer();
  }
  
  void shutdown() {
    closeConnection();
  }
}
```

### Connecting to GPS server
In the `connectToServer()` method, we use the `connect()` method from `socket` library to connect to the server. Once connected, we read the NMEA data in a periodic manner using a [`TickerBehavior`](http://org-arl.github.io/fjage/doc/html/behaviors.html):
```java
  void connectToServer() {
    clientSocket.connect(new InetSocketAddress(ip, port), timeout);
    locationUpdate = new TickerBehavior(locationUpdatePeriod*1000) {
      @Override
      public void onTick() {
        readNmeaData();
      }
    };
    add(locationUpdate);
  }
```

### Reading and parsing NMEA data
The next step is to parse the NMEA stream. We parsed `$GPGGA`, `$GNGGA` and `$GPRMC` strings. The sample code is as follows:

```java
  void readNmeaData() {
    BufferedReader inFromServer = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
    if ((nmeaLine = inFromServer.readLine()) != null) {

      if (nmeaLine.startsWith("$GPRMC")) {
        parseGPRMC(nmeaLine);
        updateLocation();
      }
      else if (nmeaLine.startsWith("$GPGGA") || nmeaLine.startsWith("$GNGGA")) {
        parseGPGGA(nmeaLine);
        updateLocation();
      }
    }
  }
  
  void parseGPGGA(String nl) {
    String[] gpgga = nl.split(",");
    lastFixTime = gpgga[1].substring(0,2)+":"+gpgga[1].substring(2,4)+":"+gpgga[1].substring(4,6)+gpgga[1].substring(6)+" UTC";

    String latd = gpgga[2].split("\\.")[0];
    String latm1 = gpgga[2].split("\\.")[1];
    String lond = gpgga[4].split("\\.")[0];
    String lonm1 = gpgga[4].split("\\.")[1];

    String latm = latd.substring(latd.length()-2);
    latm=latm.concat(".");
    latm=latm.concat(latm1);
    latd = latd.substring(0, latd.length()-2);

    String lonm = lond.substring(lond.length()-2);
    lonm=lonm.concat(".");
    lonm=lonm.concat(lonm1);
    lond = lond.substring(0, lond.length()-2);

    latD = Double.parseDouble(latd);
    latM = Double.parseDouble(latm);
    longD = Double.parseDouble(lond);
    longM = Double.parseDouble(lonm);
  }
```
Once the NMEA string is parsed, the latitude and longitude values are stored in `latD`, `latM`, `longD` and `longM` variables.
> NOTE: Since parsing other NMEA strings are similar to that of `$GPGGA`, the implementation is skipped.

### Updating `location` parameter of `node` agent
Now that we have the GPS coordinates, we need to set/update the `location` parameter of the `node` agent. Since `node` agent stores `location` in local coordinates, we need to convert the GPS coordinates to local coordinates. This can be done using the `GpsLocalFrame` helper class in UnetStack. The simplified code is as follows:

```java
  private void updateLocation () {
    ParameterReq req = new ParameterReq(agentForService(Services.NODE_INFO));
    
    // Get origin
    req.get(NodeInfoParam.origin);
    ParameterRsp rsp = (ParameterRsp) request(req, 1000);
    double[] origin = (double[])rsp.get(NodeInfoParam.origin);
  
    // Convert to local coordinates and update current location
    GpsLocalFrame gps = new GpsLocalFrame(origin[0], origin[1]);
    double[] xy = new double[2];
    xy = gps.toLocal(latD, latM, longD, longM);
    if (xy.length == 2) {
      req = new ParameterReq(agentForService(Services.NODE_INFO));
      req.set(NodeInfoParam.location, xy);
      rsp = (ParameterRsp)request(req, 1000);
    }
  }
```

### Parameters, getters & setters
We also need to implement getters and setters for the various parameters. Some of the getters are given below:
```java
  public String getIp() {
    return this.ip;
  }
  
  public int getPort() {
    return this.port;
  }
  
  public double getLatD() {
    return this.latD;
  }

  public double getLatM() {
    return this.latM;
  }

  public double getLongD() {
    return this.longD;
  }

  public double getLongM() {
    return this.longM;
  }
  
  public int getLocationUpdatePeriod() {
    return this.locationUpdatePeriod;
  }
```

Setters generally have slightly more logic. The simplified version is given below. Once again, note that error checks are not included.
```java
  public void setIp(String value) {
    this.ip = value;
  }
  
  public void setPort (int value) {
    this.port = value;
  }
  
  public void setLocationUpdatePeriod(int value) {
    if (value >= 0) {
      this.locationUpdatePeriod = value;
      if (locationUpdate != null) locationUpdate.stop();
      if (value == 0) locationUpdate = null;
      else { // Reset ticker behavior where there is a change
        locationUpdate = new TickerBehavior(value*1000) {
          @Override
          public void onTick() {
            readNmeaData();
          }
        };
        add(locationUpdate);
      }
    }
  }
```
Thats it, the basic implementation of a simple location agent is complete.

## Loading the location agent

Now that we have the location agent ready, all we have to do is to load it in UnetStack. It can be done manually by typing:
```groovy
container.add 'loc', new MyLocation()
```
When you run UnetStack, you should be able to see (using the shell) your agent and interact with it just like any other agent running in UnetStack.
```groovy
> ps
loc: MyLocation - IDLE
```
The  _IP address_ and _port_ of the server can be set as follows:
```groovy
> loc = agent('loc')
> loc.ip="192.168.1.10"
> loc.port=7777
```
Once the agent starts receiving NMEA stream, it will update its own GPS coordinates,
```groovy
> loc.latD
1
> loc.latM
21.119484
> loc.longD
103
> loc.longM
45.542248
```
and also the `node` agent's `location` parameter.
```groovy
> node
[org.arl.unet.nodeinfo.NodeInfoParam]
  address = 1
  canForward = false
  diveRate = 0
  heading = 0
  location = [1.9605354193454196, -10.464070507339857]
  mobility = false
  nodeName = 1
  origin = [1.3520860333333333, 103.75901985]
  speed = 0
  time = Thu Sep 20 12:00:00 SGT 2018
  turnRate = 0
```

Once the `location` agent is loaded and running, the modem will be location aware. Any agent can request the location information from the `node` agent using a [`ParameterReq`](https://www.unetstack.net/javadoc/index.html?org/arl/unet/ParameterReq.html) for geotagging.
