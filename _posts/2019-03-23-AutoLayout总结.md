---
layout:     post
title:      "AutoLayout总结"
subtitle:   "iOS布局基础"
date:       2019-03-23
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - iOS
---

# 前言

`AutoLayout`总结

--------------

# 正文

--------------

## 一. 布局方式与背景

在开始介绍`AutoLayout`之前，需要先介绍一下`iOS`中的布局方式；iOS`中主流的界面布局方式主要有手写代码布局，`xib`布局，`storyboard`布局；笔者更喜欢的还是手写代码的方式，一个可能与笔者之前`Android`经验相关（因为`Android`中多是使用手写`xml`的方式布局，另一个是，对于多人合作而言，手写代码其实更方便（减少冲突）；当然，对于单人的独立项目，其实没有什么优劣可言，选择一种自己更为熟悉与快捷的方式都是因人而异。

关于`xib`布局和`storyboard`布局方式的区别，其实二者都是使用`IB`来进行可视化空间的拖拽与约束，唯一的区别是二者的侧重点不同；一般来说，单个的`xib`文件对应一个`ViewController`，对于一些自定义`View`，通常也会使用单个`xib`并从`main bundle`进行加载的方式来载入；而`storyboard`只能使用`ViewController`而不能用于单独的`UIView`（`UIView`只能基于`ViewController`使用，而`xib`同时支持两者）

`xib`实际上是一个`xml`文件，通过编译之后就得到`nib`文件

在上面介绍的三种方式中，都可以使用`AutoLayout`的方式来进行布局；`AutoLayout`的出现，是为了解决不同尺寸屏幕的适配问题；`iPhone 5`之前，屏幕都是`3.5`寸的（`640 x 960`分辨率），这之前，屏幕尺寸相同，不存在适配问题，所有`View`坐标只需要计算好即可，但是`2012`年，苹果发布了`4.0`寸（`640 x 1136`分辨率）的`iPhone 5`，这样在`iOS`平台上就出现了不同尺寸的移动设备，使得原有的`frame`布局方式无法进行很好的屏幕适配，所以为了解决这一问题，就出现了`AutoLayout`


-----------

## 二. 原理与使用

`AutoLayout`其实类似于`Android`中的`RelativeLayout`，采用`View`之间的相对位置来进行布局；我们知道，要确定一个`View`的位置，需要知道`View`的`x，y，width，height`，即`View`的起始坐标点，宽度和高度信息；`AutoLayout`其实是通过解`View`之间建立的线性方程组（`y = ax + b`）来确定其信息的（如下图），当然，如果出现约束不完整的情况或者约束冲突的情况，就会出现解的不定性，表现出来即是`View`位置未达到预期

![](/img/post/AutoLayout/AutoLayout_1.png)

可约束的属性参见[NSLayoutAttribute](https://developer.apple.com/documentation/uikit/nslayoutattribute)枚举


`AutoLayout`实际上是基于`Cassowary`算法的，`Cassowary`是`Alan Borning, Kim Marriott, Peter Stuckey`等人在`1997`年提出的一个解决布局问题的算法，`Cassowary`算法能够有效解决线性等式系统和线性不等式系统，这也是`AutoLayout`的性能保障

当使用`AutoLayout`的时候，`View`的默认初始值会被弃用，如下代码，此时`UILable`的初始化宽高会失效；这里还需要注意一个`translatesAutoresizingMaskIntoConstraints`属性，从名字我们可以看出，该属性是控制是否把`AutoresizingMask`变成约束（`autoresizing mask`其实就是完全指定视图的尺寸和位置，即是否需要将其转换为线性方程组）；当使用`IB（Interface Builder）`布局的时候，即`xib，storyboard`方式，如果勾选了`Use Autolayout`选项（默认勾选），那么`IB`生成的控件的`translatesAutoresizingMaskIntoConstraints`属性都会被默认设置`false`；当使用手写代码布局时，`View`的`translatesAutoresizingMaskIntoConstraints`属性默认为`true`，但是`View`的`AutoresizingMask`属性默认被设置为`.None`，也就是说如果我们不去动`View`的`AutoresizingMask`属性，那么`AutoresizingMask`就不会对约束产生影响，所以，这个属性，一般也不需要手动设置（当然，为了保险，也可以手动将`translatesAutoresizingMaskIntoConstraints`属性置为`false`）

当`translatesAutoresizingMaskIntoConstraints`属性为`true`时，`View`的`AutoresizingMask`将会转换为约束，一起参与到`AutoLayout`的约束计算中，即会对`AutoLayout`产生影响

```
let label = UILabel(frame: CGRect(x: 100, y: 100, width: 100, height: 200))
label.backgroundColor = #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)
view.addSubview(label)
label.translatesAutoresizingMaskIntoConstraints = false
label.snp.makeConstraints { (make) in
            make.width.equalTo(10)
            make.leading.equalToSuperview().offset(40)
            make.top.equalToSuperview().offset(40)
}
```

布局关系不仅限于等于，还可以是大于等于或者小于等于，这种不等关系在处理`UILabel`，`UIImageView`等具有自身内容尺寸（`Intrinsic Content Size`）的控件时非常有用；比如：`UILabel`的长度会随文字长度而变化，那么我们可以对`UILabel`控件添加两个约束，即`宽度大于等于50`与`宽度小于等于200`，这样，当文字很少时，宽度也至少为`50`，当文字很多时，宽度也不会超过`200`

某些用来展现内容的用户控件，例如`UILabel`、`UIButton`、`UIImageView`等，它们具有自身内容尺寸（`Intrinsic Content Size`），此类用户控件会根据自身内容尺寸添加布局约束；也就是说，如果开发者没有显式给出其宽度或者高度约束，则其自身内容约束将会起作用

具有`Intrinsic Content Size`的`View`参见下图（摘自官网）；具有`Intrinsic Content Size`属性的`View`都重写了`UIView`的`-(CGSize)intrinsicContentSize:`方法，并且在需要改变这个值的时候调用`invalidateIntrinsicContentSize`方法即可，通知系统这个值改变了；同样，当我们自定义`View`的时候，如果想要拥有`Intrinsic Content Size`属性，就可以重写该方法

![](/img/post/AutoLayout/AutoLayout_2.png)

`AutoLayout`中还有两个比较重要的概念，`Content Hugging`与`Content Compression Resistance`约束；在讲解这两个属性之前，需要先了解一下`AutoLayout`中的优先级属性；所谓的优先级，我个人的理解其实是一种减少冲突与弱化约束的作用，即为各约束设置优先级，当出现冲突时`AutoLayout`优先满足高优先级的约束；关于优先级的使用，可以参见文末参考链接

`Content Hugging`约束：不想变大约束；即如果组件的此属性优先级比另一个组件此属性优先级高的话，那么这个组件就保持不变，另一个可以在需要拉伸的时候拉伸；可以简单理解为`Content Hugging`越大，`View`越难变大；默认值为`250`

`Content Compression Resistance`约束：不想变小约束；如果组件的此属性优先级比另一个组件此属性优先级高的话，那么这个组件就保持不变，另一个可以在需要压缩的时候压缩；可以简单理解为`Content Compression Resistance`越大，`View`越难变小；默认值为`750`

关于`Content Hugging`与`Content Compression Resistance`的应用，可以参见[博客](https://www.jianshu.com/p/f6bc007b30e5)


------------

## 三. 性能分析

1. https://time.geekbang.org/column/article/85332

2. https://www.jianshu.com/p/0b964dc17c04

3. https://xiaozhuanlan.com/topic/5378941206

4. https://draveness.me/layout-performance

5. https://juejin.im/post/5bd5a546f265da0af033cee6#heading-3


----------------


## 四. 参考

1. https://www.jianshu.com/p/f6bc007b30e5
2. https://blog.csdn.net/hard_man/article/details/50888377

