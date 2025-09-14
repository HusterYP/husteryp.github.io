---
layout:     post
title:      "Text Handling"
subtitle:   "Text Handling"
date:       2025-09-03 
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - 跨端渲染
    - Font
---

* MacOS上系统字体路径一般为`/System/Library/Fonts/`，可以看到有ttc、ttf，有什么区别

  * `.ttf` (TrueType Font)

    - 单字体文件

    - 包含一整套字体（一个 font），包括 glyph 轮廓、metrics、cmap 等表。

    - 每个 `.ttf` 文件通常只对应一个 **字体样式**（例如 *Microsoft YaHei Regular*）。

    - 适合单独分发、安装。

  * `.ttc` (TrueType Collection)

    - 字体集合文件 (TrueType Collection)

    - 内部可以包含多个 TrueType 字体（多个 `.ttf` 打包在一起）。

    - 这些字体通常共享某些表（比如 glyph 轮廓、cmap），减少冗余，提高存储效率。

    - 常用于一个 typeface 的多个变体（Regular, Bold, Italic, Light…）。

* TrueType和OpenType的区别：简单说就是OpenType是TrueType的扩展

  * OpenType一般以otf为后缀，但也不能简单的根据文件名后缀区分二者，文件扩展名只是习惯，并不能完全说明内部格式。真正的区别要看字体表结构和 outline 格式


![TrueType vs OpenType](/Users/ping/Desktop/husteryp.github.io/img/post/Font/TrueType vs OpenType.png)

* Font里面有什么：可以归类metrics、advance width、ascent、descent等

如下是NewYork.ttf字体文件的内容：

![NewYork-ttf](/img/post/Font/NewYork-ttf.png)

分别解释下字体文件中的内容：

* GlyphOrder：glyphID与glyphName的映射

```
<GlyphOrder>
  <GlyphID id="0" name=".notdef"/>
  <GlyphID id="1" name=".null"/>
  <GlyphID id="2" name="nonmarkingreturn"/>
  <GlyphID id="3" name="space"/>
  <GlyphID id="4" name="A"/>
  ...
</GlyphOrder>
```

* head：Font Header，存储一些全局信息；关注几个值
  * unitsPerEm：可以发现，字体表里的数值一般都很大，其单位并不是像素值，而是 `em unit`，`<unitsPerEm value="2048"/>`表示`2048 units = 1 em = 设计的字高`，当字体在屏幕上以 16px 渲染时，1 em = 16px，其他数值可按比例换算

```
<head>
  <unitsPerEm value="2048"/>
  ...
</head>
```

* hhea：Horizontal Header，横向排版信息，关注几个值
  * ascent & descent：假设字体大小16，unitsPerEm如上为2048，则按比例换算：`ascent = 1950/2048 * 16 ≈ 15.2`，`descent ≈ 494/2048 * 16 ≈ 3.8`

```
<hhea>
	<!-- MacOS一般使用hhea里的ascent、descent；OS_2表里还有几个ascent、descent，一般在Windows或专业设计上使用 -->
  <ascent value="1950"/>
  <descent value="-494"/>
  <lineGap value="0"/>
  <advanceWidthMax value="2818"/>
  <minLeftSideBearing value="-693"/>
  <minRightSideBearing value="-693"/>
  ...
</hhea>
```

* maxp：字体里 glyph 的数量，以及一些最大值参数

```
<maxp>
  <numGlyphs value="1811"/>
  ...
</maxp>
```

* OS_2：参见[Apple文档](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6OS2.html)

