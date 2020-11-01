---
layout: post
comments: true
title: Harnessing the power of Julia in UnetStack — Part II
date: 01/11/2020
author: Mandar Chitre
categories: howto
feature-img: "assets/img/custom-julia-phy.png"
thumbnail: "assets/img/custom-julia-phy.png"
tags: [howto, julia, unetstack, modems, phy, agents]
---

In my previous article on [developing your own acoustic PHY]({% post_url 2020-10-31-custom-phy %}), I showed you how to develop your own acoustic PHY in Groovy or Java. However, Groovy and Java are not well suited to writing complex mathematical algorithms. Wouldn't it be nice if we could write the algorithms in Julia instead? In this article, we take the [custom PHY we developed previously](https://github.com/org-arl/unet-contrib/blob/master/contrib/MyPhy/MyPhy.groovy), and replace the signal processing methods with the Julia equivalents. The technique applies not just to PHY agents, and so this article should get you started on leveraging Julia in any UnetStack agents (or for that matter in any Java or Groovy code).

### Java-Julia Bridge

Julia is a wonderful language to implement mathematical and signal processing algorithms. It solves the _two-language problem_ by allowing you to write your algorithm in a nice high-level mathematically intuitive style, while generating performant native code that can be used in real-time systems. In the "[Harnessing the power of Julia in UnetStack — Part I]({% post_url 2020-08-28-harnessing-the-power-of-julia-in-unetstack %})" article, we looked at how to access UnetStack functionality from Julia. In this article, we'll do the reverse -- we'll explore how to use Julia code in UnetStack agents.

In order to access Julia's mathematical prowess from Groovy or Java agents, we need a way to call Julia functions from the JVM. The [Java-Julia Bridge (JaJuB)](https://github.com/org-arl/jajub) project provides exactly this functionality, and we'll leverage it in this article.

### Modulation and demodulation

Recall from my previous article on [developing your own acoustic PHY]({% post_url 2020-10-31-custom-phy %}) that we developed a simple uncoded binary frequency-shift keying (BFSK) implementation in Groovy. While this implementation wasn't difficult to do, Groovy or Java aren't ideally suited for mathematical algorithms. So let's see what the equivalent code would look like in Julia.

The Groovy modulation code we used was encapsulated within a single method `bytes2signal()`:
```groovy
private float[] bytes2signal(byte[] buf) {
  float[] signal = new float[buf.length * 8 * SAMPLES_PER_SYMBOL * 2]   // 8 bits/byte, 2 floats/sample
  int p = 0
  for (int i = 0; i < buf.length; i++) {
    for (int j = 0; j < 8; j++) {
      int bit = (buf[i] >> j) & 0x01
      float f = bit == 1 ? -NFREQ : NFREQ
      for (int k = 0; k < SAMPLES_PER_SYMBOL; k++) {
        signal[p++] = (float)Math.cos(2 * Math.PI * f * k)
        signal[p++] = (float)Math.sin(2 * Math.PI * f * k)
      }
    }
  }
  return signal
}
```

The equivalent Julia code is this:
```julia
function bytes2signal(buf)
  signal = Array{ComplexF32}(undef, length(buf) * 8 * SAMPLES_PER_SYMBOL)
  p = 1
  for b in buf
    for j in 0:7
      bit = (b >> j) & 0x01
      f = bit == 1 ? -NFREQ : NFREQ
      signal[p:p+SAMPLES_PER_SYMBOL-1] .= cis.(2pi * f * (0:SAMPLES_PER_SYMBOL-1))
      p += SAMPLES_PER_SYMBOL
    end
  end
  return signal
end
```

Being able to use complex numbers directly in Julia is such a pleasure! While this code isn't particularly different, as you start implemeting more complex algorithms, you'll appreciate the different a lot more.

The Groovy demodulation code we used was in the method `signal2bytes()` and a helper method `abs2`:
```groovy
private byte[] signal2bytes(float[] signal, int start) {
  int n = (int)(signal.length / (2 * SAMPLES_PER_SYMBOL * 8))       // number of bytes
  def buf = new byte[n]
  int p = start
  for (int i = 0; i < buf.length; i++) {
    for (int j = 0; j < 8; j++) {
      double s0re = 0                 // real path of matched filter for f0
      double s0im = 0                 // imaginary path of matched filter for f0
      double s1re = 0                 // real path of matched filter for f1
      double s1im = 0                 // imaginary path of matched filter for f0
      for (int k = 0; k < SAMPLES_PER_SYMBOL; k++) {
        float re = signal[p++]
        float im = signal[p++]
        float rclk = (float)Math.cos(2 * Math.PI * NFREQ * k)
        float iclk = (float)Math.sin(2 * Math.PI * NFREQ * k)
        s0re += re*rclk + im*iclk
        s0im += im*rclk - re*iclk
        s1re += re*rclk - im*iclk
        s1im += im*rclk + re*iclk
      }
      if (abs2(s1re, s1im) > abs2(s0re, s0im))
        buf[i] = (byte)(buf[i] | (0x01 << j))
    }
  }
  return buf
}

private double abs2(double re, double im) {
  return re*re + im*im
}
```

