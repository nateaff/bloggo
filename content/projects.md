---
title: "Projects"
author: Nathanael Aff
slug: projects
categories: ["Miscellaneous" ]
draft: false
date: 2017-06-01
---

<h4> Master's Thesis </h4>

[PDF](https://github.com/nateaff/eeg-complex/blob/master/docs/thesis/thesis.pdf)
|  [Website](https://nateaff.github.io/eeg-complex/index.html)

<p style="font-size:90%;">
<i>Improvement of epsilon-complexity estimation and an application to seizure prediction</i>, San Francisco State University. 2017.</p>

<p style="font-size:90%;">
Epsilon-complexity as defined by <a href="https://arxiv.org/abs/1303.1777">Darkhovsky and Piryatinska</a> is a time series feature designed to measure the intrinsic complexity of the time series. 
</p>
<p style="font-size:90%;">
For this thesis, I implemented the epsilon-complexity estimation procedure in an `R` package. Some family of approximations is used in the estimation procedure. Several approximation methods were implemented and the classification performance of the epsilon-complexity coefficients was tested on simulated time series. Although the complexity coefficients had been successfully used as features in classification tasks their relation to other time series features was not understood. I tested the coefficients behavior on several simulations and found that, for the class of functions tested, the slope coefficient behaves like the variogram estimator of fractal dimension. The complexity coefficients were also used to predict seizures in epileptic mice. Change points in the complexity coefficients were used to segment the EEG features and a random forest was used to predict the seizure outcomes. 
</p>

<h4> Ecomplex </h4>

<p> 
<img src="https://api.travis-ci.org/nateaff/ecomplex.svg?branch=master" align="left">     
<br>
<a href="https://github.com/nateaff/ecomplex"> Code</a>
</p>



<p style="font-size:90%;">
An R package for computing the epsilon-complexity of a time series. The package also includes a nonparametric change-point detection algorithm.
</p>


<h4> Scale-Space Theory Applied to Text Analysis </h4>

[Code](https://github.com/nateaff/scale-space-text)

<p style="font-size:90%;">
A prototype Python implementation of SH Yang's <a href= "https://arxiv.org/abs/1212.2145"> Scale-Space Theory for Text</a>. Instead of a bag-of-words treatment of text where the time element is ignored, this method adapts techniques used in computer vision and treats text as existing in a 2-dimensional space semantic-time space. I implemented an algorithm for smoothing over word frequencies both in time and over a semantic graph. The method was demonstrated on simple keyword finding task.
</p>


<h4> Cards of the Wild Multiplayer Game </h4>

[Website](http://smurf.sfsu.edu/~wob/?lipi=urn:li:page:d_flagship3_profile_view_base%3BSzFZhqLuSpWT6sVqoL%2Fzog%3D%3D)  |  [Code](https://github.com/nateaff/cards_of_the_wild)

<p style="font-size:90%;">
A Hearthstone-style battle card game created with the Unity game engine and based on the World of Balance's Serengeti ecosystem. The multiplayer game is accessible through the World of Balance Lobby.

I lead a small team and wrote server logic and protocols in Java and C#.
</p>