```
<OS_2>
	<!-- 下标的大小和偏移 -->
  <ySubscriptXSize value="650"/>
  <ySubscriptYSize value="600"/>
  <ySubscriptXOffset value="0"/>
  <ySubscriptYOffset value="75"/>
  
  <!-- 上标的大小和偏移 -->
  <ySuperscriptXSize value="650"/>
  <ySuperscriptYSize value="600"/>
  <ySuperscriptXOffset value="0"/>
  <ySuperscriptYOffset value="350"/>

  <!-- 删除线的粗细和垂直位置 -->
  <yStrikeoutSize value="12"/>
  <yStrikeoutPosition value="620"/>

  <!-- 
  ulUnicodeRange表示字体支持的Unicode范围，用ulUnicodeRange1 … ulUnicodeRange4 这 4 个 32 位字段来表示，总共 128 个 bit，对应 128 个 Unicode Block，如果某 bit = 1，表示字体支持该区块中的至少一些字符
  映射表见：https://learn.microsoft.com/en-us/typography/opentype/spec/os2#ur
  Windows系统用 ulUnicodeRange 来挑选字体；
  macOS/iOS系统更依赖 cmap 表（精确的字符映射），ulUnicodeRange 只是附加信息；
  浏览器排版一般直接查 cmap，但 ulUnicodeRange 有时用于字体 fallback 策略；
  -->
  <ulUnicodeRange1 value="10100001 00000000 00000010 11111111"/>
  <ulUnicodeRange2 value="00000010 00000000 00100000 01011110"/>
  <ulUnicodeRange3 value="00000000 00000000 00000000 00000000"/>
  <ulUnicodeRange4 value="00000000 00000000 00000000 00000000"/>

  <!-- 专业排版（比如 InDesign）一般使用sTypoAscender、sTypoDescender -->
  <sTypoAscender value="1950"/>
  <sTypoDescender value="-494"/>
  <sTypoLineGap value="0"/>

  <!-- Windows一般使用sTypoAscender、sTypoDescender -->
  <usWinAscent value="1950"/>
  <usWinDescent value="494"/>
  ...
</OS_2>
```

* hmtx：Horizontal Metrics，记录每个 glyph 的 advance width 和left side bearing
  * 当排版引擎绘制一个字形时：
    1. 把字形放在当前点 + lsb 偏移位置。
    2. 画完后，将光标向右移动 `advanceWidth`，准备绘制下一个字形。

```
<hmtx>
  <mtx name=".notdef" width="2048" lsb="199"/>
  <mtx name=".null" width="0" lsb="0"/>
  <mtx name="A" width="1244" lsb="-16"/>
  ...
</hmtx>
```

* cmap：Character to Glyph Mapping，定义 Unicode code point → glyph ID 的映射

```
<cmap>
  <tableVersion version="0"/>
  <cmap_format_4 platformID="0" platEncID="3" language="0">
  	<!-- A的Unicode code point是0x41 -->
    <map code="0x41" name="A"/><!-- LATIN CAPITAL LETTER A -->
    <map code="0x42" name="B"/><!-- LATIN CAPITAL LETTER B -->
    <map code="0x43" name="C"/><!-- LATIN CAPITAL LETTER C -->
    <map code="0x44" name="D"/><!-- LATIN CAPITAL LETTER D -->
    <map code="0x45" name="E"/><!-- LATIN CAPITAL LETTER E -->
    <map code="0x46" name="F"/><!-- LATIN CAPITAL LETTER F -->
    <map code="0x47" name="G"/><!-- LATIN CAPITAL LETTER G -->
    <map code="0x48" name="H"/><!-- LATIN CAPITAL LETTER H -->
    ...
  </cmap_format_4>
  ...
</cmap>
```

* loca：Index to Location，记录每个 glyph 在 glyf 表中的偏移量。

* glyf：Glyph Data，真正的字形轮廓（矢量点、轮廓、控制点）；cmap 表负责把 Unicode 字符映射到 glyphID，而 glyf 表告诉渲染系统该 glyph 的具体形状

