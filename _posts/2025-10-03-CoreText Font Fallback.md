---
layout:     post
title:      "CoreText Font Fallback"
subtitle:   "CoreText中的字体级联/Font Fallback机制"
date:       2025-10-03
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - 跨端渲染
    - Font
---

# 一、引言

> 本文基于Xcode 16.4，iOS 18.5模拟器分析，不同系统版本可能有区别。

前面我们介绍了[自定义文字排版引擎的原理](https://mp.weixin.qq.com/s/fcL6if52qYQUTChEjntHJg)，其中有一个复杂部分是字体Fallback，本文将通过逆向手段分析CoreText中`CTFontCopyDefaultCascadeListForLanguages`的实现，通过了解系统的字体回退实现，可以帮助我们实现更好的生产级别的文字排版引擎。

在开始之前，先介绍下`CTFontCopyDefaultCascadeListForLanguages` API，其完整的函数签名如下：

> 官方文档：https://developer.apple.com/documentation/coretext/ctfontcopydefaultcascadelistforlanguages(_:_:)

```swift
func CTFontCopyDefaultCascadeListForLanguages(
    _ font: CTFont,
    _ languagePrefList: CFArray?
) -> CFArray?
```

一个字体不可能支持所有的Unicode，比如Helvetica不支持中文，PingFang不支持韩文，在实际渲染时，往往是多个字体共同参与完成的，另外不同字体支持的Unicode有交集，那最终选择哪个字体也是有优先级的；`CTFontCopyDefaultCascadeListForLanguages`的作用就是：给定一个字体和语言列表，返回系统默认的Fallback列表（也叫级联列表，CascadeList），简单理解就是系统会按这个Fallabck列表进行优先级选择Fallback字体。

在macOS/iOS中，我们也可以通过`kCTFontCascadeListAttribute`显示指定Fallback链（如下），这样就能自定义Fallback，当然，如果不指定的话会系统也会启用默认Fallback，来尽量保证文本渲染正确。

```swift
func makeAttributedStringWithFallback(
    text: String,
    baseFontName: String = "Helvetica",
    size: CGFloat = 16,
    languages: [String] = ["zh-Hans", "ja", "ko"]
) -> NSAttributedString {
    let baseFont = CTFontCreateWithName(baseFontName as CFString, size, nil)
    let fallbacks = CTFontCopyDefaultCascadeListForLanguages(baseFont, languages as CFArray)
        as? [CTFontDescriptor] ?? []
    var attributes: [CFString: Any] = [
        kCTFontNameAttribute: baseFontName,
        kCTFontSizeAttribute: size
    ]
  	// 可以在这里修改fallbacks，来自定义回退
    if !fallbacks.isEmpty {
        attributes[kCTFontCascadeListAttribute] = fallbacks
    }
    let newDescriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
    let finalFont = CTFontCreateWithFontDescriptor(newDescriptor, size, nil)
    let attributesDict: [NSAttributedString.Key: Any] = [
        .font: finalFont
    ]
    return NSAttributedString(string: text, attributes: attributesDict)
}
```

下面，我们按如下调用Demo来实际研究下：

```swift
let ctFont = UIFont.systemFont(ofSize: 16)
let languages: [String] = ["zh-Hans"]
let cascadeList = CTFontCopyDefaultCascadeListForLanguages(ctFont, languages as CFArray)
```

# 二、调用链路

![CTFontCopyDefaultCascadeListForLanguages](/img/post/FontFallback/CTFontCopyDefaultCascadeListForLanguages.png)

如上是`CTFontCopyDefaultCascadeListForLanguages`的调用链路，可以看出大致分为两条处理链路：

* **Preset Fallbacks**：系统预设Fallback，这是一个“快速通道”，系统内部维护了一个针对特定字体（如系统UI字体）的硬编码Fallback列表，如果请求的主字体在这个预设列表中，系统会直接使用这个列表，速度非常快。
* **System Default Fallbacks**：系统默认Fallback，这是一个“通用通道”，如果预设列表没有命中，系统会启动默认Fallback流程，该流程会加载一个全局的、定义了完整回退规则的配置文件，根据用户的语言偏好设置，动态地为请求的字体生成一个Fallback列表，并进行缓存以提高后续调用效率。

后文我们也将按这两个流程分开分析。

完整的反汇编逻辑和注释可以参考：https://github.com/HusterYP/FontFallback

# 三、TBaseFont::CreateFallbacks

```assembly
/**
* 核心分发函数，决定是使用预设Fallback还是系统默认Fallback。
*
* @param result@<X0> (TBaseFont*) TBaseFont 实例。
* @param a2@<X1>     (int) 标志位，可能表示是否为系统UI字体。
* @param a3@<X2>     (int) 字体属性。
* @param a4@<X3>     (_QWORD*) 未知参数，可能是字符集。
* @param a5@<X4>     (CFArrayRef) 语言列表。
* @param a6@<X8>     (_QWORD*) 用于接收结果的输出指针。
*
* @return __int64 无实际意义。
 */
__int64 __usercall TBaseFont::CreateFallbacks@<X0>(__int64 result@<X0>, __int64 a2@<X1>, __int64 a3@<X2>, __int64 a4@<X3>, __int64 a5@<X4>, _QWORD *a6@<X8>)
{
	...
  // 保存参数
  v6 = a3;  // 字体特性标志
  v7 = a5;  // 语言数组指针
  v8 = a2;  // 系统UI字体标志
  v9 = (TBaseFont *)result;  // 基础字体对象
  ...
  // 如果系统UI字体标志不为 0，尝试创建预设字体回退
  if ( (_DWORD)a2 )
  {
    v11 = (_QWORD *)a4;
    // 从字体对象中获取字体名，如.SFUI-Regular
    v12 = (*(__int64 (**)(void))(*(_QWORD *)result + 560LL))();
    if ( v12 )
    {
      v13 = v12;
      // 初始化字体描述符源对象
      TDescriptorSource::TDescriptorSource((TDescriptorSource *)&v33);
      _X26 = &v34;
      // 创建预设字体回退列表
      _X0 = TDescriptorSource::CreatePresetFallbacks(v13, v11, v7, v6, &v34);
      ...
    }
  }
  // 检查预设字体回退是否成功创建
  v24 = objc_retain(_X0);
  if ( v24 )
  {
    v25 = v24;
    v26 = CFArrayGetCount(v24);
    result = objc_release(v25);
    // 如果预设字体回退不为空，直接返回
    if ( v26 )
      return result;
  }
  ...
  // 如果预设字体回退为空，创建系统默认字体回退
  v27 = TBaseFont::GetCSSFamily(v9);
  _X23 = &v34;

  // 创建系统默认字体回退列表
  _X0 = TBaseFont::CreateSystemDefaultFallbacks((__int64)v9, v27, v7, v8, &v34);
  ...
  return result;
}
```

这是处理预设Fallback和默认Fallback的入口函数。

**1）`result@<X0>`参数是什么**

首先我们主要关注的是第一个入参`result@<X0>`，我们先尝试反汇编x0，发现它其实指向的是类 `TTenuousComponentFont` （CoreText 内部的一个私有类，继承自 `TBaseFont`）的虚函数表，如下，下面的`udf` 其实是因为LLDB尝试将数据当代码解读，但其实它是一个指针表，所以识别成了未定义。

![CreateFallbacks-1](/img/post/FontFallback/CreateFallbacks-1.png)

CoreText 是由 C++ 和 Objective-C 混合实现的，C++类对象的方法调用是通过虚函数表（vtable）实现的，C++ 虚表是一个函数指针数组，对象里保存着一个 vptr（虚表指针），指向它所属类的 vtable。

下面我们尝试将`result@<X0>`按虚表指针解析，主要是`dis -c 5 -s xxx`，可以通过这种方式索引各方法。

![CreateFallbacks](/img/post/FontFallback/CreateFallbacks-2.png)

继续往上追溯，`result@<X0>`其实来自原始入参CTFont中的一个属性。

**2）什么情况下会触发Preset Fallbacks**

提取主要控制逻辑如下：

```assembly
// 如果系统UI字体标志不为 0，尝试创建预设字体回退
if ( (_DWORD)a2 )
{
  v11 = (_QWORD *)a4;
  // 从字体对象中获取字体名，如.SFUI-Regular
  v12 = (*(__int64 (**)(void))(*(_QWORD *)result + 560LL))();
  if ( v12 )
  {
  	...
  }
}
```

可以发现当`a2`非0时会触发Preset Fallbacks，继续往上追溯`a2`来自于`TFont::IsSystemUIFontAndForShaping((TFont *)v5, &v14)`，`IsSystemUIFontAndForShaping`不在本文重点，简单理解就是如果是系统UI字体且用于文本塑形的字体则返回true，比如典型的`UIFont.systemFont`（`.SFUI-Regular`：San Francisco (SF)字体家族中的字体）判定为true。

>  Q：为什么只有系统UI字体才有预设Fallback
>
> 简单理解就是只有系统UI字体是系统完全可控可感知的，所以可以提前构建Fallback列表

**3）什么情况下会触发System Default Fallbacks**

从上面反汇编逻辑比较容易看出，当Preset Fallbacks的结果为空时，会继续走System Default Fallbacks兜底。

# 四、Preset Fallbacks

## 4.1 获取全局预设Fallback列表CTPresetFallbacks

在分析系统是如何为特定字体构建预设Fallback（字体的级联列表）之前，我们需要先知道预设列表是从哪里读取的。

系统是通过`GetCTPresetFallbacksDictionary`获取预设列表的，继续往下追溯预设列表最终来自`GSFontCacheGetData`：

```assembly
/*
 * 函数: GSFontCacheGetData
 * -------------------------
 * @brief  从图形服务（GraphicsServices）的字体缓存中根据键名获取数据。
 * @param  a1 (void*)      String入参，实际是对应plist名称，比如预设列表的plist名称CTPresetFallbacks.plist
 * @param  a2 (const char*) 在此反汇编中未使用，可能是寄存器传参的残留。
 * @return (void*)         返回一个指向缓存数据的指针，如果找不到则可能返回NULL。
 */
void *__fastcall GSFontCacheGetData(void *a1, const char *a2)
{
  // =================================================================
  // 快速通道 1: 检查是否请求 "DefaultFontFallbacks.plist"
  // =================================================================
  // 调用 a1 的 isEqualToString: 方法，与字符串 "DefaultFontFallbacks.plist"（stru_6BEB8）比较
  if ( (unsigned int)objc_msgSend_isEqualToString_(a1, a2, &stru_6BEB8) )
  {
    // 如果是，直接返回全局变量 kDefaultFontFallbacks 的值。
    // 这是一个非常高效的硬编码路径，用于获取默认的后备字体规则。
    v4 = &kDefaultFontFallbacks;
    return (void *)*v4;
  }

  // =================================================================
  // 快速通道 2: 检查是否请求 "CTPresetFallbacks.plist"
  // =================================================================
  // 调用 a1 的 isEqualToString: 方法，与字符串 "CTPresetFallbacks.plist"（stru_6BED8）比较
  if ( (unsigned int)objc_msgSend_isEqualToString_(v2, v3, &stru_6BED8) )
  {
    // 如果是，直接返回全局变量 CTPresetFallbacks 的值。
    // 这正是我们之前分析的、包含了所有预设后备规则的那个.plist文件的内容。
    // 系统通过这个键来加载整个预设后备字典。
    v4 = &CTPresetFallbacks;
    return (void *)*v4;
  }

  // =================================================================
  // 快速通道 3: 检查是否请求某个特殊字典
  // =================================================================
  // 调用 a1 的 isEqualToString: 方法，与字符串 "CTFontInfo.plist"（stru_6BEF8）比较
  if ( !((unsigned __int64)objc_msgSend_isEqualToString_(v2, v5, &stru_6BEF8) & 1) )
  {
    // 如果键不是 stru_6BEF8，则进入下面的常规查询逻辑
    // =================================================================
    // 常规查询路径: 在一个全局字典 (unk_1EB8F0) 中查找
    // =================================================================
    // 检查键是否为 "CTCharacterSets.plist" (stru_6BF18)
    if ( (unsigned int)objc_msgSend_isEqualToString_(v2, v7, &stru_6BF18) )
    {
      // **键名转换/别名**: 如果是，则将要查询的键替换为另一个字符串 "CTCharacterSets" (stru_6BF38)
      v9 = &stru_6BF38;
    }
    // 检查键是否为 "GSFontCache.plist" (stru_6BF58)
    else if ( (unsigned int)objc_msgSend_isEqualToString_(v2, v8, &stru_6BF58) )
    {
      // **键名转换/别名**: 如果是，则将要查询的键替换为另一个字符串 "GSFontCache" (stru_6BF78)
      v9 = &stru_6BF78;
    }
    else
    {
      // 检查键是否为 "CoreTextConfig.plist" (stru_6BF98)
      if ( !(unsigned int)objc_msgSend_isEqualToString_(v2, v8, &stru_6BF98) )
        // 如果键不匹配上面任何一个需要转换的键，则使用原始的键 v2 在全局字典中查找
        return objc_msgSend_objectForKey_(&unk_1EB8F0, v8, v2);
      
      // **键名转换/别名**: 如果键是 stru_6BF98，则将其替换为 "CoreTextConfig" (stru_6BFB8)
      v9 = &stru_6BFB8;
    }
    
    // 对于所有经过“键名转换”的情况，使用转换后的新键 v9 在全局字典中查找
    // objectForKeyedSubscript: 是 OC 中字典下标语法 (dictionary[key]) 的底层实现
    return objc_msgSend_objectForKeyedSubscript_(&unk_1EB8F0, v8, v9);
  }

  // 如果快速通道3的检查为真 (键等于 stru_6BEF8)，则直接返回整个全局字典 unk_1EB8F0
  return &unk_1EB8F0;
}
```

从反汇编逻辑不太容易看，可以结合LLDB Debug一起分析：

![CTPresetFallbacks-plist](/img/post/FontFallback/CTPresetFallbacks-plist.png)

在查询预设列表时，入参是`CTPresetFallbacks.plist`，系统会从**全局变量CTPresetFallbacks**中读取预设列表，CTPresetFallbacks是全局共享的，是在CoreText服务启动时构建的一个全局常量，内容如下：

> 完整列表见：https://github.com/HusterYP/FontFallback/blob/main/CTPresetFallbacks.plist

```json
{
  ...
  ".SFUI-Regular" =     (
        ".AppleSystemFallback-Regular",
        ".AppleColorEmojiUI",
        ".SFGeorgian-Regular",
        HelveticaNeue,
        ".AppleSymbolsFB",
                {
            ar = ".AppleArabicFont-Regular"; // 如果系统语言是阿拉伯语(ar)，则使用此字体
            ur = ".AppleUrduFont-Regular"; // 如果是乌尔都语(ur)，则使用此字体
        },
                {
            ja = ".AppleJapaneseFont-Regular"; // 如果是日语(ja)
            ko = ".AppleKoreanFont-Regular"; // 如果是韩语(ko)
            my = "NotoSansMyanmar-Regular";
            "my-Qaag" = "NotoSansZawgyi-Regular";
            "zh-HK" = ".AppleHongKongChineseFont-Regular"; // 香港繁体中文
            "zh-Hans" = ".AppleSimplifiedChineseFont-Regular"; // 简体中文
            "zh-Hant" = ".AppleTraditionalChineseFont-Regular"; // 台湾繁体中文
            "zh-MO" = ".AppleMacaoChineseFont-Regular";
        },
        ".ThonburiUI-Regular",
        ".SFHebrew-Regular",
        ".SFArmenian-Regular",
        ".AppleIndicFont-Regular",
        "KohinoorDevanagari-Regular",
        Kailasa,
        "KohinoorBangla-Regular",
        "KohinoorGujarati-Regular",
        "MuktaMahee-Regular",
        "NotoSansKannada-Regular",
        KhmerSangamMN,
        LaoSangamMN,
        MalayalamSangamMN,
        NotoSansOriya,
        SinhalaSangamMN,
        TamilSangamMN,
        "KohinoorTelugu-Regular",
        "NotoSansArmenian-Regular",
        EuphemiaUCAS,
        "Menlo-Regular",
        AppleSymbols,
        ArialMT,
        "STIXTwoMath-Regular",
        ".HiraKakuInterface-W4",
        HelveticaNeue,
        "Kefa-Regular",
        Galvji,
        ".PhoneFallback"
    );
    SystemWideFallbacks =     (
                (
            128,
            887,
            "Charter-Roman"
        ),
                (
            895,
            895,
            "DINCondensed-Bold"
        ),
                (
            975,
            1315,
            "Charter-Roman"
        ),
                (
            1316,
            1319,
            ".SFUI-Regular"
        ),
				...
    )
}
```

CTPresetFallbacks.plist中主要定义了两组内容：

**1）为特定字体定义Fallback列表/级联列表**

比如我们这里要查询`.SFUI-Regular`的Fallback列表，就用`.SFUI-Regular`作为key去CTPresetFallbacks.plist中找到一组字典进行解析，解析逻辑后面会讲。

**2）SystemWideFallbacks**

SystemWideFallbacks定义了一个全局级别的 Fallback 映射，和字体无关，按 Unicode code point 范围定义；每个元素是一个三元组，包括：起始 Unicode 码点 + 结束 Unicode 码点 + 指定 Fallback 字体。

比如128～887范围优先用Charter-Roman。

## 4.2 预设列表解析流程

获取到全局预设列表之后，我们再来看系统是如何针对特定字体（系统的UI字体）构建级联列表的，主要逻辑在`CreatePresetFallbacks`中，如下：

```assembly
/*
* 实现“快速通道”，从一个全局的、硬编码的字典中查找并创建预设列表。
*
* @param a1@<X1> (CFStringRef) 字体名称或标识符。
* @param a2@<X2> (_QWORD*)     输出参数，可能用于字符集。
* @param a3@<X3> (CFArrayRef)  语言列表。
* @param a4@<X4> (int)         标志位。
* @param a5@<X8> (_QWORD*)     用于接收结果的输出指针。
*
* @return __int64 返回创建的预设列表 (CFArrayRef)。
*/
__int64 __usercall TDescriptorSource::CreatePresetFallbacks@<X0>(__int64 a1@<X1>, _QWORD *a2@<X2>, __int64 a3@<X3>, __int64 a4@<X4>, _QWORD *a5@<X8>)
{
  ...
  _X19 = a5;
  // 1. 获取全局预设字典
  result = GetCTPresetFallbacksDictionary();
  v11 = result;
  // 2. 创建有序的语言列表
  v12 = CreateOrderedLanguages(v6);
  // 3. 使用字体名 a1 在预设字典中查找
  v13 = CFDictionaryGetValue(v11, v8);
  // 4. 如果找到匹配项，并且它是一个数组，则开始处理
  if ( v13 && (v15 = v13, v16 = CFGetTypeID(v13), v16 == CFArrayGetTypeID()) )
  {
    // 创建一个可变数组用于存放结果
    v37 = CFArrayCreateMutable(*(_QWORD *)kCFAllocatorDefault_ptr, 0LL, kCFTypeArrayCallBacks_ptr);
    v17 = CFArrayGetCount(v15);
    if ( v17 )
    {
      // 5. 遍历预设数组中的每一项
      do
      {
        v20 = (__CFString *)CFArrayGetValueAtIndex(v15, v19);
        v21 = CFGetTypeID(v20);
				// 5a. 如果是字典类型，说明是按语言区分的后备字体
        if ( v21 == CFDictionaryGetTypeID() )
        {
          // 遍历上面构建的语言列表，在字典中查找匹配的后备字体
          do
          {
            v25 = CFArrayGetValueAtIndex(v12, v24);
            if ( v20 )
            {
              v26 = CFDictionaryGetValue(v20, v25);
              if ( v26 )
                TDescriptorSource::AppendFontDescriptorFromName(&v37, v26, 1024LL);
            }
          }
          while ( v23 != v24 );
        }
        // 5b. 如果是字符串类型，直接作为后备字体名
        else
        {
          // ... 对Emoji等特殊字体进行处理 ...
          TDescriptorSource::AppendFontDescriptorFromName(&v37, v20, 1024LL);
        }
        ++v19;
      }
      while ( v19 != v18 );
    }
  }
  // 将最终结果写入输出指针并返回
  ...
}
```

代码注释已经比较清晰，总结下来解析流程是：

**1）通过字体名从全局预设列表中查询Fallback数组**

比如我们通过`.SFUI-Regular`查询到的原始Fallback数组如下：

```json
".SFUI-Regular" =     (
        ".AppleSystemFallback-Regular",
        ".AppleColorEmojiUI",
        ".SFGeorgian-Regular",
        HelveticaNeue,
        ".AppleSymbolsFB",
                {
            ar = ".AppleArabicFont-Regular"; // 如果系统语言是阿拉伯语(ar)，则使用此字体
            ur = ".AppleUrduFont-Regular"; // 如果是乌尔都语(ur)，则使用此字体
        },
                {
            ja = ".AppleJapaneseFont-Regular"; // 如果是日语(ja)
            ko = ".AppleKoreanFont-Regular"; // 如果是韩语(ko)
            my = "NotoSansMyanmar-Regular";
            "my-Qaag" = "NotoSansZawgyi-Regular";
            "zh-HK" = ".AppleHongKongChineseFont-Regular"; // 香港繁体中文
            "zh-Hans" = ".AppleSimplifiedChineseFont-Regular"; // 简体中文
            "zh-Hant" = ".AppleTraditionalChineseFont-Regular"; // 台湾繁体中文
            "zh-MO" = ".AppleMacaoChineseFont-Regular";
        },
	  	...
)
```

**2）遍历Fallback数组，如果是字典类型，需要按语言区分Fallback字体**

还记得最初`CTFontCopyDefaultCascadeListForLanguages`的函数签名中，第二个参数支持传语言列表：

```swift
func CTFontCopyDefaultCascadeListForLanguages(
    _ font: CTFont,
    _ languagePrefList: CFArray?
) -> CFArray?
```

系统会通过`CreateOrderedLanguages`创建一个有序的语言数组，具体做法是将调用者想要的语言（languagePrefList）、App自身想要的语言、以及用户在整个系统中设置的语言偏好合并成一个有序的语言数组。

然后遍历语言数组，从字典中筛选出对应语言的Fallback字体添加到结果中。

从这里可以看出，**同一字体的Fallback列表，还会受语言影响**，比如：

| zh-Hans                                        | zh-HK                                      |
| ---------------------------------------------- | ------------------------------------------ |
| ![zh-Hans](/img/post/FontFallback/zh-Hans.png) | ![zh-HK](/img/post/FontFallback/zh-HK.png) |

> Q：为什么Fallback字体还跟语言设置相关?
>
> 参考[自定义文字排版引擎的原理](https://mp.weixin.qq.com/s/fcL6if52qYQUTChEjntHJg)一文中针对「相同Script的字符如果使用了不同的Font，会有什么问题」的回答

**3）遍历Fallback数组，如果是字符串类型，「直接」作为Fallback字体**

「直接」加引号，因为还会处理Emoji字体等特殊情况。

**4）Fallback数组遍历完成之后，构建完成该字体最终的预设Fallabck列表/级联列表**

## 4.2 Preset Fallbacks小结

总结下Preset Fallbacks流程：

**1）系统从全局常量CTPresetFallbacks中读取预设列表**

**2）根据用户指定主字体名从全局预设列表中查询Fallback数组**

**3）遍历Fallback数组，如果为字典类型，根据用户指定语言、App偏好语言、系统设置偏好语言来选择Fallback字体**

**4）遍历Fallback数组，如果为字符串类型，「直接」作为Fallback字体**

**5）Fallback数组遍历完后，对应字体的级联列表构建完成**

# 五、System Default Fallbacks

如果系统预设Fallback没有查到结果，则会兜底到系统默认Fallback逻辑，为字体动态构建级联列表。

## 5.1 CSSFamily分类

```assembly
__int64 __usercall TBaseFont::CreateFallbacks@<X0>(__int64 result@<X0>, __int64 a2@<X1>, __int64 a3@<X2>, __int64 a4@<X3>, __int64 a5@<X4>, _QWORD *a6@<X8>)
{
  ...
  // 如果预设字体回退为空，创建系统默认字体回退
  v27 = TBaseFont::GetCSSFamily(v9);
  _X23 = &v34;

  // 创建系统默认字体回退列表
  _X0 = TBaseFont::CreateSystemDefaultFallbacks((__int64)v9, v27, v7, v8, &v34);
  ...
  return result;
}
```

系统默认Fallback，会先通过`TBaseFont::GetCSSFamily`将用户指定主字体分类，这是后续查表的关键；GetCSSFamily会读取字体特征进行分类，主要分为：

* **`sans-serif` (无衬线体)**：字体笔画的末端没有额外的装饰性“脚”，如Helvetica、Arial、San Francisco (SF Pro)、PingFang SC (苹方)
* **`serif` (衬线体)**：字体笔画的末端有装饰性的“脚”（衬线），如Times New Roman、Georgia、New York、宋体 
* **`monospace` (等宽体)**：所有字符占据相同的宽度，如Menlo、Courier、Monaco、SF Mono
* **`cursive` (手写体)**：如Snell Roundhand
* **`fantasy` (装饰体)**：如Papyrus

除此外，苹果在UI上下文中，还有几个扩展的CSSFamily分类：

* **`ui-serif`**：用于 UI 的衬线字体，主要指 `New York` 家族

* **`ui-sans-serif`**：用于 UI 的无衬线字体，即 `San Francisco` 家族

* **`ui-monospace`**：用于 UI 的等宽字体，即 `SF Mono`。

* **`ui-rounded`**：用于 UI 的圆体字体。如 `SF Pro Rounded` 和 `SF Compact Rounded`

## 5.2 获取系统默认Fallback列表kDefaultFontFallbacks

和全局预设列表一样，系统默认Fallback列表也是通过`GSFontCacheGetData`读取配置文件。

调用链路是：`CreateSystemDefaultFallbacks -> CopyDefaultSubstitutionListForLanguages -> CopyFontFallbacksForLanguages -> CopyFontFallbacks -> CopyDefaultFontFallbacks -> GSFontCacheGetData`；通过GSFontCacheGetData读取系统默认Fallback列表时，入参是`DefaultFontFallbacks.plist`

![DefaultFontFallbacks.plist](/img/post/FontFallback/DefaultFontFallbacks.plist.png)

也是从一个全局常量`kDefaultFontFallbacks`中获取的，内容如下：

```json
{
    common =     (
        ...
    );
    cursive =     (
        ...
    );
    default =     (
        ...
    );
    fantasy =     (
        ...
    );
    monospace =     (
        ...
    );
    "sans-serif" =     (
        Helvetica,
        AppleColorEmoji,
        ".AppleSymbolsFB",
                {
            ar = GeezaPro;
            ja = "HiraginoSans-W3";
            ko = "AppleSDGothicNeo-Regular";
            my = "NotoSansMyanmar-Regular";
            "my-Qaag" = "NotoSansZawgyi-Regular";
            ur = NotoNastaliqUrdu;
            "zh-HK" = "PingFangHK-Regular";
            "zh-Hans" = "PingFangSC-Regular";
            "zh-Hant" = "PingFangTC-Regular";
            "zh-MO" = "PingFangMO-Regular";
        },
        Thonburi,
        ArialHebrew
    );
    serif =     (
        ...
    );
    "ui-monospace" =     (
        ...
    );
    "ui-rounded" =     (
        ...
    );
    "ui-serif" =     (
        ...
    );
}
```

`DefaultFontFallbacks.plist`的格式基本和`CTPresetFallbacks.plist`类似，也是KV结构，Value部分也分为字符串和字典类型，字典类型也会根据用户指定语言来择优选取。

## 5.3 解析并缓存系统默认Fallback列表

解析和缓存逻辑主要由`CopyFontFallbacks`处理，主逻辑如下：

```assembly
/**
 * CoreText 字体回退 - 复制字体回退列表函数
 * 功能: 根据字体描述符和语言信息复制相应的字体回退列表
 * 
 * 参数:
 *   a1 (_QWORD *): 输出参数指针，用于接收生成的字体回退数组
 *   a2 (__int64): 字体描述符对象指针
 *   a3 (__CFString *): 主要语言代码字符串
 *   a4 (__CFString *): 次要语言代码字符串（可选）
 *   a5 (__int64): 语言数组指针（可选）
 * 
 * 返回值:
 *   __int64: 操作结果
 */
__int64 __fastcall TFontFallbacks::CopyFontFallbacks(_QWORD *a1, __int64 a2, __CFString *a3, __CFString *a4, __int64 a5)
{
	...
  // 保存参数到局部变量和寄存器
  _X22 = a5;  // 语言数组指针
  v6 = a4;    // 次要语言代码
  v7 = a3;    // 主要语言代码
  v8 = a2;    // 字体描述符对象
  v9 = a1;    // 输出参数指针
  // 先在Font实例成员变量字典中查找Fallback缓存
  v16 = CFDictionaryGetValue(_X0, a3);
  ...
  // 如果没有找到缓存，则动态构建
  if ( !_X9 )
  {
  	...
    // 获取系统默认Fallback列表
    CopyDefaultFontFallbacks();
    v22 = objc_retain(_X0);
    if ( v22 )
    {
      // 用cssfamliy从系统默认Fallback列表中查找映射
      v24 = CFDictionaryGetValue(v22, v6);      
      // 检查是否找到了有效的字体列表
      if ( v24 && CFArrayGetCount(v24) >= 1 )
      {
      	...
      	// 解析列表
        // 根据用户指定语言、App偏好语言、系统设置偏好语言创建有序语言数组
        v29 = CreateOrderedLanguages(_X22);
        // 处理字体回退列表
        TDescriptorSource::ProcessFallbackList(v24, (__int64)&v59, v31, v29);

        // 解析通用（common）字体回退列表
        v34 = CFDictionaryGetValue(_X25, &stru_1F69C8);
        TDescriptorSource::ProcessFallbackList(v36, (__int64)&v59, v31, v29);

				// 缓存结果到Font实例
        v44 = objc_retain(_X0);
        if ( v44 )
        {
        	...
        	CFDictionarySetValue(_X0, v7, _X2);
        }
      }
    }
  // 处理特定语言的回退逻辑
  ...
  return objc_release(v57);
}
```

注意CopyFontFallbacks中一共调了两次ProcessFallbackList，逻辑是先取对应CSSFamily的（比如sans-serif）Fallback列表，再取common的Fallback列表，最终将二者合并起来作为对应字体的Fallback结果。

ProcessFallbackList解析字体列表的逻辑和预设Fallback类似，也是根据Value是字符串类型还是字典类型来区分解析，此处不再赘述。

最后，CopyFontFallbacks还会将Fallback结果缓存到Font实例的字典变量中，key是`cssfamily + languages`（逗号分隔开），比如：`sans-serif,zh-HK`

![CopyFontFallbacks](/img/post/FontFallback/CopyFontFallbacks.png)



CopyFontFallbacks逻辑比较清晰，总结下来是：

**1）先从Font实例中获取Fallback缓存，如果已经构建过则直接使用**

**2）缓存获取失败，走动态构建，将对应CSSFamily的Fallback列表和common的Fallback列表合并成最终Fallback结果**

**3）缓存Fallback结果到Font实例，key是`cssfamily + languages`**



## 5.4 语言处理与线程安全

CopyFontFallbacksForLanguages在调用CopyFontFallbacks之前，会对用户指定的语言（即`CTFontCopyDefaultCascadeListForLanguages`的`languagePrefList`参数）进行处理：

```assembly
__int64 __usercall TFontFallbacks::CopyFontFallbacksForLanguages@<X0>(__int64 a1@<X0>, __int64 a2@<X1>, __int64 a3@<X2>, __int64 a4@<X8>)
{
  // 如果没有提供语言数组，直接调用单语言版本
  if ( !a3 )
    return TFontFallbacks::CopyFontFallbacks((_QWORD *)a4, a1, (__CFString *)a2, 0LL, 0LL);
	...
  // 获取系统有序语言数组
  v7 = GetOrderedLanguages;
  // 遍历输入的语言代码数组
  do
  {
    // 检查规范化后的语言代码是否在系统支持的语言列表中
    __asm { LDAPR           X3, [X22], [X22] }
    if ( (unsigned int)CFArrayContainsValue(v7, 0LL, v8, _X3) )
    {
      // 如果支持，添加到有效语言数组中
      CFArrayAppendValue(v6, v21);

    }
    ++v12;
  }
  while ( v11 != v12 );
  ...
  // 如果找到了有效的语言代码
  if ( CFArrayGetCount(v6) )
  {
      TFontFallbacks::CopyFontFallbacks(v24, v25, _X2, v4, v6);
  }
  else
  {
    // 如果没有找到有效语言，使用单语言版本
    TFontFallbacks::CopyFontFallbacks(v24, v25, v4, 0LL, 0LL);
  }
  ...
}
```

大致逻辑是：

* 如果`languagePrefList`传nil（注意空数组不算nil），则直接用cssfamily查询CopyFontFallbacks

* 如果`languagePrefList`不为nil，会将用户指定的languages通过GetOrderedLanguages过滤一遍，去除系统不支持的language，然后使用cssfamily + languages查询CopyFontFallbacks

另外，`CopyFontFallbacks`会有对字典的读写操作，为了线程安全，CopyDefaultSubstitutionListForLanguages会对整个流程加一把大锁：

```assembly
__int64 __usercall TDescriptorSource::CopyDefaultSubstitutionListForLanguages@<X0>(__int64 a1@<X0>, __int64 a2@<X1>, __int64 a3@<X8>)
{
  TDescriptorSource *v6; // 锁对象指针
  // 这个锁确保字体回退缓存的线程安全访问
  v6 = (TDescriptorSource *)os_unfair_lock_lock_with_options(&TDescriptorSource::sFontFallbacksLock, 327680LL);
  ...
  TFontFallbacks::CopyFontFallbacksForLanguages(TDescriptorSource::sFontFallbacksCache, v4, v3, v5);
  // 释放字体回退缓存锁并返回
  return os_unfair_lock_unlock(&TDescriptorSource::sFontFallbacksLock);
}
```

## 5.5 结果处理与返回

最后`CreateSystemDefaultFallbacks`会对`CopyDefaultSubstitutionListForLanguages`中获取到的字体描述符进行处理，即排除用户指定字体，防止自己Fallback自己。

# 六、总结

至此，我们通过逆向的手段梳理完了`CTFontCopyDefaultCascadeListForLanguages`的完整流程，最后整理下结论如下：

整体分为两个大流程：

**1、Preset Fallbacks：预设Fallback**

1.1 系统从全局常量CTPresetFallbacks中读取预设列表

1.2 根据用户指定主字体名从全局预设列表中查询Fallback数组

1.3 遍历Fallback数组，如果为字典类型，根据用户指定语言、App偏好语言、系统设置偏好语言来选择Fallback字体

1.4 遍历Fallback数组，如果为字符串类型，「直接」作为Fallback字体

1.5 Fallback数组遍历完后，对应字体的级联列表构建完成

**2、System Default Fallbacks：系统默认Fallback**

1.1 获取主字体的CSSFamily分类

1.2 从全局常量kDefaultFontFallbacks中读取默认Fallback列表

1.3 用`cssfamily + languages`从字体实例中获取Fallback缓存，如果已经构建则直接使用

1.4 缓存缺失则动态构建，根据CSSFamily获取对应字体的Fallback列表并解析，获取common类型的Fallback列表并解析，合并二者结果作为最终Fallback结果

1.5 用`cssfamily + languages`将Fallback结果缓存到Font实例

1.6 处理并返回Fallback结果
