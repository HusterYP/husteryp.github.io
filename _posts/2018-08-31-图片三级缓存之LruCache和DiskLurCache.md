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

`LruCache`常用作内存缓存, 也就是第一级缓存

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

-----

## 二. DiskLruCache

`DiskLruCache`常用作磁盘缓存, 也就是第二级缓存; 虽然其没有纳入`Android`的官方`API`, 但是受到了`Google`的官方推荐; 源代码可以从[Github](https://github.com/JakeWharton/DiskLruCache)下载

`DiskLruCache`的基本思路是, 将文件缓存到磁盘上, 设定最大的缓存阈值, 超过该值的时候, 会在后台去清除旧缓存

需要注意的是, 这里旧文件的清除是在后台线程完成的(实际上是开了一个线程池去做该工作), 有时候缓存的文件总量会暂时超过最大阈值, 所以对缓存容量比较敏感的程序应该设置保守的缓存阈值

先来看一下`DiskLruCache`的构造函数; 其只有一个构造函数, 如下; 其中`directory`表示缓存目录; `appVersion`表示应用版本号, 当该值改变时, `DiskLruCache`会清除所有缓存, 默认需要从网上拉取新数据; `valueCount`表示的是一个`key`可以对应多少个文件, 通常都传入`1`即可, 该值通常用于表示将一个大文件分成多个小文件存放, 存放的规则是, `key`后面加上自增的索引(如`key1`, `key2`等)(当然, 这些都是内部处理细节, 具体使用的时候可以不用管); `maxSize`表示的是缓存阈值(`byte`)

```
private DiskLruCache(File directory, int appVersion, int valueCount, long maxSize) {
    this.directory = directory;
    this.appVersion = appVersion;
    this.journalFile = new File(directory, JOURNAL_FILE);
    this.journalFileTmp = new File(directory, JOURNAL_FILE_TEMP);
    this.journalFileBackup = new File(directory, JOURNAL_FILE_BACKUP);
    this.valueCount = valueCount;
    this.maxSize = maxSize;
}
```

`DiskLruCache`的文件缓存依赖于日志文件, 即存储在同一文件夹下的名为`journal`的文件, 在该文件中, 存储了每个文件缓存的信息;  在开始之前, 需要先了解一下该文件的格式, 因为后面会去读取该日志文件, 做判断; 关于该文件格式, 可以参考[Android DiskLruCache完全解析，硬盘缓存的最佳方案](https://blog.csdn.net/guolin_blog/article/details/28863651)

```
          libcore.io.DiskLruCache
          1
          100
          2
     
          CLEAN 3400330d1dfc7f3f7f4b8d4d803dfcf6 832 21054
          DIRTY 335c4c6028171cfddfbaae1a9c313c52
          CLEAN 335c4c6028171cfddfbaae1a9c313c52 3934 2342
          REMOVE 335c4c6028171cfddfbaae1a9c313c52
          DIRTY 1ab96a171faeeee38496d8b330771a7a
          CLEAN 1ab96a171faeeee38496d8b330771a7a 1600 234
          READ 335c4c6028171cfddfbaae1a9c313c52
          READ 3400330d1dfc7f3f7f4b8d4d803dfcf6
```

在`DiskLruCache`中, 有三个重要的内部类, 一个是`Editor`, 用于文件写入; 一个是`Entry`, 表示一个文件信息节点; 还有一个是`Snapshot`, 表示文件节点的快照, 其实就是为了防止数据更改, 对`Entry`信息做了一层封装

其中, 在`Editor`中有一个`Entry`成员变量, 在`Entry`中有一个`Editor`成员变量, 这是为了考虑在多线程中使用的时候, 通过判断携带的是不是同一个`Entry`或者`Editor`来判断是否是在同一个线程中操作同一个文件; 因为`DiskLruCache`不允许多个线程去操作同一个文件

```
public final class Editor {
    private final Entry entry;
    ...
}
```
```
private final class Entry {
    ...
    private Editor currentEditor;
    ...
}
```

另外, 这里还需要关注的一点是, `DiskLruCache`是如何判断哪些文件是旧文件; 这里我们发现了一个熟悉的身影, 即`
private final LinkedHashMap<String, Entry> lruEntries = new LinkedHashMap<String, Entry>(0, 0.75f, true);`, 前面我们知道了`LruCache`是利用`LinkedHashMap`的访问特性来实现旧文件的判断和移除, 这里其实也是一样, 只不过这里存储的是`key`和`Entry`; 这也是前面日志文件`journal`的作用

在初始化的时候, 会先去`journal`日志文件读取键值信息, 在`readJournal()`中不断的去读取`journal`文件, 然后调用`readJournalLine()`构建信息, 存储在`LinkedHashMap`中; 然后在`get()`值或者判断旧文件去移除的时候, 就直接去查询`LinkedHashMap`中的值就好了; 至于判断旧文件的原理, 和`LruCache`一样, 可以参见[Java集合框架之LinkedHashMap](https://husteryp.github.io/2018/08/28/Java%E9%9B%86%E5%90%88%E6%A1%86%E6%9E%B6%E4%B9%8BLinkedHashMap/)

```
private void readJournal() throws IOException {
    ...
    while (true) {
        try {
          readJournalLine(reader.readLine());
          lineCount++;
        } catch (EOFException endOfJournal) {
          break;
        }
    }
    ...
}
```

```
private void readJournalLine(String line) throws IOException {
    ...
    Entry entry = lruEntries.get(key);
    if (entry == null) {
      entry = new Entry(key);
      lruEntries.put(key, entry);
    }
    ...
}
```


------------

## 三. 总结

到这里, 我们对内存缓存和磁盘缓存所需要使用到的两个类有了较为详细的了解, 之后该动手自己实践啦 !
