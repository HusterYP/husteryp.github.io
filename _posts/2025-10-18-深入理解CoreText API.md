---
layout:     post
title:      "深入理解iOS CoreText API"
subtitle:   "iOS自定义富文本渲染基础篇"
date:       2025-10-18
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - 跨端渲染
    - 富文本
---

这篇文章是从0到1自定义富文本渲染的原理篇之一，此外你还可能感兴趣：

* [一文读懂字符与编码](https://mp.weixin.qq.com/s/EYPO3sSjtIstD3RmlRCs9w)
* [一文读懂字符、字形、字体](https://mp.weixin.qq.com/s/96YJGYKLoxENC4qT9tYNoQ)
* [一文读懂字体文件](https://mp.weixin.qq.com/s/D0A8HAQaQNart7KAdWXyJg)
* [从0到1自定义文字排版引擎：原理篇](https://mp.weixin.qq.com/s/fcL6if52qYQUTChEjntHJg)
* [逆向分析CoreText中的字体级联/Font Fallback机制](https://mp.weixin.qq.com/s/EpaNjLcG6DZBc128A2gdIQ)
* [新手小白也能看懂的LLDB技巧/逆向技巧](https://mp.weixin.qq.com/s/1oOSJkTIJ8njV49B6PsfgA)

更多内容可订阅公众号「非专业程序员Ping」，文中所有代码可在公众号后台回复 “CoreText” 获取。

# 一、引言

CoreText是iOS/macOS中的文字排版引擎，提供了一系列对文本精确操作的API；UIKit中UILabel、UITextView等文本组件底层都是基于CoreText的，可以看官方提供的层级图：

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=NzEzNDNiNmRiMWNjNTA1OTgzOWE0ZDZjMjgxNmUyODlfdTZzbzZMZGk3U0dRRG9UQ0lNTjI1QUJ2SDNpcGJxeXhfVG9rZW46Q1RrY2JYeDJQb0NEM3N4QmxxMGNVcVVxbjRmXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

本文的目的是结合实际使用例子，来介绍和总结CoreText中的重要概念和API。

# 二、重要概念

CoreText中有几个重要概念：CTTypesetter、CTFramesetter、CTFrame、CTLine、CTRun；它们之间的关系可以看官方提供的层级图：

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=MGJhNmI2NDlmZDU0ODM2YTNlZDU4MjQ2YzM5MjkyZWJfZzFWV2tjY0tKdW5nSWQxWnZZUHF5TUhkbkY1SGl0RVNfVG9rZW46WE5tSWJYTDhVbzc1M3J4RnRwdmNCUlczbnRjXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

一篇文档可以分为：文档 -> 段落 -> 段落中的行 -> 行中的文字，类似的，CoreText也是按这个结构来组织和管理API的，我们也可以根据诉求来选择不同层级的API。

## 2.1 CTFramesetter

CTFramesetter类似于文档的概念，它负责将多段文本进行排版，管理多个段落（CTFrame）。

CTFramesetter的输入是属性字符串（NSAttributedString）和路径（CGPath），负责将文本在指定路径上进行排版。

## 2.2 CTFrame

CTFrame类似于段落的概念，其中包含了若干行（CTLine）以及对应行的位置、方向、行间距等信息。

## 2.3 CTLine

CTLine类似于行的概念，其中包含了若干个字形（CTRun）以及对应字形的位置等信息。

## 2.4 CTRun

需要注意CTRun不是单个的字符，而是**一段连续的且具有相同属性（字体、颜色等）的字形（Glyph）。**

如下，每个虚线框都代表一个CTRun：

![CTRun](/img/post/深入理解CoreText/CTRun.png)

## 2.5 CTTypesetter

CTTypesetter支持对属性字符串进行换行，可以通过CTTypesetter来自定义换行（比如按word换行、按char换行等）或控制每行的内容，可以理解成更精细化的控制。

# 三、重要API

## 3.1 CTFramesetter

**1）CTFramesetterCreateWithAttributedString**

```Swift
func CTFramesetterCreateWithAttributedString(_ attrString: CFAttributedString) -> CTFramesetter
```

通过属性字符串来创建CTFramesetter。

我们可以构造不同字体、颜色、大小的属性字符串，然后从属性字符串构造CTFramesetter，之后可以继续往下拆分得到段落、行、字形等信息，这样可以实现自定义排版、图文混排等复杂富文本样式。

**2）CTFramesetterCreateWithTypesetter**

```Swift
func CTFramesetterCreateWithTypesetter(_ typesetter: CTTypesetter) -> CTFramesetter
```

通过CTTypesetter来创建CTFramesetter，当我们需要对文本实现更精细控制，比如自定义换行时，可以自己构造CTTypesetter。

**3）CTFramesetterCreateFrame**

```Swift
func CTFramesetterCreateFrame(
    _ framesetter: CTFramesetter,
    _ stringRange: CFRange,
    _ path: CGPath,
    _ frameAttributes: CFDictionary?
) -> CTFrame
```

生成CTFrame：在指定路径（path）为属性字符串的指定范围（stringRange）生成CTFrame。

* `framesetter`
* `stringRange`：字符范围，注意需要以UTF-16编码格式计算；当 stringRange.length = 0 时，表示从起点（stringRange.location）到字符结束为止；比如当 CFRangeMake(0, 0) 表示全字符范围
* `path`：排版路径，可以是不规则矩形，这意味着可以传入不规则图形来实现文字环绕等高级效果
* `frameAttributes`：一个可选的字典，可以用于控制段落级别的布局行为，比如行间距等，一般用不到，可传 nil

**4）CTFramesetterSuggestFrameSizeWithConstraints**

```Swift
func CTFramesetterSuggestFrameSizeWithConstraints(
    _ framesetter: CTFramesetter,
    _ stringRange: CFRange,
    _ frameAttributes: CFDictionary?,
    _ constraints: CGSize,
    _ fitRange: UnsafeMutablePointer<CFRange>?
) -> CGSize
```

计算文本宽高：在给定约束尺寸（constraints）下计算文本范围（stringRange）的实际宽高。

如下，我们可以计算出在宽高 100 x 100 的范围内排版，实际能放下的文本范围（fitRange）以及实际的文本尺寸：

```Swift
let attr = NSAttributedString(string: "这是一段测试文本，通过调用CTFramesetterSuggestFrameSizeWithConstraints来计算文本的宽高信息，并返回实际的range", attributes: [
    .font: UIFont.systemFont(ofSize: 16),
    .foregroundColor: UIColor.black
])
let framesetter = CTFramesetterCreateWithAttributedString(attr)
var fitRange = CFRange(location: 0, length: 0)
let size = CTFramesetterSuggestFrameSizeWithConstraints(
    framesetter,
    CFRangeMake(0, 0),
    nil,
    CGSize(width: 100, height: 100),
    &fitRange
)
print(size, fitRange, attr.length)
```

这个API在分页时非常有用，比如微信读书的翻页效果，需要知道在哪个地方截断，PDF的分页排版等。

### 3.1.1 CTFramesetter使用示例

**1）实现一个支持AutoLayout且高度靠内容撑开的富文本View**

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=Mzc4YmRjMzQxZTdhM2ZmZDYxODIxYTRkNjUyZDU1ZGRfV2hMUHBaTk8yZ1o4RnlZZFNreWw3c1lIVEtQSHVkTnBfVG9rZW46RmNrN2JkOFlXb3dmaHV4bllHNmNwdmpqblFlXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

**2）在圆形路径中绘制文本**

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=M2I0NzA4ODA4OGUzOTAxMmYyNGQ4MjM0NzFiMDg4YmZfOGdRdVA4aUk5UUNvZ3FpclIzSlY5SVNuaHNzdXVpODlfVG9rZW46TzFiOWJzQlRUb1FuVmZ4cjhBNWNIZzl4blR0XzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

**3）文本分页：模拟微信读书的分页逻辑**

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=YTJlZGY5YjRkNjIxNDVkMzgxMGY5YWE5NjJkNGQ3OTdfa3hTYzNwZTV2UWx3bENCTWpLMHZodHdFckFxRUU0TThfVG9rZW46RXBNeWI4UGw4b0Y4dGp4UGVhQ2N0VE0ybkhkXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

## 3.2 CTFrame

**1）CTFramesetterCreateFrame**

```Swift
func CTFramesetterCreateFrame(
    _ framesetter: CTFramesetter,
    _ stringRange: CFRange,
    _ path: CGPath,
    _ frameAttributes: CFDictionary?
) -> CTFrame
```

创建CTFrame，在CTFramesetter一节中有介绍过，这是创建CTFrame的唯一方式。

**2）CTFrameGetStringRange**

```Swift
func CTFrameGetStringRange(_ frame: CTFrame) -> CFRange
```

获取CTFrame包含的字符范围。

我们在调用CTFramesetterCreateFrame创建CTFrame时，会传入一个 stringRange 的参数，CTFrameGetStringRange也可以理解成获取这个 stringRange，区别是处理了当 stringRange.length 为0的情况。

**3）CTFrameGetVisibleStringRange**

```Swift
func CTFrameGetVisibleStringRange(_ frame: CTFrame) -> CFRange
```

获取CTFrame实际可见的字符范围。

我们在调用CTFramesetterCreateFrame创建CTFrame时，会传入path，可能会把字符截断，CTFrameGetVisibleStringRange返回的就是可见的字符范围。

需要注意和CTFrameGetStringRange进行区分，可以用如下Demo验证：

```Swift
let longText = String(repeating: "这是一个分栏布局的例子。Core Text 允许我们将一个长的属性字符串（CFAttributedString）流动到多个不同的路径（CGPath）中。我们只需要创建一个 CTFramesetter，然后循环调用 CTFramesetterCreateFrame。每次调用后，我们使用 CTFrameGetStringRange 来找出有多少文本被排入了当前的框架，然后将下一个框架的起始索引设置为这个范围的末尾。 ", count: 10)
let attributedText = NSAttributedString(string: longText, attributes: [
    .font: UIFont.systemFont(ofSize: 12),
    .foregroundColor: UIColor.darkText
])
let framesetter = CTFramesetterCreateWithAttributedString(attributedText as CFAttributedString)
let path = CGPath(rect: .init(x: 10, y: 100, width: 400, height: 200), transform: nil)
let frame = CTFramesetterCreateFrame(
    framesetter,
    CFRange(location: 100, length: 0),
    path,
    nil
)
// 输出：CFRange(location: 100, length: 1980)
print(CTFrameGetStringRange(frame))
// 输出：CFRange(location: 100, length: 584)
print(CTFrameGetVisibleStringRange(frame))
```

**4）CTFrameGetPath**

```Swift
func CTFrameGetPath(_ frame: CTFrame) -> CGPath
```

获取创建CTFrame时传入的path。

**5）CTFrameGetLines**

```Swift
func CTFrameGetLines(_ frame: CTFrame) -> CFArray
```

获取CTFrame中所有的行（CTLine）。

**6）CTFrameGetLineOrigins**

```Swift
func CTFrameGetLineOrigins(
    _ frame: CTFrame,
    _ range: CFRange,
    _ origins: UnsafeMutablePointer<CGPoint>
)
```

获取每一行的起点坐标。

用法示例：

```Swift
let lines = CTFrameGetLines(frame) as! [CTLine]
var origins = [CGPoint](repeating: .zero, count: lines.count)
CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)
```

**7）CTFrameDraw**

```Swift
func CTFrameDraw(
    _ frame: CTFrame,
    _ context: CGContext
)
```

绘制CTFrame。

### 3.2.1 CTFrame使用示例

**1）绘制CTFrame**

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=Yzc3YzE1YTFmZjJiOGY5NjE3ZGY2YWI2ZTVhMWE1ZmVfVUtqQVB3eEU3QWtsQ3JlcWJ2VDFwOXRFZkViQ2FHV0ZfVG9rZW46TXhlM2J0T0Nlb3NPTTJ4MWpuaGN2R0ZNbnhjXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

**2）高亮某一行**

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=OGY4MzMxMjYxYWE4NTdjYzcyMDZiNjc2OGE0MzBjZjRfQzExaE44ZzNjaG8wRmtaeGZIcnJ1QmNWYWJ4WldtbGtfVG9rZW46U0FZQ2JXTXhBb2JNWDd4eDVGZmN0Rk5zbmlnXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

**3）检测点击字符**

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=MzFkZGU0MjBkMmUxMjg5NDRjZTJlM2E2MDdhOWZiYjdfRmttZVJyNXJIUkdWblZpQjRESlFzd2VPYVE4bmlXd3VfVG9rZW46U0JvRmJpRzhyb1h4RGF4dHNaaWNraTdjbmpoXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

## 3.3 CTLine

**1）CTLineCreateWithAttributedString**

```Swift
func CTLineCreateWithAttributedString(_ attrString: CFAttributedString) -> CTLine
```

从属性字符串创建**单行**CTLine，如果字符串中有换行符（\\n）的话，换行符会被转换成空格，如下：

```Swift
let line = CTLineCreateWithAttributedString(
    NSAttributedString(string: "Hello CoreText\nWorld", attributes: [.font: UIFont.systemFont(ofSize: 16)])
)
```

**2）CTLineCreateTruncatedLine**

```Swift
func CTLineCreateTruncatedLine(
    _ line: CTLine,
    _ width: Double,
    _ truncationType: CTLineTruncationType,
    _ truncationToken: CTLine?
) -> CTLine?
```

创建一个被截断的新行。

* `line`：待截断的行
* `width`：在多少宽度截断
* `truncationType`：start/end/middle，截断类型
* truncationToken：在截断处添加的字符，nil表示不添加，一般使用省略符（...）

```Swift
let truncationToken = CTLineCreateWithAttributedString(
    NSAttributedString(string: "…", attributes: [.font: UIFont.systemFont(ofSize: 16)])
)
let truncated = CTLineCreateTruncatedLine(line, 100, .end, truncationToken)
```

**3）CTLineCreateJustifiedLine**

```Swift
func CTLineCreateJustifiedLine(
    _ line: CTLine,
    _ justificationFactor: CGFloat,
    _ justificationWidth: Double
) -> CTLine?
```

创建一个两端对齐的新行，类似书籍或报纸中两端对齐的排版效果。

* `line`：原始行
* `justificationFactor`：`justificationFactor <= 0`表示不缩放，即与原始行相同；`justificationFactor >= 1`表示完全缩放到指定宽度；`0 < justificationFactor < 1`表示部分缩放到指定宽度，可以看示例代码
* `justificationWidth`：缩放指定宽度

示例：

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=ZTYwMGVkMjhkY2YzOWQ3ZTg3ZDc4OTNlYzQ5YmFjNWNfMXpWbGNJcDFRakk4bmVJNjJOa1dEWXFlU2RkZGpaNnpfVG9rZW46T1dPbmJ4bHZPb3NCZEJ4VkExZ2MxWjVZbjhiXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

**4）CTLineDraw**

```Swift
func CTLineDraw(
    _ line: CTLine,
    _ context: CGContext
)
```

绘制行。

**5）CTLineGetGlyphCount**

```Swift
func CTLineGetGlyphCount(_ line: CTLine) -> CFIndex
```

获取行内字形总数。

**6）CTLineGetGlyphRuns**

```Swift
func CTLineGetGlyphRuns(_ line: CTLine) -> CFArray
```

获取行内所有的CTRun。

**7）CTLineGetStringRange**

```Swift
func CTLineGetStringRange(_ line: CTLine) -> CFRange
```

获取该行对应的字符范围。

**8）CTLineGetPenOffsetForFlush**

```Swift
func CTLineGetPenOffsetForFlush(
    _ line: CTLine,
    _ flushFactor: CGFloat,
    _ flushWidth: Double
) -> Double
```

获取在指定宽度绘制时的水平偏移，一般配合 CGContext.textPosition 使用，可用于实现在固定宽度下文本的左对齐、右对齐、居中对齐及自定义水平偏移等。

示例：

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=MjdkYjRmN2VhZDljNzlkOGJlM2YwOTE2MjY0ZjYwZjZfUnA3UEpkUFFDWUlUajdRRkp1d0NEd1lBejBMTnVRSk5fVG9rZW46RmFQSGJ6UG9wb1lSckt4WUg3V2N3WjhvbndlXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

**9）CTLineGetImageBounds**

```Swift
func CTLineGetImageBounds(
    _ line: CTLine,
    _ context: CGContext?
) -> CGRect
```

获取行的**视觉边界**；注意 CTLineGetImageBounds 获取的是**相对于CTLine局部坐标系的矩形**，即以textPosition为原点的矩形。

视觉边界可以看下面的例子，与之相对的是布局边界；这个API在实际应用中不常见，除非有特殊诉求，比如要检测精确的内容点击范围，给行绘制紧贴背景等。

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=MTliN2NkOGE4NzRmZjE2NDY4YzNmZGM0YTc3NzUxM2VfQmFXUWNycVhUekY5TzE5aFAzOHl3UjE0RWVCY0NlWVVfVG9rZW46RWVZaWJ0Vkgzb09FRld4bktIN2NGYkZxbkZkXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

**10）CTLineGetTypographicBounds**

```Swift
func CTLineGetTypographicBounds(
    _ line: CTLine,
    _ ascent: UnsafeMutablePointer<CGFloat>?,
    _ descent: UnsafeMutablePointer<CGFloat>?,
    _ leading: UnsafeMutablePointer<CGFloat>?
) -> Double
```

获取上行（ascent）、下行（descent）、行距（leading）。

这几个概念不熟悉的可以参考：[一文读懂字符、字形、字体](https://mp.weixin.qq.com/s/96YJGYKLoxENC4qT9tYNoQ)

想了解这几个数值最终是从哪个地方读取的可以参考：[一文读懂字体文件](https://mp.weixin.qq.com/s/D0A8HAQaQNart7KAdWXyJg)

通过这个API我们可以手动构造**布局边界**（见上面的例子），一般用于点击检测、绘制行背景等。

**11）CTLineGetTrailingWhitespaceWidth**

```Swift
func CTLineGetTrailingWhitespaceWidth(_ line: CTLine) -> Double
```

获取行尾空白字符的宽度（比如空格、制表符 (\\t) 等），一般用于实现对齐时基于可见文本对齐等。

示例：

```Swift
let line = CTLineCreateWithAttributedString(
    NSAttributedString(string: "Hello  ", attributes: [.font: UIFont.systemFont(ofSize: 16)])
)

let totalWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
let trailingWidth = CTLineGetTrailingWhitespaceWidth(line)

print("总宽度: \(totalWidth)")
print("尾部空白宽度: \(trailingWidth)")
print("可见文字宽度: \(totalWidth - trailingWidth)")
```

**12）CTLineGetStringIndexForPosition**

```Swift
func CTLineGetStringIndexForPosition(
    _ line: CTLine,
    _ position: CGPoint
) -> CFIndex
```

获取给定位置处的字符串索引。

**注意：**虽然官方文档说这个API一般用于点击检测，但实际测试下来**这个API返回的点击索引不准确**，比如虽然点击的是当前字符，但实际返回的索引是后一个字符的，如下：

![CTLineGetStringIndexForPosition](/img/post/深入理解CoreText/CTLineGetStringIndexForPosition.png)

查了下，发现这个API一般是用于计算光标位置的，比如点击「行」的左半部分，希望光标出现在「行」左侧，如果点击「行」的右半部分，希望光标出现在「行」的右侧。

如果我们想精确做字符的点击检测，推荐使用字符/行的bounds来计算，参考「CTFrame使用示例-3」例子。

**13）CTLineGetOffsetForStringIndex**

```Swift
func CTLineGetOffsetForStringIndex(
    _ line: CTLine,
    _ charIndex: CFIndex,
    _ secondaryOffset: UnsafeMutablePointer<CGFloat>?
) -> CGFloat
```

获取指定字符索引相对于行的 x 轴偏移量。

* `line`：待查询的行
* `charIndex`：要查询的字符在**原始属性字符串**中的索引
* `secondaryOffset`：次要偏移值，在简单的LTR文本中，可以忽略（传nil即可），但在复杂的双向文本（BiDi）中会用到

使用场景：

* 字符点击检测：见「CTFrame使用示例-3」例子
* 给某段字符绘制高亮和下划线
* 定位某个字符：比如想在一段文本中的某个字符上方显示弹窗，可以用这个API先定位该字符

**14）CTLineEnumerateCaretOffsets**

```Swift
func CTLineEnumerateCaretOffsets(
    _ line: CTLine,
    _ block: @escaping (Double, CFIndex, Bool, UnsafeMutablePointer<Bool>) -> Void
)
```

遍历一行中光标所有的有效位置。

* `line`
* `block`
  * Double：offset，相对于行的 x 轴偏移
  * CFIndex：与此光标位置相关的字符串索引
  * Bool：true 表示光标位于字符的前边（在 LTR 中即左侧），false 表示光标位于字符的后边（在 LTR 中即右侧）；在 BiDi 中需要特殊同一个字符可能会回调两次（比如 BiDi 边界的地方），需要用这个值区分前后
  * UnsafeMutablePointer<Bool>：stop 指针，赋值为 true 会停止遍历

使用场景：

* 绘制光标：富文本选区或者文本编辑器中，要绘制光标时，可以先通过 CTLineGetStringIndexForPosition 获取字符索引，再通过这个函数或者 CTLineGetOffsetForStringIndex 获取光标偏移
* 实现光标的左右键移动：可以用这个API将所有的光标位置存储到数组，并按offset排序，当用户按下右箭头 -> 时，可以找到当前光标index，将index + 1即是下一个光标位置

### 3.3.1 CTLine使用示例

除了上面例子，再举一个：

**1）高亮特定字符**

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=MjJjMWYyZjU4MDFlMzY2ZDIxNGQ2MTgxYWQ5MDgwNThfZDI2VzA4WnRETlZ4Ym1hVXIxT1BBc3RoSUZ5ZUV6ck1fVG9rZW46QzlPOGJZRkYzb0NKdFh4NEcweWNudlZybktkXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

## 3.4 CTRun

CTRun相关API比较基础，这里主要介绍常用的。

**1）CTLineGetGlyphRuns**

```Swift
func CTLineGetGlyphRuns(_ line: CTLine) -> CFArray
```

获取CTRun的**唯一**方式。

**2）CTRunGetAttributes**

```Swift
func CTRunGetAttributes(_ run: CTRun) -> CFDictionary
```

获取CTRun的属性；比如想知道这个CTRun是不是粗体，是不是链接，是不是目标Run等，都可以通过这个API。

示例：

```Swift
guard let attributes = CTRunGetAttributes(run) as? [NSAttributedString.Key: Any] else { continue }
// 现在你可以检查属性
if let color = attributes[.foregroundColor] as? UIColor {
    // ...
}
if let font = attributes[.font] as? UIFont {
    // ...
}
if let link = attributes[NSAttributedString.Key("my_custom_link_key")] {
    // 这就是那个可点击的 run！
}
```

**3）CTRunGetStringRange**

```Swift
func CTRunGetStringRange(_ run: CTRun) -> CFRange
```

获取CTRun对应于原始属性字符串的哪个范围。

**4）CTRunGetTypographicBounds**

```Swift
func CTRunGetTypographicBounds(
    _ run: CTRun,
    _ range: CFRange,
    _ ascent: UnsafeMutablePointer<CGFloat>?,
    _ descent: UnsafeMutablePointer<CGFloat>?,
    _ leading: UnsafeMutablePointer<CGFloat>?
) -> Double
```

获取CTRun的度量信息，同上面许多API一样，当 range.length 为0时表示直到CTRun文本末尾。

**5）CTRunGetPositions**

```Swift
func CTRunGetPositions(
    _ run: CTRun,
    _ range: CFRange,
    _ buffer: UnsafeMutablePointer<CGPoint>
)
```

获取CTRun中每一个字形的位置，注意这里的位置是**相对于CTLine原点**的。

**6）CTRunDelegate**

CTRunDelegate允许为属性字符串中的一段文本提供自定义布局测量信息，一般用于在文本中插入图片、自定义View等非文本元素。

比如在文本中间插入图片：

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=YmI5MzViNjczMjVlNDQ1ZDYwN2E3MDI0YTMyM2YxZDhfTlNJNmV4aGJtZloydTJPSWlYTUUwZ3NadkZ0NnNDcktfVG9rZW46R3JsM2JUUXZTb3ZNVm14SHV5dGNtZWhKblhjXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

### 3.4.1 CTRun使用示例

**1）基础绘制**

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=MTAwM2RiN2M2YTBiZjBkOGU0OWYxM2U0NjE4ZmQyNzRfMEZMUllNV05Ob3NHdzFuTW9jNGxnRE0zNzFRNHdIakRfVG9rZW46QW1XM2JaVzVwb25qUHB4cVh0MGNQamZGbmFjXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

**2）链接点击识别**

![](https://lk9v5zgfb4.feishu.cn/space/api/box/stream/download/asynccode/?code=M2FkMGE5MzBhODAyNWMwNmE4NzFiYTM5NjE3ZDJlYWJfY0tIY1J2NEZicklpbERGTU9hNkNYd0N0VTFrS1hKUGxfVG9rZW46WDlUcGJjRDdyb0d3T1F4UndjQWNOYzRFbnNkXzE3NjA4Nzc2MjY6MTc2MDg4MTIyNl9WNA)

## 3.5 CTTypesetter

CTFramesetter会自动处理换行，当我们想手动控制换行时，可以用CTTypesetter。

**1）CTTypesetterSuggestLineBreak**

```Swift
func CTTypesetterSuggestLineBreak(
    _ typesetter: CTTypesetter,
    _ startIndex: CFIndex,
    _ width: Double
) -> CFIndex
```

按单词（word）换行。

如下示例，输出：`Try word `和`wrapping`

```Swift
let attrStringWith = NSAttributedString(string: "Try word wrapping", attributes: [.font: UIFont.systemFont(ofSize: 18)])
let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
let totalLength = attributedString.length // UTF-16 长度
var startIndex = 0
var lineCount = 1

while startIndex < totalLength {
    let charCount = CTTypesetterSuggestLineBreak(typesetter, startIndex, 100)
    // 如果返回 0，意味着一个字符都放不下（或已结束）
    if charCount == 0 {
        if startIndex < totalLength {
            print("Line \(lineCount): (Error) 无法放下剩余字符。")
        }
        break
    }
    // 获取这一行的子字符串
    let range = NSRange(location: startIndex, length: charCount)
    let lineString = (attributedString.string as NSString).substring(with: range)
    print("Line \(lineCount): '\(lineString)' (UTF-16 字符数: \(charCount))")
    // 更新下一次循环的起始索引
    startIndex += charCount
    lineCount += 1
}
```

**2）CTTypesetterSuggestClusterBreak**

```Swift
func CTTypesetterSuggestClusterBreak(
    _ typesetter: CTTypesetter,
    _ startIndex: CFIndex,
    _ width: Double
) -> CFIndex
```

按字符（char）换行。

如下示例，输出：`Try word wr`和`apping`

```Swift
let attrStringWith = NSAttributedString(string: "Try word wrapping", attributes: [.font: UIFont.systemFont(ofSize: 18)])
let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
let totalLength = attributedString.length // UTF-16 长度
var startIndex = 0
var lineCount = 1

while startIndex < totalLength {
    let charCount = CTTypesetterSuggestClusterBreak(typesetter, startIndex, 100)
    // 如果返回 0，意味着一个字符都放不下（或已结束）
    if charCount == 0 {
        if startIndex < totalLength {
            print("Line \(lineCount): (Error) 无法放下剩余字符。")
        }
        break
    }
    // 获取这一行的子字符串
    let range = NSRange(location: startIndex, length: charCount)
    let lineString = (attributedString.string as NSString).substring(with: range)
    print("Line \(lineCount): '\(lineString)' (UTF-16 字符数: \(charCount))")
    // 更新下一次循环的起始索引
    startIndex += charCount
    lineCount += 1
}
```

# 四、总结

以上是CoreText中常用的API及其场景代码举例，完整示例代码可在公众号「非专业程序员Ping」回复 “CoreText” 获取。
