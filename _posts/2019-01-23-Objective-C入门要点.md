---
layout:     post
title:      "Objective-C入门要点"
subtitle:   "OC问道"
date:       2019-1-23
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - Java
---

# 前言

近日开始入坑iOS，正所谓工欲善其事，必先利其器；iOS的两大基础利器莫过于OC和Swift这两门语言了；笔者先接触的是OC，时至今日也近一月，以此总结，记录OC的一些要点和难点

-----------

# 正文

------------

## 一. 面向对象

> OC是C的一个扩展集，在C的基础上添加了面向对象和消息传递等机制；作为一门面向对象的语言，自然需要探讨面向对象三大特性在OC上的体现

### 1.1 封装

笔者认为，封装更多的是体现在类或者说类的设计上面，有点带设计模式那个层次，如果真要从语法层面去讲解的话，更契合的还是类，方法，成员变量的访问修饰符

OC中类没有访问修饰符，OC中也没有package的概念

OC中方法也没有权限修饰符一说，在头文件中声明的方法都相当于是public的，如果要定义私有方法，则只需在.m文件中实现，但不需要在.h文件声明

成员变量权限访问修饰方法主要有如下三种；除了以下三种外，还有一个是@package，它修饰属性的时候，只能在当前框架中才能呗访问，用的比较少

| -- | -- | -- | -- |
| 修饰符 | 类内部 | 子类 | 任何地方 |
| -- | -- | -- | -- |
| private | YES | NO | NO |
| protected（默认）| YES | YES | NO |
| public | YES | YES | YES |

### 1.2 继承

OC只支持单继承，如果要实现多继承，可以采用如下三种方式：

#### 1.2.1 通过组合实现

组合实际上就是说如果一个类无法实现某个功能，那么就将该需求转接到另一个类实现，比较简单，就是将能实现该功能的类作为自己的一个成员变量

#### 1.2.2 通过协议实现

协议类似于Java中的接口，但是也有所不同，参见下面对协议的讲解；OC中只能继承一个类，但是可以实现多个协议

#### 1.2.3 通过Category实现

Category可以实现在不继承类的基础上实现对类的扩展；这里使用Category实现多继承举例如下：Child已经继承了Father，想要再对Child扩展方法，可以使用Category扩展

```
// 文件：Child.h
@interface Child : Father

- (void)showChild;

@end

// 文件：Child+Hello.h
@interface Child(Hello)

- (void)hello;

@end

// 文件：Child+Hello.m
@implementation Child(Hello)

- (void)hello {
    
}

@end

```

### 1.3 多态

Java中多态的实现依赖于重写，重载和向上转型（动态链接）；但是OC中方法不能重载，可以重写，其余的和普通Java多态的概念和用法基本相同；另外，Java中多态还有一个重要的点就是接口，依赖于接口达到的运行时动态绑定，与之对应的，在OC中可以使用协议实现

这里还需要注意的是，重新认识OC中的方法签名，OC的语法比较冗余，举例如下：

```
// 函数原型如下，方法签名为：addNumber1:andNumber2:
- (NSInteger)addNumber1:(NSInteger)number1 andNumber2:(NSInteger)number2;

// 函数原型如下，方法签名为：add::
- (NSInteger)add:(NSInteger)number1 :(NSInteger)number2;
```


--------------

## 二. 协议

OC中的协议相当于Java中的接口，很多设计模式都依赖于协议；但是OC中的协议于Java中的接口也有一些细微的差别；

一般而言，协议应该与对应的类声明在同一个头文件中，与Java中接口不同的是，协议的中的方法不是必须都实现的，可以使用`@optional`和`@required`来声明方法，但是使用@required修饰的协议方法也不是必须实现的，如果没有实现，编译会报警告；但是如果调用了一个没有实现的协议方法的话，运行时会崩溃

协议中不能有默认方法实现，这点与Java中的接口相同，但是OC的协议中不能定义变量；协议可以被class，struct，enum实现

协议的使用场景：
> 1. 需要由别的类实现的方法
> 2. 声明未知类的接口
> 3. 两个类之间的通信


---------------


## 三. define：宏定义

OC中的宏定义是非常强大的，合理使用可以极大的简化和优雅代码

### 3.1 define，const，enum定义常量

define宏：只是在预处理器里进行文本替换，没有类型，不做任何类型检查，编译器可以对相同的字符串进行优化。只保存一份到 .rodata 段。甚至有相同后缀的字符串也可以优化，你可以用GCC 编译测试，"Hello world" 与 "world" 两个字符串，只存储前面一个。取的时候只需要给前面和中间的地址，如果是整形、浮点型会有多份拷贝，但这些数写在指令中。占的只是代码段而已，大量用宏会导致二进制文件变大

