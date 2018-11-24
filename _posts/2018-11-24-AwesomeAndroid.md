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

```
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        initView()
    }

    private fun initView() {
//        Thread { main_text.text = "World" }.start()
        Thread {
            sleep(200)
            main_text.text = "World"
        }.start()
    }
}
```
