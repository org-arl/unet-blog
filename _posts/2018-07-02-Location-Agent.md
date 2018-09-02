---
layout: post
title: Location Agent
date: 07/2/2018
author: Manu Ignatius
categories: unet
feature-img: "assets/img/search-map.jpg"
thumbnail: "assets/img/search-map.jpg"
tags: [unet, nagivation, gps]
---

UnetStack runs on several modems, simulators, and even laptops with sound cards. But what if we have a modem that UnetStack doesn't already run on? And we want it to! Well ... we need to write a driver for that modem. It really isn't that difficult, and this blog will walk you through the basics.

Jekyll supports the use of [Markdown](http://daringfireball.net/projects/markdown/syntax) with inline HTML tags which makes it easier to quickly write posts with Jekyll, without having to worry too much about text formatting. A sample of the formatting follows.

Tables have also been extended from Markdown:

First Header  | Second Header
------------- | -------------
Content Cell  | Content Cell
Content Cell  | Content Cell

Here's an example of an image, which is included using Markdown:

![Image of a glass on a book]({{ site.baseurl }}/assets/img/clear-underwater-water.jpg)

Highlighting for code in Jekyll is done using Base16 or Rouge. This theme makes use of Rouge by default.

{% highlight js %}
// count to ten
for (var i = 1; i <= 10; i++) {
    console.log(i);
}

// count to twenty
var j = 0;
while (j < 20) {
    j++;
    console.log(j);
}
{% endhighlight %}

Type on Strap uses KaTeX to display maths. Equations such as $$S_n = a \times \frac{1-r^n}{1-r}$$ can be displayed inline.

Alternatively, they can be shown on a new line:

$$ f(x) = \int \frac{2x^2+4x+6}{x-2} $$