const常量：共享一块内存空间，就算项目中N处用到，也不会分配N块内存空间，可以根据const修饰的位置设定能否修改，在编译阶段会执行类型检查

enum枚举：只能定义int类型

推荐使用const常量

部分摘自[博客](https://www.jianshu.com/p/f83335e036b5)

### 3.2 宏定义

使用宏定义可以将一些冗杂的语句简化，使得调用简明；常用宏可以参见[博客](https://my.oschina.net/leejan97/blog/354904)


---------------

## 四. @property修饰符

本来@property是和@synthesize共用来实现自动生成set和get方法的，但是Xcode4.4之后，@property得到了增强，只使用@property即可生成set和get方法，同时还会自动生成一个带下划线的同名私有变量（需要注意的是，当我们自己写了对应的set和get方法时，该带下划线的同名变量将不可用，解决办法参见[博客](https://www.jianshu.com/p/baef6d5a41d3)）

但是@property的使用难点在于理解其修饰符，关于@property修饰符的使用涉及到内存管理，也是比较复杂的一部分，这里暂时搁置，找机会和内存管理一起讲解


--------------

## 五. Xcode与模拟器快捷键

说实话，刚从Android Studio转到Xcode实际上是很不习惯的，很明显的一个就是IDE写代码不顺手，AS各种快捷键与插件写起代码来简直上天～

但既已入坑，还是自己去适应呗

Xcode常用快捷键：

```
cmd + shift + o      快速打开文件
cmd + 1              切换成 Project Navigator (cmd + 2~7 也可以做相应切换，不过不常用）
cmd + ctrl + 上     在 .h 和 .m 文件之间切换
cmd + enter          切换成 standard editor
cmd + opt + enter    切换成 assistant editor
cmd + shift + y      切换 Console View 的显示或隐藏
cmd + 0              隐藏左边的导航 (Navigator) 区
cmd + opt + 0        隐藏右边的工具 (Utility) 区
ctrl  + 6            列出当前文件中所有的方法，可以输入关键词来过滤。这个相当赞，可以快速定位到想编辑的方法。
                     我直接把这个快键盘改成了 ctrl+o，这样按起来更顺手。
cmd + ctrl + 左 / 右   到上 / 下一次编辑的位置，在 2 个编辑位置跳转的时候很方便。
cmd + opt + j        跳转到文件过滤区
cmd + shift + f      在工程中查找
cmd + r              运行，如果选上直接 kill 掉上次进程的话，每次直接一按就可以重新运行了
cmd + b              编译工程
cmd + shift + k      清空编译好的文件
cmd + .              结束本次调试
ESC                  调出代码补全
cmd + 单击           查看该方法的实现
opt + 单击           查看该方法的文档
cmd + t              新建一个 tab 栏
cmd + shift + [      在 tab 栏之间切换
``` 

模拟器常用快捷键：

```
SHIFT+CMD+H	回到桌面
CMD+Q		退出模拟器
CMD+S		模拟器截屏(所截图片都在桌面上)
```

----------

## 六. 内存管理

内存管理是一个比较难的点，东西也很多，并非三言两语就能阐述清楚，后面有机会再另起新篇

-------------分割线------------------

**Draft：暂存**
@property修饰符，常见的几组如下：
> 1. atomic, nonatomic：是否线程安全；默认为atomic，线程安全，但是会影响性能，一般使用nonatomic
> 2. retain, copy, assign：默认为assign，该修饰符对属性只是简单的赋值，不更改引用计数，常用于基本数据类型，如：int，short等；retain一般用于修饰指针，会持有对象，增加引用计数
> 3. readonly, readwrite
> 4. strong, getter=method, setter=method, unsafe_unretained

weak和assign的区别：weak和assign的区别主要是体现在两者修饰OC对象时的差异。上面也介绍过，assign通常用来修饰基本数据类型，如int、float、BOOL等，weak用来修饰OC对象，如UIButton、UIView等；weak不能修饰基本数据类型

相关博客推荐：
> 1. https://hk.saowen.com/a/1bdf81decab39874080a44833b2fc47eb8a59355e9ae2b997565552d63991f4d
> 2. https://hk.saowen.com/a/7b29e511436f99243478a22570615137266de714cbcda782e798ab04a4611d5e  及其后文链接
> 3. https://hk.saowen.com/a/e7b69dbe7dfea4e5a00ebd4ef4a73a61403c8351d319eb901a05388d38513dbf  及其后文链接
> 4. https://stackoverflow.com/questions/2255861/property-retain-assign-copy-nonatomic-in-objective-c
