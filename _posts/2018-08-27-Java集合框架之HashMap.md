---
layout:     post
title:      "Java集合框架之HashMap"
subtitle:   "HashMap源码解析"
date:       2018-08-27
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - Java
---

# 前言

> [前面](https://husteryp.github.io/2018/08/26/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E6%A6%82%E8%BF%B0/)我们对Java集合框架有了一个基本的认识; 本文将主要讲解`HashMap`的实现原理和处理细节

文章源码基于`JDK8`

----

# 正文

----

## 一. 概述

我们知道`HashMap`存储的是一组键值对, `HashMap`底层实际上就是一个`Node`数组, 将`key`转换为`hash`值, 映射到对应的数组位置, 这样存取都采用相同的规则, 利用数组的快速索引, 实现理想状态下的`O(1)`时间定位; 但是其中也有很多处理细节, 比如一个最常见的就是`Hash`冲突处理, 本文将主要介绍`HashMap`的三大方面, 包括: `Hash`规则, 扩容规则, 解决冲突

----

## 二. Hash规则

`Hash`规则就是如何将一个`key`映射到对应的数组索引位置; 首先来看如何得到一个`key`的`Hash`值; 如下`hash()`函数, 该函数也叫扰动函数, 扰动函数做 的事情是将`key`的`hash`值的高位与低位做异或运算(以`32`位计算, `16`正好是`32`的一半)(这里说明一下`>>>`是无符号右移, 高位补0), 这样做的目的是为了混合高低位的信息, 使得取余计算索引值的时候, 不仅仅只是低位起作用, 减少冲突发生的可能性

```
    static final int hash(Object key) {
        int h;
        return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
    }
```

这里需要联系索引值的计算来理解, 如下, 取存放一个键值对为例, 索引值的计算式子为`(n - 1) & hash`(注意该式实际上等价于`hash % n`, 即为了保证在有效索引范围内, 对`hash`取余, 只是这里为了提高效率, 使用位运算代替了模运算, 关于优化程序性能, 可以[参见博客](https://husteryp.github.io/2018/08/24/Details/)), 这里的`n`是数组的长度, 因为在`HashMap`中, 数组长度始终取的是`2`的整数次幂, 所以这里`n - 1`就相当于是一个掩码(全`1`, 比如默认初始长度`16`, 减一后为`15`, 二进制为`1111`), 高位补`0`, 进行与运算时, 就相当于只取了低位, 本来理想状态下, 如果数组长度足够大的话, 其实不需要扰动函数也可以, 因为数组长度足够大, 相当于`n`值足够大, 那么取的有效位也就足够大, 发生冲突的概率也就相对降低了; 但是实际情况是,
需要在空间利用率, 时间消耗和冲突频率之间取一个折中值, 空间上是不可能达到理想情况的, 那么这时候就需要一个扰动函数, 将高位的影响保留下来, 减少冲突, 因为如果只看低位的话, 冲突发生的频率还是很高的;

当然, 如果这里你还是没有弄清楚的话, 可以参见[HashMap中的hash原理](https://www.zhihu.com/question/20733617)

```
     final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        if ((tab = table) == null || (n = tab.length) == 0)
            n = (tab = resize()).length;
        if ((p = tab[i = (n - 1) & hash]) == null)  // 计算索引, 即 (n - 1) & hash
            tab[i] = newNode(hash, key, value, null);
        ...
     }
```

此外, 这里还想额外补充一点的是关于对象的`hashCode()`方法和`equals()`方法: `Java`中每一种数据类型的`hashCode()`方法都必须和`equals()`方法一致, 也就是说, 如果`a.equals(b)`返回`true`, 那么`a.hashCode()`必然和`b.hashCode()`相等; 相反, 如果两个对象的`hashCode()`不同, 我们就知道该两个对象不同, 但是如果两个对象的`hashCode()`相等, 这两个对象也可能不同, 此时还需要使用`equals()`去判断

------

## 三. 扩容规则

讲扩容规则之前, 需要先看一下最开始的地方, 即`HashMap`的构造函数;  但是在此之前, 我想先介绍一下`HashMap`的几个重要成员变量和概念: 

1. `transient Node<K,V>[] table;`: 这个就是`HashMap`的底层实现数组, 比较好理解

2. `int threshold;`: `threshold`的意思是**阈值**, 标志当`Hash`表内元素数量超过该值时, 会发生扩容(`resize()`)

3. `final float loadFactor;`: 加载因子, 用于计算`threshold`, 即`threshold = table.length * loadFactor`; 合理的加载因子可以在空间和冲突频率上取的较好的折中(提高空间利用率, 同时减少冲突发生,  减少扩容次数), 默认加载因子为`0.75`


接下来看`HashMap`的构造函数, 看其构造规则

`HashMap`有四个构造函数, 如下: 

1. 传入初始容量与加载因子: 但是并不是说指定的初始容量是多少, 构造的`HashMap`容量就是多少; `HashMap`的初始容量是取大于`initialCapacity`的最小`2`的整数次幂的数(比如传入`20`的话, 实际容量就会取`32`); 这里的作用主要在`tableSizeFor()`函数中(如下); 这里之所以要取成`2`的整数次幂, 是为了方便用各种位运算代替算数运算, 提高效率(比如上面的用与运算代替取模运算)

```
    public HashMap(int initialCapacity, float loadFactor) {
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal initial capacity: " +
                                               initialCapacity);
        if (initialCapacity > MAXIMUM_CAPACITY) // 其中MAXIMUM_CAPACITY = 1 << 30;
            initialCapacity = MAXIMUM_CAPACITY; // 初始容量不能超过MAXIMUM_CAPACITY
        if (loadFactor <= 0 || Float.isNaN(loadFactor))
            throw new IllegalArgumentException("Illegal load factor: " +
                                               loadFactor);
        this.loadFactor = loadFactor;
        this.threshold = tableSizeFor(initialCapacity);
    }
```

```
    // 返回大于cap的最小的2的整数次幂的数
    static final int tableSizeFor(int cap) {
        int n = cap - 1;
        n |= n >>> 1;
        n |= n >>> 2;
        n |= n >>> 4;
        n |= n >>> 8;
        n |= n >>> 16;
        return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
    }
```

2. 传入初始容量: 如下; 当只是指定初始容量时, 则使用默认装载因子`0.75`(`static final float DEFAULT_LOAD_FACTOR = 0.75f;`)

```
    public HashMap(int initialCapacity) {
        this(initialCapacity, DEFAULT_LOAD_FACTOR); // DEFAULT_LOAD_FACTOR = 0.75
    }

```

3. 默认构造函数: 都使用默认值, 其中装载因子默认`0.75`, 初始容量默认`DEFAULT_INITIAL_CAPACITY = 1 << 4`(即`16`); 

```
    public HashMap() {
        this.loadFactor = DEFAULT_LOAD_FACTOR; // all other fields defaulted
    }
```

4. 从已有数据构建: 使用默认装载因子; 同时通过传入数据数量进行构建

```
    public HashMap(Map<? extends K, ? extends V> m) {
        this.loadFactor = DEFAULT_LOAD_FACTOR;
        putMapEntries(m, false);
    }
```

上述构造函数中, 使用默认值时, 都是只指定了`loadFactor`的默认值, 没有明确设定初始容量值, 那么该初始容量值又是在哪里指定的呢? 其实, 默认初始容量值是在`resize()`函数中指定的, 接下来马上讲解 !


扩容, 由`resize()`函数作用; `resize()`函数比较长, 具体逻辑可以参见下面代码和注释来理解; 作用主要有两方面: 一个是初始化`table`, 另一个是扩容, 即将`table`大小增大一倍

```
    final Node<K,V>[] resize() {
        Node<K,V>[] oldTab = table;
        int oldCap = (oldTab == null) ? 0 : oldTab.length;
        int oldThr = threshold;
        int newCap, newThr = 0;
        if (oldCap > 0) {
            if (oldCap >= MAXIMUM_CAPACITY) {
                threshold = Integer.MAX_VALUE;
                return oldTab;
            }
            else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY && // newCap = oldCap << 1: 容量增大一倍
                     oldCap >= DEFAULT_INITIAL_CAPACITY)
                newThr = oldThr << 1; // 阈值增大一倍
        }
        else if (oldThr > 0) // 如果构造函数中设置了阈值, 那么就不会走下一步else, 即不会使用默认初始容量进行初始化
            newCap = oldThr;
        else {               // 如果oldCap == 0的话, 就需要进行初始化
            newCap = DEFAULT_INITIAL_CAPACITY; // 使用默认容量进行初始化
            newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY); // 装载因子: threshold = length * loadFactor
        }
        if (newThr == 0) {
            float ft = (float)newCap * loadFactor;
            newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                      (int)ft : Integer.MAX_VALUE);
        }

        // 分配空间, 设置新阈值
        threshold = newThr; 
        @SuppressWarnings({"rawtypes","unchecked"})
            Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
        table = newTab;
        if (oldTab != null) {
            for (int j = 0; j < oldCap; ++j) {
                // 将旧值移动到新的位置
                ...
            }
        }
        return newTab;
    }
```

可以看出, `resize()`的时候进行了空间重新分配和数据的移动, 是一个相对比较耗时的操作, 所以应该合理设置初始容量和加载因子(一般都使用默认加载因子), 来减少扩容次数

上面我们详细了解了一下扩容函数`resize()`的过程, 接下来要解决的是什么时候进行扩容; 其实这个问题, 我们直接看什么时候调用了`resize()`即可; 调用关系主要分为两类, 如下; 可以很明显的看出, 当超出阈值的时候, 需要进行扩容; 当`table`为`null`, 即尚未初始化的时候, 需要进行初始化; 其实这也对应了上面所说的`resize()`函数的两个作用: 容量倍增和初始化

```
    if (s > threshold)
        resize();
```

```
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
```


----------------------

## 四. 解决冲突

冲突的解决是`HashMap`中的一个重难点; 造成冲突的原因就是不同的键值对经过计算后得出相同的数组索引映射;

在之前的版本中, `HashMap`采用**数组+链表**实现, 即使用链表处理冲突, 同一`hash`值的节点都存储在一个链表里, 但是当链表中的元素较多, 即`hash`值相等的元素较多时, 通过`key`值依次查找的效率较低; 而`JDK1.8`中, `HashMap`采用**数组+链表+红黑树**实现, 当链表长度超过转换阈值(默认转换阈值为`TREEIFY_THRESHOLD = 8;`)时, 将链表转换为红黑树, 这样大大减少了查找时间(将`get()`方法的性能从`O(n)`提升到`O(logN)`); 同样,
当`remove()`元素使得红黑树中元素个数小于`UNTREEIFY_THRESHOLD`阈值时(默认为`UNTREEIFY_THRESHOLD = 6`), 将红黑树转换为链表

要看如何解决冲突, 当然是在存放一个值的时候咯! 如下`putVal()`; 逻辑比较简单, 结合注释过一遍即可

```
    final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;

        if ((tab = table) == null || (n = tab.length) == 0) // resize, 上面已经讲了, 不多说
            n = (tab = resize()).length;
        
        if ((p = tab[i = (n - 1) & hash]) == null) // 没有发生冲突时, 直接存放即可
            tab[i] = newNode(hash, key, value, null);
        else { // 发生冲突
            Node<K,V> e; K k;
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p;
            else if (p instanceof TreeNode) // 如果本来就已经使用红黑树进行存储的了
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            else {
                for (int binCount = 0; ; ++binCount) { 
                    if ((e = p.next) == null) {
                        p.next = newNode(hash, key, value, null);
                        if (binCount >= TREEIFY_THRESHOLD - 1) // 超出阈值, 链表转换为红黑树
                            treeifyBin(tab, hash);
                        break;
                    }
                    // 如果键值对已经存在, 不能重复存放
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e;
                }
            }

            // 如果存在重复key, 那么进行value替换
            if (e != null) { // existing mapping for key
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null)
                    e.value = value;
                afterNodeAccess(e);
                return oldValue;
            }
        }
        ...
        return null;
    }
```

接下来主要看两种数据结构的组织方式

### 4.1 链表

链表节点是`Node`, 如下; 也是常规的单链表数据结构, 只是数据域多了一个键值(`key`); 比较简单, 没话说！

```
    static class Node<K,V> implements Map.Entry<K,V> {
        final int hash; // 软缓存
        final K key;
        V value;
        Node<K,V> next;

        Node(int hash, K key, V value, Node<K,V> next) {
            this.hash = hash;
            this.key = key;
            this.value = value;
            this.next = next;
        }
        
        ...
    }
```

这里需要提一个小的知识点：

**软缓存**: 如果`hash`值计算起来很困难, 那么就可以将第一次计算出来的`hash`值缓存起来(`Java`中`String`就是这样的); `HashMap`中的`Node`节点也使用了这种缓存


### 4.2 红黑树

红黑树, 实际上也是一棵二叉查找树, 能够保证增加, 删除, 查找的最坏时间复杂度为`O(logN)`; 红黑树的具体实现细节, 本文不做多讲, 一方面是该知识点也是一个很庞杂的体系, 一时半会也讲不透; 另一方面就是, 对于本文来说, 只需要了解红黑树的特点就可以了; 当然关于红黑树详细的资料, 可以[参考博客](https://blog.csdn.net/v_JULY_v/article/details/6105630)

这里, 我们简单看一下其节点组织方式

```
    static final class TreeNode<K,V> extends LinkedHashMap.Entry<K,V> {
        TreeNode<K,V> parent;  // red-black tree links
        TreeNode<K,V> left; // 指向左节点指针
        TreeNode<K,V> right; // 指向右节点指针
        TreeNode<K,V> prev;    // 用于将红黑树转换为单链表时所用
        boolean red; // 红黑咯 !
        TreeNode(int hash, K key, V val, Node<K,V> next) {
            super(hash, key, val, next);
        }

        ...
    }
```

-------------


## 五. 总结

到这里, `HashMap`相关的三大重难点就分析完了, 记忆的时候, 也可以从这三点出发, 虽然不必记忆具体的代码细节, 但是对于大致流程和设计思想还是要有印象的

当然, 作为集合框架中的一员, `HashMap`还有一些其他特点, 如下:

1. 非同步: `HashMap`不是线程安全的; 多线程中要使用`HashMap`的话, 可以考虑使用`Collections.synchronizedMap(new HashMap(...));`来进行包装

2. `Iterator`遍历抛异常: `ConcurrentModificationException`; 这个和大多数集合一样; 也是在多线程中使用的时候可能出现的问题, 具体原因可以[Java集合框架之List](https://husteryp.github.io/2018/08/27/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BList/)中的分析

3. 支持`null`: `HashMap`支持`key`为`null`, 也支持`value`为`null`

4. 无序: 即遍历`HashMap`得到的数据顺序并不是最初其存放顺序, 因为会伴随这再`Hash`


除此之外, 集合框架中还有一个叫`HashTable`的, 这里简要贴一下他们之间的区别:

1. `HashTable`是线程安全的, 且不允许`key`, `value`是`null`

2. `HashTable`默认容量是`11`

3. `HashTable`是直接使用`key`的`hashCode(key.hashCode())`作为`hash`值, 不像`HashMap`内部使用`static final int hash(Object key)`扰动函数对`key`的`hashCode`进行扰动后作为`hash`值

4. `HashTable`取哈希桶下标是直接用模运算`%` (因为其默认容量也不是`2`的`n`次方, 所以也无法用位运算替代模运算)

5. 扩容时, 新容量是原来的`2`倍`+1`, `int newCapacity = (oldCapacity << 1) + 1;`

6. `Hashtable`是`Dictionary`的子类同时也实现了`Map`接口, `HashMap`是`Map`接口的一个实现类


-----


## 六. 参考链接

[HashMap中的hash原理](https://www.zhihu.com/question/20733617)
