---
title: "Projects"
author: Nathanael Aff
slug: projects
categories: ["Miscellaneous" ]
draft: false
---

<h4> Master's Thesis </h4>

*Aff, Nathanael* (2017). _Improvement of epsilon-complexity estimation and an application to seizure prediction_, San Francisco State University.

 [PDF](https://github.com/nateaff/eeg-complex/blob/master/docs/thesis/thesis.pdf)
|  [Website](https://nateaff.github.io/eeg-complex/complexity-coefficients.html)

Epsilon-complexity is time series or function feature which is meant to measure the intrinsic complexity of the time series. 

For this thesis I implemented the $\varepsilon$-complexity estimation procedure in an `R` package. The classification performance of the $\varepsilon$-complexity coefficients was tested on a number of simulated time series. I also tested the properties of the complexity coefficients and found that, for the class of function tested, the feature behaves like a variogram estimator of fractal dimension. The complexity features was applied to the prediction of mouse seizures.  

<h4> Ecomplex </h4>

An R package for computing the epsilon-complexity of a time series. 

[Code](https://github.com/nateaff/ecomplex)


<h4> Scale-Space Theory Applied to Text Analysis </h4>

A prototype Python implementation of SH Yang's [Scale-Space Theory for Text](https://arxiv.org/abs/1212.2145). Instead of a bag-of-words treatement of text where the time element is ignored, this method adopts techniques used in computer vision and treats text as existing in a two-dimensional meaning and time space. I implemented an algorithm for smoothing over word frequencies both in time and over a semantic graph. The method was demonstrated on simple keyword finding task.

[Code](https://github.com/nateaff/scale-space-text)


<h4> Cards of the Wild Multiplayer Game </h4>

A Hearthstone-style battle card game created with the Unity game engine and based on the World of Balance's Serengeti ecosystem. Features online multiplayer through the World of Balance Lobby.

I lead a small team and wrote server logic and protocols in Java and C#.

[Website](http://smurf.sfsu.edu/~wob/?lipi=urn%3Ali%3Apage%3Ad_flagship3_profile_view_base%3BSzFZhqLuSpWT6sVqoL%2Fzog%3D%3D)  |  [Code](https://github.com/nateaff/cards_of_the_wild)


