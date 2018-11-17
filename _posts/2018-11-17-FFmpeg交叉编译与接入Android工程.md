---
layout:     post
title:      "FFmpeg交叉编译与接入Android工程"
subtitle:   "记录FFmpeg的交叉编译与将动态库接入Android工程"
date:       2018-11-17
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - Android
---

# 前言

> 本文主要讲解如何在`Linux`上编译`FFmpeg`, 以及将编译出来的动态库(`so`)接入已有的`Android`工程

------------------

# 正文

---------------

## 一. FFmpeg交叉编译

本文选用的`FFmpeg`版本是`FFmpeg 4.0`, `NDK`版本是`Android-ndk-r15c`, 注意在编译`FFmpeg`时, 对`NDK`版本有要求, 另外, 笔者最开始选用最新版本的`NDK`, 总是编译不过, 去查证了一下, 发现从`Androud-ndk-r16`开始, 其用于交叉编译都有问题了, 所以选用较低版本的`Androud-ndk`; 本文选用的`FFmpeg`版本和`NDK`版本亲测可编译通过; 先提供下载地址:

[FFmpeg 4.0](https://ffmpeg.org/releases/ffmpeg-4.0.tar.bz2)

[Android-ndk-r15c](https://dl.google.com/android/repository/android-ndk-r15c-linux-x86_64.zip)

笔者选用的编译环境是`ArchLinux`, `Windows`上的编译的话, 大体流程不变, 环境配置需要自己弄啦~

在开始之前, 需要先了解一下相关知识: 

> 1. JNI和NDK
> 2. CPU架构
> 3. 交叉编译
> 4. FFmpeg简介

这里推荐[官方文档](https://developer.android.google.cn/ndk/guides/), 对以上方面讲解比较详细; 下面简要介绍重点地方


### 1.1 基础知识

#### 1.1.1 JNI和NDK

`JNI`就是`Java Native Interface`, 即`Java`层和`Native`层通信的接口; 通过`JNI`, `Java`可以实现和其他语言之间的互相调用(注意其他语言不仅仅只限于`C/C++`, 虽然大多时候是`C/C++`); `Java`是跨平台的, 但是`C/C++`不是跨平台的, 所以`JNI`也使得`Java`需要考虑和特定平台相关的特性

`NDK`就是`Native Development Kit`, 是`Android`平台提供的一个工具集, 提供与本地代码之间的交互

详细可参见[博客](https://blog.csdn.net/carson_ho/article/details/73250163)

#### 1.1.2 CPU架构