```
<glyf>
    <TTGlyph name="A" xMin="-16" yMin="0" xMax="1260" yMax="1444">
    <contour>
      <pt x="1086" y="213" on="1"/>
      <pt x="1113" y="137" on="0"/>
      <pt x="1161" y="50" on="0"/>
      <pt x="1219" y="9" on="0"/>
      <pt x="1260" y="1" on="1"/>
      <pt x="1260" y="0" on="1"/>
      <pt x="793" y="0" on="1"/>
      <pt x="793" y="1" on="1"/>
      <pt x="845" y="7" on="0"/>
      <pt x="897" y="54" on="0"/>
      <pt x="899" y="143" on="0"/>
      <pt x="874" y="213" on="1"/>
      <pt x="528" y="1200" on="1"/>
      <pt x="528" y="1200" on="1"/>
      <pt x="220" y="292" on="1"/>
      <pt x="184" y="186" on="0"/>
      <pt x="170" y="66" on="0"/>
      <pt x="224" y="11" on="0"/>
      <pt x="290" y="1" on="1"/>
      <pt x="290" y="0" on="1"/>
      <pt x="-16" y="0" on="1"/>
      <pt x="-16" y="1" on="1"/>
      <pt x="27" y="9" on="0"/>
      <pt x="89" y="59" on="0"/>
      <pt x="151" y="181" on="0"/>
      <pt x="193" y="297" on="1"/>
      <pt x="614" y="1444" on="1"/>
      <pt x="648" y="1444" on="1"/>
    </contour>
    <contour>
      <pt x="290" y="532" on="1"/>
      <pt x="294" y="544" on="1"/>
      <pt x="859" y="544" on="1"/>
      <pt x="860" y="532" on="1"/>
    </contour>
    <instructions/>
  </TTGlyph>
  ...
</glyf>
```

* name：字体名称、子家族、版本、版权、厂商信息等字符串。

* post：PostScript，与 PostScript 兼容的信息，比如 italic angle、underline position、glyph 名称表。

**GDEF** (Glyph Definition Table)

- OpenType Layout 表之一，标记 glyph 类别（基字、附加字、标点等）。

```
字符 → cmap → glyph
            ↓
           GDEF（分类/属性）
            ↓
           GSUB（替换字形，例如连字）
            ↓
           GPOS（调整位置，例如 kerning、mark 对齐）
            ↓
        绘制 glyph（glyf 表）
```

**GPOS** (Glyph Positioning Table)

- OpenType Layout 表之一，定义字形间的精细位置调整（如 kerning、上下标偏移）。

**GSUB** (Glyph Substitution Table)

- OpenType Layout 表之一，定义字形替换规则（连字、上下文替换，拉丁/阿拉伯变体）。

**HVAR** (Horizontal Variations)

- 可变字体表，用于调整字宽的变化（横向）。

**MVAR** (Metrics Variations)

- 可变字体表，支持字度量参数（ascender、descender 等）的变化。

**STAT** (Style Attributes Table)

- OpenType Variable Font 的样式坐标信息（比如 Weight=400, Width=100）。

**avar** (Axis Variations)

- Variable Font 表，调整 variation axis 的映射关系（非线性调节）。

**fvar** (Font Variations)

- Variable Font 的主要定义，列出轴（Axis，比如 Weight, Width, Optical Size）和实例（Regular, Bold…）。

**gvar** (Glyph Variations)

- Variable Font 的关键表，定义 glyph 在不同轴下如何变形。



* 疑问：同一个字体中ascent、descent都相同吗？因为都是和Font中最高/低glyph做比较（或者这个描述对吗）
* 为什么descent有时候是负数？

* 层级关系图

![img](https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/Art/text_kit_arch_2x.png)

* CoreText的层级
  * glyph run：包含一组连续的有相同样式和方向的glyph

![img](https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/Art/core_text_arch_2x.png)

* CTFont：可以用于查询：character-to-glyph mapping, its encoding, glyph data, and metrics such as ascent, leading,
* font cascading：字体级联；Core Text 还提供了一种称为字体级联的自动字体替换机制。
  * 字体级联基于级联列表（cascade lists），级联列表是一组有序的font descriptors数组；系统有一个默认的级联列表，根据用户当前的语言设置和font设置而不同
  * [CTFontCreateForString](https://developer.apple.com/documentation/coretext/1509506-ctfontcreateforstring)使用了级联列表，可以逆向看下
* 可以逆向下实现

```swift
class func preferredFont(forTextStyle style: UIFont.TextStyle) -> UIFont
```

# 参考

* https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/Introduction/Introduction.html#//apple_ref/doc/uid/TP40009542-CH1-SW1
* https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/Introduction/Introduction.html#//apple_ref/doc/uid/TP40010156-CH1-SW1
* https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/Introduction/Introduction.html#//apple_ref/doc/uid/TP40010156-CH1-SW1
