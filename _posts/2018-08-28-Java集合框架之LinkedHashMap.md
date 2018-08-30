---
layout:     post
title:      "Java集合框架之LinkedHashMap"
subtitle:   "LinkedHashMap源码讲解"
date:       2018-08-28
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - Java
---

# 前言

> 1. [前面](https://husteryp.github.io/2018/08/26/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E6%A6%82%E8%BF%B0/)我们对Java集合框架有了一个基本的认识; 本文将主要讲解`LinkedHashMap`的实现原理和处理细节
> 2. `LinkedHashMap`继承于`HashMap`, 所以需要先对`HashMap`有一个基本的认识, 可以参见[Java集合框架之HashMap](https://husteryp.github.io/2018/08/27/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BHashMap/)

文章源码基于`JDK8`


----

# 正文

-----

## 一. 概述

`LinkedHashMap`继承于`HashMap`, 除了`HashMap`元素遍历无序, `LinkedHashMap`元素遍历有序以外, 具有`HashMap`的大多数特点; 另外, `LinkedHashMap`内部还有一个双向链表, 用于记录元素顺序(这也是保证其遍历有序的原因), 具体有两种顺序,  一个是插入顺序, 一个访问顺序; 同时, `LinkedHashMap`还可以用来实现`LRU`算法(`Least Recently Used`, 即最近最少使用算法); 本文将主要分析`LinkedHashMap`的两个大方面: 一个是遍历有序, 另一个是用于`LRU`算法的特性


-----

## 二. 遍历有序

`LinkedHashMap`遍历有序, 主要是因为其在`HashMap`的基础上, 增加了一个双向链表, 按照元素的插入顺序或者访问顺序, 将数据重新组织成一个双向链表; 根据标志位`final boolean accessOrder;`来决定是按照插入顺序(`insertion-order`, 此时需要`accessOrder = false`)还是访问顺序(`access-order`, 此时需要`accessOrder = true`)来组织

`LinkedHashMap`改写了`HashMap`的节点, 如下; 在其中增加了`before`和`after`域用于帮助组织双向链表

```
    static class Entry<K,V> extends HashMap.Node<K,V> {
        Entry<K,V> before, after;
        Entry(int hash, K key, V value, Node<K,V> next) {
            super(hash, key, value, next);
        }
    }
```

对于`accessOrder`值的指定只能在创建`LinkedHashMap`的时候, 也就是说`LinkedHashMap`并没有提供明确的`set()`方法来改变该值(一旦在构造函数中指定, 就无法改变); `LinkedHashMap`提供了如下构造函数可以用于指定`accessOrder`的值, 其余构造函数中, `accessOrder`都默认为`false`, 即默认以`insertion-order`的顺序组织双向链表

```
    public LinkedHashMap(int initialCapacity,
                         float loadFactor,
                         boolean accessOrder) {
        super(initialCapacity, loadFactor);
        this.accessOrder = accessOrder;
    }
```

`LinkedHashMap`重写了`HashMap`的`newNode()`函数, `newNode()`在进行元素插入的时候会被`HashMap.putVal()`调用, `LinkedHashMap`用自己的`Entry`节点替换`HashMap``Node`节点的同时, 进行双向链表的构建, 使得程序改动最小

```
    Node<K,V> newNode(int hash, K key, V value, Node<K,V> e) {
        LinkedHashMap.Entry<K,V> p =
            new LinkedHashMap.Entry<K,V>(hash, key, value, e);
        linkNodeLast(p); // 将节点插入到双向链表的末尾
        return p;
    }
```

至于`linkNodeLast()`函数, 即将节点插入到双向链表的末尾, 该方法比较简单, 这里就不再贴源码啦 !

那么当我们指定了`accessOrder`为`true`的时候, 即以元素访问顺序来组织双向链表的时候, 其实就只是在获取元素的时候, 将被访问的元素移动到链表末尾; 如下; 那么链表表头的元素就是最近没有被访问的元素, 这也是我们实现`LRU`算法的依据(稍后会细讲)

```
    public V get(Object key) {
        Node<K,V> e;
        if ((e = getNode(hash(key), key)) == null)
            return null;
        if (accessOrder) // 如果指定为按照元素访问顺序组织元素
            afterNodeAccess(e); // 将元素移动到链表末尾
        return e.value;
    }
```

```
    void afterNodeAccess(Node<K,V> e) { // move node to last
        // 省略具体细节
        ...
    }
```

到这里, 我们对`LinkedHashMap`遍历有序的原因有了较为详细的了解; 接下来要讲的是`LinkedHashMap`的一个应用, 即用于实现`LRU`算法的特性


-----

## 三. LRU算法

**LRU算法**即`Least Recently Used`, 其依据是**如果数据最近被访问过, 那么其将来被访问的几率也更大**

`Android`中的`LruCache`(内存缓存)内部就是利用`LinkedHashMap`实现的

前面我们讲了, 当`accessOrder`设置为`true`, 即按照元素访问顺序组织数据的时候, 会在`get()`方法中将被访问的元素移动到链表的末尾, 那么链表首部的元素就是最久没有访问的, 所以, 当要使用`LinkedHashMap`实现`LRU`的时候, 必须将`accessOrder`置为`true`

另外, 还需要我们自己去定义`LRU`的实现规则, 即自己定义什么时候应该移除最久没有使用的元素; 此时我们需要去重写`LinkedHashMap`的`removeEldestEntry()`函数, `removeEldestEntry()`是在我们插入一个元素完毕之后, 回调`afterNodeInsertion()`中调用的, 如下; 但是`removeEldestEntry()`默认返回`false`, 所以需要我们自己去定义规则 

```
    void afterNodeInsertion(boolean evict) { // possibly remove eldest
        LinkedHashMap.Entry<K,V> first;
        if (evict && (first = head) != null && removeEldestEntry(first)) { // 插入元素之后, 判断是否需要移除最久没有访问的元素
            K key = first.key;
            removeNode(hash(key), key, null, false, true); // 移除链表首部的元素
        }
    }
```

至于自定义规则, 比如: 约定最多在内存中缓存多少个元素, 超过该阈值之后, `removeEldestEntry()`返回`true`, 即将旧元素移除; 或者, 规定缓存占用多少内存, 当达到该阈值之后, 即进行旧元素移除; 当然, 这些都是后话, 具体的`LRU`算法, 可以根据实际需求来定


----

## 四. 总结

`LinkedHashMap`基于`HashMap`, 总体上比较简单, 主要掌握上文说的两个主要特点即可, 不再赘述 !
