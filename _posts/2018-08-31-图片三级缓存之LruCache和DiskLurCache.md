---
layout:     post
title:      "图片三级缓存之内存缓存和磁盘缓存"
subtitle:   "内存缓存用LruCache, 磁盘缓存用DiskLruCache"
date:       2018-08-31
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - Android
---

# 前言

> 本文主要分析`Android`中图片三级缓存中的前两级缓存, 即内存缓存(`LruCache`)和磁盘缓存(`DiskLruCache`), 分析其源码实现

----

# 正文

----


## 一. LruCache

`LruCache`内部使用了一个`LinkedHashMap`实例, 所以在继续往下看之前, 建议先了解一下`LinkedHashMap`的特性, 可以参见[Java集合框架之LinkedHashMap](https://husteryp.github.io/2018/08/28/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BLinkedHashMap/), 该文章有讲解如何将`LinkedHashMap`用作内存缓存以及`LRU`算法的一些基本分析

**LRU算法**即`Least Recently Used`, 其依据是**如果数据最近被访问过, 那么其将来被访问的几率也更大**

`LruCache`逻辑其实比较简单, 大致逻辑就是: 设定最大阈值(`maxSize`), 当我们缓存一个新值的时候, 去判断是否超过该阈值, 如果超过了, 则移除最久未使用的缓存(这是利用的`LinkedHashMap`的特性, 可以参考上面的链接); 这是`LruCache`的一个大致流程与思路, 接下来我们会详细讲解一些较为细节的地方                


先来看其构造函数: `LruCache`只有一个构造函数, 需要传递一个最大的缓存阈值; 同时需要注意的是, 这里构造`LinkedHashMap`的时候, 将`accessOrder`标志位设置为`true`了, 使得`LinkedHashMap`通过访问顺序来构造双向链表, 这在我们讲解`LinkedHashMap`源码的时候重点分析过, 这里不再赘述 !

```
    public LruCache(int maxSize) {
        if (maxSize <= 0) {
            throw new IllegalArgumentException("maxSize <= 0");
        }
        this.maxSize = maxSize;
        this.map = new LinkedHashMap<K, V>(0, 0.75f, true);
    }
```

当然, `LruCache`还允许重新设置该阈值, 通过`trimToSize()`函数实现, 如下; 实现思路也很简单, 就是通过遍历当前缓存值, 然后不断删除最久未使用的缓存, 直到缓存量在阈值之下

```
     public void trimToSize(int maxSize) {
        while (true) {
            K key;
            V value;
            synchronized (this) {
                ...
                if (size <= maxSize || map.isEmpty()) {
                    break;
                }

                Map.Entry<K, V> toEvict = map.entrySet().iterator().next();
                key = toEvict.getKey();
                value = toEvict.getValue();
                map.remove(key);
                size -= safeSizeOf(key, value);
                evictionCount++;
            }

            entryRemoved(true, key, value, null);
        }
    }
```

在我们平时使用的时候, 需要重点关注的有两个方法, 一个是`sizeOf()`, 另一个是`entryRemoved()`; 这两个方法通常都会根据实际需要重写; 两个方法也很简单, 下面分别讲解

`sizeOf()`: 返回一个缓存条目的大小, 注意应该和`maxSize`在一个量级(以便正确比较); 其默认返回`1`, 单纯的表示缓存的条目数量, 代码很简单(只是`return 1`而已), 这里就不贴啦 ~

`entryRemoved()`: 该方法有点意思, 默认是一个空方法, 没有做任何处理; 在发生`value`缓存冲突的时候(`key`重复, 冲突)和删除缓存条目的时候会调用(通过传入参数`evicted`标志, `evicted == true`表示为`value`是被删除的, `evicted == false`表示`value`是因为`key`冲突被挤出来的)
一般我们重写该方法是为了做一些旧数据的回收清理等特殊工作

```
protected void entryRemoved(boolean evicted, K key, V oldValue, V newValue) {}
```
