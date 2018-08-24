---
layout:     post
title:      "AndroidStudio代理设置"
subtitle:   "Android Studio踩坑"
date:       2018-8-20 
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - AndroidStudio
---

# 前言
> 近日, Android Studio新建项目一直Gradle失败, 网上各种搜, 说是设置代理, 然而代理设置之后不能使用, 搞了一天, 差点就滚去重装AS了, 不过终于还是搞清楚问题出在哪里了, 以此记录

# 正文

## 一. 问题描述
* 新建项目失败
* 完好的项目第二次打开之后, Gradle失败
* 使用Help->Check for Updates 提示联网失败
* SDK 无法联网下载

![联网失败](/img/post/AndroidStudio/timeout.png)

## 二. 解决
* 根本原因还是ShadowSocks的代理设置有问题, 之前使用的是Socks5代理, 改为Http代理就好了, 如下
* 在网上查了一下, Socks5是局部代理, Android Studio 本身支持 socks5 代理，但是 gradle 只支持 http 代理，这也导致了虽然开着 shadowsocks 却无法更新 SDK 或者下载 gradle 依赖; 

![Socks5代理](/img/post/AndroidStudio/socks.png)

改为

![Http代理](/img/post/AndroidStudio/http.png)
