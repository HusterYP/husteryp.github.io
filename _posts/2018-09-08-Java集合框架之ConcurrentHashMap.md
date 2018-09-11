---
layout:     post
title:      "Java集合框架之ConcurrentHashMap"
subtitle:   "ConcurrentHashMap源码解析"
date:       2018-09-08
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - Java
---

# 前言

> 1. [前面](https://husteryp.github.io/2018/08/26/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E6%A6%82%E8%BF%B0/)我们对Java集合框架有了一个基本的认识; 本文将主要讲解`ConcurrentHashMap`的实现原理和处理细节

文章源码基于`JDK8`


----

# 正文

-----


sizeCtl, 线程自旋

U.compareAndSwapInt: 双重check

在java7的ConcurrentHashMap实现上，使用了所谓分段锁的方法，而所谓分段锁就是将记录分段存储，不同段的访问互相不影响，某个线程想要访问某一个段的时候就需要对该段上锁，而其他线程不能访问在有其他线程加锁的段

ConcurrentHashMap是基于CAS来实现线程安全的，CAS是一种轻量级的锁，它不会阻塞线程，而是会等待直到获得变量，然后进行业务操作，这和锁需要阻塞线程来实现线程安全来比较，是一种很大的改良，

https://docs.oracle.com/javase/9/docs/api/index.html?overview-summary.html
