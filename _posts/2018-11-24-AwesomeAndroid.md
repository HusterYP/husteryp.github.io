---
layout:     post
title:      "AwesomeAndroid"
subtitle:   "AwesomeAndroid"
date:       2018-11-24
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - Note
---


# 前言

> 记录一些有趣的`Android`知识, 内容不限~

--------------------

# 正文

-----------------

## 子线程更新UI

考虑如下代码:

注: `MainActivity`的`Layout`布局只有一个`id`为`main_text`的`TextView`

```
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        initView()
    }

    private fun initView() {
//        Thread { main_text.text = "World" }.start() // 更新UI成功
        Thread {
            sleep(200)
            main_text.text = "World" // 更新UI失败(崩溃0)
        }.start()
    }
}
```

如上代码中, 在第二个子线程中跟新`UI`的时候失败了, 报错: `Only the original thread that created a view hierarchy can touch its views`; 即常见的不能在子线程中更新`UI`; 但是在第一个子线程中跟新`UI`成功了, 原因是: 线程的检查是在`ViewRootImp`中的`checkThread()`中, 但是在`onCreate()`中, 此时`ViewRootImp`还没有创建, 所以此时无法`checkThread()`, 实际上, `ViewRootImp`的创建是在`onResume()`方法回调之后, 在`WindowManagerGlobal`的`addView`中创建的; 所以如果这里的`initView`即使是在`onResume()`中调用也是同样的现象