In Julia, we don't need the helper method, and the complex number calculations become simpler:
```julia
function signal2bytes(signal)
  n = length(signal) ÷ (SAMPLES_PER_SYMBOL * 8)
  buf = zeros(Int8, n)
  p = 1
  for i in 1:length(buf)
    for j in 0:7
      s = @view signal[p:p+SAMPLES_PER_SYMBOL-1]
      p += SAMPLES_PER_SYMBOL
      x = cis.(2pi * NFREQ .* (0:SAMPLES_PER_SYMBOL-1))
      s0 = sum(s .* conj.(x))
      s1 = sum(s .* x)
      if abs(s1) > abs(s0)
        buf[i] = buf[i] | (0x01 << j)
      end
    end
  end
  return buf
end
```

### Using JaJuB from our PHY agent

In order to run the Julia code from our PHY agent, we need to pass it to JaJuB as a string. For a complex piece of code, we might store it in a `.jl` file and load it as a resource from Groovy, but since our code is simple, we'll just insert it in our Groovy source code directly. This also enables us to directly insert constants in our Groovy code (e.g. `SAMPLES_PER_SYMBOL` and `NFREQ`) into the Julia code using Groovy's string interpolation syntax (`${...}`), rather than have to pass them as arguments to the function.

The modulation method now looks like this:
```groovy
private final String julia_bytes2signal = """
  function bytes2signal(buf)
    signal = Array{ComplexF32}(undef, length(buf) * 8 * ${SAMPLES_PER_SYMBOL})
    p = 1
    for b in buf
      for j in 0:7
        bit = (b >> j) & 0x01
        f = bit == 1 ? -${NFREQ} : ${NFREQ}
        signal[p:p+${SAMPLES_PER_SYMBOL-1}] .= cis.(2pi * f * (0:${SAMPLES_PER_SYMBOL-1}))
        p += ${SAMPLES_PER_SYMBOL}
      end
    end
    return signal
  end
"""

private float[] bytes2signal(byte[] buf) {
  def arg = new ByteArray(data: buf, dims: [buf.length] as int[])
  def rv = (FloatArray)julia.call("bytes2signal", arg)
  return rv?.data
}
```

The original `bytes2signal()` method in Groovy is replaced by a `julia.call()` to the Julia implementation of the function `bytes2signal()` defined in `julia_bytes2signal`. To pass the byte array to Julia, we need to wrap the `byte[]` in a `ByteArray` instance provided by JaJuB. The return value from the function is a complex float array, which we get as a `FloatArray` instance. The `data` field of the `FloatArray` object is simply the `float[]` that we return from the Groovy method.

Similarly, we convert the demodulation function to also use the Julia code:
```groovy
private final String julia_signal2bytes = """
  function signal2bytes(signal)
    n = length(signal) ÷ (${SAMPLES_PER_SYMBOL} * 8)
    buf = zeros(Int8, n)
    p = 1
    for i in 1:length(buf)
      for j in 0:7
        s = @view signal[p:p+${SAMPLES_PER_SYMBOL-1}]
        p += ${SAMPLES_PER_SYMBOL}
        x = cis.(2pi * ${NFREQ} .* (0:${SAMPLES_PER_SYMBOL-1}))
        s0 = sum(s .* conj.(x))
        s1 = sum(s .* x)
        if abs(s1) > abs(s0)
          buf[i] = buf[i] | (0x01 << j)
        end
      end
    end
    return buf
  end
"""

private byte[] signal2bytes(float[] signal, int start) {
  def arg = new FloatArray(
    data: signal[start..-1] as float[],
    dims: [(signal.length-start).intdiv(2)] as int[],
    isComplex: true
  )
  def rv = (ByteArray)julia.call('signal2bytes', arg)
  return rv?.data
}
```

Here we pass in a `FloatArray` representing the complex baseband signal to the Julia function, and get back a `ByteArray` with the demodulated data.

Before we can use the `julia.call()` functionality from JaJuB, we need to initialize Julia. We do this by adding an attribute to our class (after importing `org.arl.jajub.*`):
```groovy
private JuliaBridge julia = new JuliaBridge()
```
and loading the two functions at startup (code inserted in our `setup()` method):
```groovy
julia.open()
julia.exec(julia_bytes2signal)
julia.exec(julia_signal2bytes)
```

