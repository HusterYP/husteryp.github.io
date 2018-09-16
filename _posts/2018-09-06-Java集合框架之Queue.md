---
layout:     post
title:      "Java集合框架之Queue"
subtitle:   "Queue的实现类"
date:       2018-09-06
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - Java
---

# 前言

> [前面](https://husteryp.github.io/2018/08/26/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E6%A6%82%E8%BF%B0/)我们对Java集合框架有了一个基本的认识, 这里我们从几大接口入手, 逐步讲解其实现类; 下面要讲解的是`Queue`的实现类, 即`ArrayDeque`

文章源码基于`JDK8`



**`Java`集合框架系列博客**: 

1. [Java集合框架概述](https://husteryp.github.io/2018/08/26/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E6%A6%82%E8%BF%B0/)

2. [Java集合框架之List](https://husteryp.github.io/2018/08/27/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BList/)

3. [Java集合框架之HashMap](https://husteryp.github.io/2018/08/27/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BHashMap/)

4. [Java集合框架之Set](https://husteryp.github.io/2018/08/27/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BSet/)

5. [Java集合框架之LinkedHashMap](https://husteryp.github.io/2018/08/28/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BLinkedHashMap/)

6. [Java集合框架之Queue](https://husteryp.github.io/2018/09/06/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BQueue/)


----

# 正文

-----

## 一. 概述

`ArrayDeque`是一个双端队列, 内部使用数组实现, 既可以作为栈使用, 也可以作为队列使用(当作为栈使用时, 比`Stack`快; 当作为队列使用时, 比`LinkedList`快); 既然是双端队列, 那么自然支持首尾插入删除等操作; `ArrayDeque`不是线程安全的, 不允许插入`null`

`ArrayDeque`内部使用`Object[] elements`来容纳元素, 默认初始容量为`16`, 需要注意的是, `ArrayDeque`的容量大小需要为`2`的整数幂次方, 这是为了使用位运算去代替普通的乘除运算来提高效率; 下面将从两个方面讲解其有关知识点: 即基本方法和扩容规则


-----

## 二. 基本方法

### 2.1 构造函数

`ArrayDeque`提供了三个构造函数, 这里只挑其中一个比较难的讲解; 如下, 该构造函数允许提供自定义初始容量, 但是并不是说, 我们传进去多少容量, 最初就会分配多少容量, 因为传进去的值还经过了`calculateSize()`函数的处理; `calculateSize()`函数的作用是, 找出不小于`numElements`的最小的`2`的整数次幂的整数, 因为上面已经说了, `ArrayDeque`的容量需要都是`2`的整数次幂; 这点和`HashMap`的扩容规则比较相像, 具体分析可以参见[Java集合框架之HashMap](https://husteryp.github.io/2018/08/27/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BHashMap/)中对`HashMap`扩容规则一节的讲解; 另外, 值得一提的是, `calculateSize()`的时候还进行了边界值的判断, 一个是初始容量最小为`8`, 最大不得超过`2^30`, 如下代码;

```
    private void allocateElements(int numElements) {
        elements = new Object[calculateSize(numElements)];
    }
```

```
    private static int calculateSize(int numElements) {
        int initialCapacity = MIN_INITIAL_CAPACITY;  // 初始最小容量为8
        // Find the best power of two to hold elements.
        // Tests "<=" because arrays aren't kept full.
        if (numElements >= initialCapacity) {
            initialCapacity = numElements;
            initialCapacity |= (initialCapacity >>>  1);
            initialCapacity |= (initialCapacity >>>  2);
            initialCapacity |= (initialCapacity >>>  4);
            initialCapacity |= (initialCapacity >>>  8);
            initialCapacity |= (initialCapacity >>> 16);
            initialCapacity++;

            if (initialCapacity < 0)   // Too many elements, must back off
                initialCapacity >>>= 1;// Good luck allocating 2 ^ 30 elements // 最大容量为2^30
        }
        return initialCapacity;
    }
```

### 2.2 元素增删

双端队列的难点在于数据元素增删的时候, 如何通过首尾指针的关系判断当前队列是满还是空, 以及插入和删除元素后首尾指针的变化情况; 在`ArrayDeque`中的处理是, `head`指针指向队列首元素, `tail`指针指向队列尾元素的后一个位置, 那么比如在队列头部插入元素时,  通过判断`(head - 1) & (elements.length - 1) == tail`为`true`的时候队列就满了, 这样, 虽然双端队列在队列满和空的情况下, 都是`head == tail`, 但是仍然能够分辨

下面我们通过具体的元素添加来看, 如下, 为在队列头添加元素, 这里需要注意的一点是先添加元素, 再判断队列是否已满, 这是因为上面我们说了, `ArrayDeque`中`tail`指针指向的是队尾元素的下一个位置, 一定是空位置, 否则在上一次添加元素的时候就会引起扩容了

```
    public void addFirst(E e) {
        if (e == null)
            throw new NullPointerException();
        elements[head = (head - 1) & (elements.length - 1)] = e;
        if (head == tail)
            doubleCapacity();
    }
```

这里讲一下`head = (head - 1) & (elements.length - 1)`的运算规则, 比如, 当我们的数组容量为`8`, 本次插入之前`head = 0`, `tail = 7`的时候, 执行该插入操作, 通过`head = (head - 1) & (elements.length - 1)`元素, 即 `-1 & 7`, 转换为二进制就是(`1111 & 0111 = 0111`), 最终运算结果为`7`, 所以可以判断队列满了, 需要扩容 ~

其实这里使用位运算也是利用了数组容量为`2`的整数次幂的特点

同理, 在队列尾插入元素也是一样的, 如下; 就不再分析啦~

```
    public void addLast(E e) {
        if (e == null)
            throw new NullPointerException();
        elements[tail] = e;
        if ( (tail = (tail + 1) & (elements.length - 1)) == head)
            doubleCapacity();
    }
```

对于删除元素来说, 这里举一个例子, 如下; 主要看`head`指针的变化规则, 即`head = (h + 1) & (elements.length - 1);`, 其实就是和插入元素相反的过程而已

```
    public E pollFirst() {
        int h = head;
        E result = (E) elements[h];
        // Element is null if deque empty
        if (result == null)
            return null;
        elements[h] = null;     
        head = (h + 1) & (elements.length - 1);
        return result;
    }
```


-----

## 三. 扩容规则

什么时候会扩容呢, 我们注意到, 上面我们讲解插入元素指针变化规则的时候, 当`head == tail`也就是队列满了的时候, 会调用一个`doubleCapacity()`
函数, 其实该函数就是用于扩容的 

那么根据上面的分析, 什么时候会发生扩容呢, 其实就是当队列满的时候; 扩容的规则又是怎样的呢, 从`doubleCapacity()`的函数名我们猜测, 就是将数组容量加倍而已; 如下, 思路也比较简单, 就是创建一个扩容的新数组进行旧元素的复制罢了, 比较简单, 不再赘述

```
    private void doubleCapacity() {
        assert head == tail;
        int p = head;
        int n = elements.length;
        int r = n - p; // number of elements to the right of p
        int newCapacity = n << 1; // 左移一位, 相当于容量加倍
        if (newCapacity < 0)
            throw new IllegalStateException("Sorry, deque too big"); // 这是因为左移溢出之后会变成负值, 说明队列太大啦~
        Object[] a = new Object[newCapacity];
        System.arraycopy(elements, p, a, 0, r);
        System.arraycopy(elements, 0, a, r, p);
        elements = a;
        head = 0;
        tail = n;
    }
```


## 四. 总结

到这里, `ArrayDeque`的源码就分析完啦~; 最后笔者还想补充解释一点的是, 最开始我们提过, 当`ArrayDeque`作为栈来使用的时候, 比`Stack`要快, 关于`Stack`, 我们在[Java集合框架概述](https://husteryp.github.io/2018/08/26/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E6%A6%82%E8%BF%B0/)中粗略的提过, `Stack`是`Java 2`以前的几个遗留`API`, 其内部也是使用数组实现的, 但是由于其加了锁, 支持多线程访问, 所以会比`ArrayDeque`要慢; 当`ArrayDeque`作为队列使用的时候,
比`LinkedList`要快是因为在`LinkedList`内部是使用链表节点实现的, 不具备数组的索引定位, 当然也就是慢啦~

