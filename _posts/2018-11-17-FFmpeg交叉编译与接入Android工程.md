---
layout:     post
title:      "FFmpeg交叉编译与接入Android工程"
subtitle:   "记录FFmpeg的交叉编译与将动态库接入Android工程"
date:       2018-11-17
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - Android
---

# 前言

> 本文主要讲解如何在`Linux`上编译`FFmpeg`, 以及将编译出来的动态库(`so`)接入已有的`Android`工程

------------------

# 正文

---------------

## 一. FFmpeg交叉编译

本文选用的`FFmpeg`版本是`FFmpeg 4.0`, `NDK`版本是`Android-ndk-r15c`, 注意在编译`FFmpeg`时, 对`NDK`版本有要求, 另外, 笔者最开始选用最新版本的`NDK`, 总是编译不过, 去查证了一下, 发现从`Androud-ndk-r16`开始, 其用于交叉编译都有问题了, 所以选用较低版本的`Androud-ndk`; 本文选用的`FFmpeg`版本和`NDK`版本亲测可编译通过; 先提供下载地址:

[FFmpeg 4.0](https://ffmpeg.org/releases/ffmpeg-4.0.tar.bz2)

[Android-ndk-r15c](https://dl.google.com/android/repository/android-ndk-r15c-linux-x86_64.zip)

笔者选用的编译环境是`ArchLinux`, `Windows`上的编译的话, 大体流程不变, 环境配置需要自己弄啦~

在开始之前, 需要先了解一下相关知识: 

> 1. JNI和NDK
> 2. CPU架构
> 3. 交叉编译
> 4. FFmpeg简介

这里推荐[官方文档](https://developer.android.google.cn/ndk/guides/), 对以上方面讲解比较详细; 下面简要介绍重点地方


### 1.1 基础知识

#### 1.1.1 JNI和NDK

`JNI`就是`Java Native Interface`, 即`Java`层和`Native`层通信的接口; 通过`JNI`, `Java`可以实现和其他语言之间的互相调用(注意其他语言不仅仅只限于`C/C++`, 虽然大多时候是`C/C++`); `Java`是跨平台的, 但是`C/C++`不是跨平台的, 所以`JNI`也使得`Java`需要考虑和特定平台相关的特性

`NDK`就是`Native Development Kit`, 是`Android`平台提供的一个工具集, 提供与本地代码之间的交互

详细可参见[博客](https://blog.csdn.net/carson_ho/article/details/73250163)

#### 1.1.2 CPU架构

不同的手机使用不同的`CPU`, 不同的`CPU`有不同的指令集, 每种`CPU`及其指令集有其自己的应用程序二进制接口(`Application Binary Interface`即`ABI`); `ABI`定义了机器代码与系统运行时的交互方式; `ABI`与指令集的对应关系如下表(摘自官方文档)

![ABI与指令集对应关系](/img/post/FFmpegCompile/ABI与指令集对应关系.png)

常见的`CPU`架构有`x86`, `x86-64`以及`arm`等(`x86-64`也是基于`x86`的), 其中, `x86`主要是针对`PC`端, `arm`主要针对移动端; `Android`系统目前支持`ARMv5`, `ARMv7`, `ARMv8`, ` x86`, `x86_64`, `MIPS`以及`MIPS64`共七种`CPU`架构

在`Android`中应用安装时, `Package Manager Service`会去扫描`APK`, 只有该设备`CPU`架构支持的`.so`文件才会被安装, 另外还可以定义`.so`文件的对应安装优先级


#### 1.1.3 交叉编译

在某个平台上编译该平台上的可执行文件叫本地编译; 如果在一个平台上编译在其他平台上的可执行程序则叫交叉编译; 交叉编译是随着嵌入式系统的发展而发展的, 因为嵌入式系统的处理能力, 内存等均有限, 所以有时候需要在其他平台上编译好后导入嵌入式系统中, 此时就需要交叉编译

交叉编译最主要的是环境, 即交叉编译链; 对本文来说, 编译`FFmpeg`需要准备`NDK`, `NDK`中提供了交叉编译链; 即`android-ndk-r15c/toolchains/`下提供的各种平台相关的编译工具链

本文使用的示例是在`x86`的`Linux`下编译`arm-v7a`架构的动态库

#### 1.1.4 FFmpeg

推荐[官方文档](https://ffmpeg.org/ffmpeg-formats.html)

[基本用法](http://javapyer.iteye.com/blog/1989274)


-----------------------


### 1.2 FFmpeg交叉编译

在开始之前需要先配置一下`NDK`的环境变量, 在`/etc/profile`文件中添加`PATH`

`FFmpeg`编译生成的动态库默认格式为`xx.so.版本号`, 但是`Android`工程中只支持以`.so`结尾的动态库, 所以需要修改`FFmpeg`的配置文件, 修改其生成库文件名的格式; 编辑`FFmpeg`目录下的`configure`文件, 修改如下: 

```
# 将configure文件中的：
SLIBNAME_WITH_MAJOR='$(SLIBNAME).$(LIBMAJOR)'
LIB_INSTALL_EXTRA_CMD='$$(RANLIB) "$(LIBDIR)/$(LIBNAME)"'
SLIB_INSTALL_NAME='$(SLIBNAME_WITH_VERSION)'
SLIB_INSTALL_LINKS='$(SLIBNAME_WITH_MAJOR) $(SLIBNAME)'

#替换为：
SLIBNAME_WITH_MAJOR='$(SLIBPREF)$(FULLNAME)-$(LIBMAJOR)$(SLIBSUF)'
LIB_INSTALL_EXTRA_CMD='$$(RANLIB) "$(LIBDIR)/$(LIBNAME)"'
SLIB_INSTALL_NAME='$(SLIBNAME_WITH_MAJOR)'
SLIB_INSTALL_LINKS='$(SLIBNAME)'
```

为了减小`APK`大小, 我们只将需要的功能开启即可; 配置参数较多, 我们写一个脚本如下(名为`build-script.sh`)

> 注: 下面的注释在运行脚本时需删除~

```
#!/bin/bash

NDK=/home/yuanping/Software/NDK/android-ndk-r15c  # NDK所在路径, 注意替换为你的
SYSROOT=$NDK/platforms/android-19/arch-arm/
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64 # 交叉编译链, 这里使用的是arm, 如果需要编译其他平台的, 更换即可
function build_one
{
./configure \
--prefix=$PREFIX \
--enable-shared \  # 生成动态库
--disable-static \ # 禁止生成静态库
--disable-doc \  # 关闭不需要的功能, 下同
--disable-ffplay \
--disable-ffprobe \
--disable-doc \
--disable-symver \
--disable-ffmpeg \
--enable-small \
--cross-prefix=$TOOLCHAIN/bin/arm-linux-androideabi- \
--target-os=linux \
--arch=arm \ 
--enable-cross-compile \
--sysroot=$SYSROOT \
--extra-cflags="-Os -fpic $ADDI_CFLAGS" \
--extra-ldflags="$ADDI_LDFLAGS" \
$ADDITIONAL_CONFIGURE_FLAG
make clean all
make -j3
make install
}
CPU=armv7-a # CPU架构
PREFIX=$(pwd)/android/$CPU # 生成动态库所在路径
ADDI_CFLAGS="-marm"
build_one
```

之后运行该脚本即可, 注意添加可执行权限(`sudo chmod a+x build-script.sh`)


等待一会应该就好啦, 然后在`FFmpeg`目录下有一个`android`目录, 生成的动态库就在其中啦~; 笔者生成的如下:

![Armv7-a](/img/post/FFmpegCompile/armv7-a.png)



-------------------


## 二. 动态库接入Android工程

在开始接入之前, 需要先配置`Android Studio`的环境; 主要是在`SDK Manager`中下载`CMake`, `LLDB`; 这里可以不用下载`NDK`, 最好使用与编译版本一致的`NDK`, 以免出现兼容性问题

![SDKManager](/img/post/FFmpegCompile/SDKManager.png)

配置`NDK`路径, 如下:

![NDK路径](/img/post/FFmpegCompile/NDKPath.png)

`Android`项目接入`JNI`有两种方法, 一种是通过`cmake`和`CMakeLists.txt`配置文件来指定; 另一种是通过`ndk-build`和`Android.mk`, `Application.mk`配置文件来指定; 官方推荐使用第一种; 关于第二种接入方式, 可以参见[官方文档](https://developer.android.google.cn/ndk/guides/android_mk)配置

这里主要讲解第一种方式, 参见[官方文档](https://developer.android.com/studio/projects/configure-cmake)

如果是创建的新项目的话, 可以直接在创建项目的时候选择`include C++  surpport`, 如下图; 如果项目已经创建了, 也不要紧, 下面讲解的就是这种情况

![JNI新项目](/img/post/FFmpegCompile/JNI新项目.png)

我们先来看一下完整的目录结构如下:

![目录结构](/img/post/FFmpegCompile/JNI目录结构.png)

在`main`目录下创建一个`jni`目录(其他目录名也可以, 但是要注意后文的更改), 在`jni`下创建一个`ffmpeg`目录, 将上面编译好的`android/armv7-a/lib`目录下的`.so`文件拷贝到`Android`工程的`ffmpeg/armeabi-v7a`下(新建`armeabi-v7a`目录, 注意目录名一定要是`armeabi-v7a`, 和`CPU`架构对应), 需要注意的是生成的动态链接库中有一些不带版本号的是指向另一个待版本号的软链接, 如下举例的两个`so`文件, 其中`libavcodec.so`文件是软链接, 指向`libavcodec-58.so`, 所以拷贝时不需要拷贝这些软链接咯

![动态链接库](/img/post/FFmpegCompile/动态链接库.png)

再将`android/armv7-a`目录下的`include`文件夹拷贝到`ffmpeg`下; 创建好后目录结构如下:

![创建jni目录](/img/post/FFmpegCompile/创建jni目录.png)

在`app`目录下创建`CMakeLists.txt`(一定要是这个名字咯), 如下:

![创建CMakeLists](/img/post/FFmpegCompile/创建CMakeLists.png)

内容如下: 

```
cmake_minimum_required(VERSION 3.4.1) # cmake最低版本

add_library( # Sets the name of the library.
             wlffmpeg

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             src/main/jni/ffmpeg/player.c )

add_library( avcodec-58  # 库名字
             SHARED
             IMPORTED)
set_target_properties( avcodec-58
                       PROPERTIES IMPORTED_LOCATION
                       ${CMAKE_SOURCE_DIR}/src/main/jni/ffmpeg/armeabi-v7a/libavcodec-58.so) 

add_library( avdevice-58
             SHARED
             IMPORTED)
set_target_properties( avdevice-58
                       PROPERTIES IMPORTED_LOCATION
                       ${CMAKE_SOURCE_DIR}/src/main/jni/ffmpeg/armeabi-v7a/libavdevice-58.so)

add_library( avfilter-7
             SHARED
             IMPORTED)
set_target_properties( avfilter-7
                       PROPERTIES IMPORTED_LOCATION
                       ${CMAKE_SOURCE_DIR}/src/main/jni/ffmpeg/armeabi-v7a/libavfilter-7.so)

add_library( avformat-58
             SHARED
             IMPORTED)
set_target_properties( avformat-58
                       PROPERTIES IMPORTED_LOCATION
                       ${CMAKE_SOURCE_DIR}/src/main/jni/ffmpeg/armeabi-v7a/libavformat-58.so)

add_library( avutil-56
             SHARED
             IMPORTED)
set_target_properties( avutil-56
                       PROPERTIES IMPORTED_LOCATION
                       ${CMAKE_SOURCE_DIR}/src/main/jni/ffmpeg/armeabi-v7a/libavutil-56.so)

add_library( swresample-3
             SHARED
             IMPORTED)
set_target_properties( swresample-3
                       PROPERTIES IMPORTED_LOCATION
                       ${CMAKE_SOURCE_DIR}/src/main/jni/ffmpeg/armeabi-v7a/libswresample-3.so)

add_library( swscale-5
             SHARED
             IMPORTED)
set_target_properties( swscale-5
                       PROPERTIES IMPORTED_LOCATION
                       ${CMAKE_SOURCE_DIR}/src/main/jni/ffmpeg/armeabi-v7a/libswscale-5.so)


find_library( # Sets the name of the path variable.
              log-lib  # Android内置的log模块, 用于将JNI层的log打到AS控制台

              # Specifies the name of the NDK library that
              # you want CMake to locate.
              log )

include_directories(src/main/jni/ffmpeg/include)

target_link_libraries( # Specifies the target library.  # 链接

                       wlffmpeg  
                       avcodec-58
                       avdevice-58
                       avfilter-7
                       avformat-58
                       avutil-56
                       swresample-3
                       swscale-5

                       # Links the target library to the log library
                       # included in the NDK.
                       ${log-lib} )

```

关于`CMake`配置可以参见[文档](https://developer.android.com/studio/projects/configure-cmake)

在模块级别的`build.gradle`下配置: 

```
android {
    ...
    defaultConfig {
        ...
        externalNativeBuild {
            cmake {
                cppFlags "" 
            }
            ndk {
                abiFilters "armeabi-v7a" # 指定CPU架构
            }
        }
        sourceSets {
            main {
                jniLibs.srcDirs = ['src/main/jni/ffmpeg']  # 指定jni路径
            }
        }
    }
    externalNativeBuild {
        cmake {
            path 'CMakeLists.txt' # 指定cmake的配置文件路径
        }
    }
}
```

创建`FFmpeg.java`类, 使用静态代码块加载动态链接库, 定义`native`方法`playMyMedia()`, 如下:

```
public class FFmpeg {
    static {
        System.loadLibrary("avutil-56");
        System.loadLibrary("swresample-3");
        System.loadLibrary("avcodec-58");
        System.loadLibrary("avformat-58");
        System.loadLibrary("swscale-5");
        System.loadLibrary("avfilter-7");
        System.loadLibrary("avdevice-58");
        System.loadLibrary("wlffmpeg"); // 注意不要忘了加载这个库
    }

    public native void playMyMedia(String url);
}
```

在`playMyMedia()`上快捷键`Alt + Enter`选择`create function xxx`, 可以自动创建对应的`.c`文件, 当然该`.c`文件也可以自命名, 此处命名为`player.c`; `player.c`的完整代码如下: 该代码摘自[博客](https://blog.csdn.net/ywl5320/article/details/75136986)

```
#include <jni.h>
#include "libavformat/avformat.h"
#include <android/log.h>
#define LOGI(FORMAT,...) __android_log_print(ANDROID_LOG_INFO,"HusterYP",FORMAT,##__VA_ARGS__);  // 输出到AS的log中
#define LOGE(FORMAT,...) __android_log_print(ANDROID_LOG_ERROR,"HusterYP",FORMAT,##__VA_ARGS__);

JNIEXPORT void JNICALL
Java_com_gif_ping_jnidemo_FFmpeg_playMyMedia(JNIEnv *env, jobject instance, jstring url_) {
    const char *url = (*env)->GetStringUTFChars(env, url_, 0);
    LOGI("url:%s", url);
    av_register_all();
    AVCodec *c_temp = av_codec_next(NULL);
    while (c_temp != NULL)
    {
        switch (c_temp->type)
        {
            case AVMEDIA_TYPE_VIDEO:
                LOGI("[Video]:%s", c_temp->name);
                break;
            case AVMEDIA_TYPE_AUDIO:
                LOGI("[Audio]:%s", c_temp->name);
                break;
            default:
                LOGI("[Other]:%s", c_temp->name);
                break;
        }
        c_temp = c_temp->next;
    }
    (*env)->ReleaseStringUTFChars(env, url_, url);
}
```

然后在`MainActivity`中使用, 也比较简单; 注意添加网络权限, 在`log`中就可以看到输出的视频信息啦~

```
public class MainActivity extends AppCompatActivity {

    FFmpeg mFFmpeg;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        init();
    }

    private void init() {
        mFFmpeg = new FFmpeg();
        mFFmpeg.playMyMedia("http://video.xxx"); // 随便找一个视频url啦~
    }
}
```

到这里, 项目应该就能跑起来啦~

`Android`工程参见[JNIDemo](https://github.com/HusterYP/JNIDemo)

`FFmpeg`编译参见: https://github.com/HusterYP/FFmpeg

-----------------


## 三. 参考链接

[Cross Compiling FFmpeg 4.0 for Android](https://medium.com/@karthikcodes1999/cross-compiling-ffmpeg-4-0-for-android-b988326f16f2)

[Android 集成 FFmpeg (一) 基础知识及简单调用](https://blog.csdn.net/yhaolpz/article/details/76408829)

[Android Studio通过cmake创建FFmpeg项目](https://blog.csdn.net/ywl5320/article/details/75136986)