We also add a `shutdown()` method to our agent to cleanly shutdown Julia when the agent terminates:
```groovy
void shutdown() {
  julia.close()
}
```

Thats it!

The entire modified agent source code can be found in the [unet-contrib repository](https://github.com/org-arl/unet-contrib/blob/master/contrib/MyPhy/MyJuliaPhy.groovy).

### Testing our custom Julia PHY

Now that we've the modified Julia-based `phy2` agent, it is time to try it out on Unet audio. Copy the [`MyJuliaPhy.groovy`](https://github.com/org-arl/unet-contrib/blob/master/contrib/MyPhy/MyJuliaPhy.groovy) file to the `classes` folder in [Unet audio](https://unetstack.net/#downloads). Download [JaJuB jar](https://repo1.maven.org/maven2/com/github/org-arl/jajub/0.1.0/jajub-0.1.0.jar) and put it in the `jars` folder.

If you don't already have Julia installed, [download](https://julialang.org/downloads/) and install it on your computer and ensure it's in your PATH.

Then on the shell:
```bash
> phy.fullduplex = true
true
> container.add 'phy2', new MyJuliaPhy()
phy2
> subscribe phy2
```
We turn on `fullduplex` so that we can transmit and receive on the same device. We subscribe to the `phy2` agent's topic so that we see the `RxFrameNtf` when data is received.

> **TIP**
>
> Writing agents in Groovy in the `classes` folder of UnetStack is often convenient since Groovy can load the class directly from source, without needing explicit compilation. However, if there are errors in the code, Groovy's classloader sometimes gives a cryptic "`BUG! exception in phase 'semantic analysis' in source unit`" error message. If you encounter this, use `groovyc` to get a clearer error report:
>
> `$ groovyc -cp lib/unet-framework-3.2.0.jar:lib/fjage-1.8.0.jar:lib/unet-yoda-3.2.0.jar:jars/jajub-0.1.0.jar classes/MyJuliaPhy.groovy`
>
> and remember to delete off the resultant `MyJuliaPhy.class` file to avoid a stale class file being used later accidentally.

To test the agent, we make a transmission:
```bash
> phy2 << new TxFrameReq(data: [1,2,3])
AGREE
phy2 >> TxFrameNtf:INFORM[txTime:19013099]
phy2 >> RxFrameNtf:INFORM[type:CONTROL from:1 rxTime:19039936 rssi:-49.1 (3 bytes)]
```
You should have been able to hear the transmission on your speaker. After a short delay, you'd see the reception (`RxFrameNtf`). We check the contents to ensure that we got the correct data back:
```bash
> ntf.data
[1, 2, 3]
```
If the frame had any errors, you'd have gotten a `BadFrameNtf`. In that case, you may want to try adjusting your computer's volume setting or transmit power (`plvl` command), and try again.

Now that we can transmit and receive correctly, we can enable the rest of the network stack to use our new Julia PHY:
```bash
> uwlink.phy = 'phy2'
phy2
> mac.phy = 'phy2'
phy2
> ranging.phy = 'phy2'
phy2
```

We can send a text message via UnetStack's remote agent:
```bash
> tell 0, 'hi'
AGREE
phy2 >> RxFrameNtf:INFORM[type:DATA from:1 protocol:3 rxTime:96861353 rssi:-48.7 (3 bytes)]
[1]: hi
```
This resulting datagram goes down the layers of the stack, passed through our new PHY to yield an acoustic signal, gets received by the PHY again to be converted to a datagram, which then goes back up the stack all the way to the remote agent who sends it to the shell for display!

> **TIP**
>
> With Unet audio, Julia calls from Java work seamlessly. However, if you're running on a real modem, chances are that the modem's JVM sandbox won't let you install and run non-JVM code directly. If you have a coprocessor on your modem, you can install Julia on the coprocessor and run the `phy2` agent in a fjåge slave container. Alternatively you can run the `phy2` agent even on your laptop, as long as the laptop is connected over Ethernet to thr modem. To start a slave container, just install Unet audio on the coprocessor/laptop, and start Unet with `bin/unet sh <ipaddr> 1100` where `<ipaddr>` is replaced by the IP address of your modem, and port 1100 is the API port set on the modem.

### Conclusion

Developing complex algorithms in Julia is much easier than in Java or Groovy. By leveraging Julia from UnetStack agents, we bring the power of Julia to UnetStack. The custom Julia-based PHY implementation developed in this article demonstrates how easy it is to combine Groovy and Julia code seamlessly.

I am excited about developing cool new agents in UnetStack using Julia, and I hope you are too!

