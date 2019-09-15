---
layout:     post
title:      "WebView与JS交互的几种方式[Swift版]"
subtitle:   "从小程序的角度出发"
date:       2019-06-12
author:     "袁平"
header-img: "img/tag-bg.jpg"
tags:
    - iOS
---

# 前言

总结`iOS`中`JS`与`Native`交互的几种方式：
1. 拦截`Url`：适用于`UIWebView`和`WKWebView`
2. `JavaScriptCore`：只适用于`UIWebView`（`iOS7+`）
3. `WKScriptMessageHandler`：只适用于`WKWebView`（`iOS8+`）
4. `WebViewJavascriptBridge`：适用于`UIWebView`和`WKWebView`（属于第三方框架）

小程序本质上也就是运行在`WebView`中的`H5`页面，通过`JS`与`Native`之间的相互通信，实现逻辑层与渲染层的分离，提供比普通`H5`更好的体验

文中代码详见：https://github.com/HusterYP/iOS_JS_To_Native

------------

# 正文

------------

## 一. 拦截Url
> 适用于`UIWebView`和`WKWebView`，以`WKWebView`为例

`JS`与`Native`约定好协议，`Native`实现相应的代理方法拦截请求，如果是约定好的协议，则进行`Native`的响应；这种方式比较简单，但是当
需要传递参数增多时，会出现协议过长的问题

在`WKWebView`中，`H5`发出请求会经过代理`WKNavigationDelegate`进行拦截，可通过在代理方法`webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;`中处理；如果检测到是实现约定好的`scheme`，则进行`Native`拦截处理，而不进行响应

若约定以`wxlocal://`开头的`url`为协议

### 1.1 JS发送消息给Native

`JS`代码如下：
```
function sendMsg() {
   var content=document.getElementById("content").value            
   location.href="wxlocal://base.com?content="+content // 重点在这里
}
```

`Native`需要实现`WKWebView`的`WKNavigationDelegate`代理，进行`url`拦截：
```
webView.navigationDelegate = self
extension BlockUrlController: WKNavigationDelegate {
    // 拦截请求
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString
        guard let urlStr = url else { return }
        // 如果不是以约定好的协议，则交给WebView处理
        if !urlStr.hasPrefix("wxlocal://") {
            decisionHandler(.allow)
        } else {
            // 如果是约定好的协议，则进行参数解析，交给Native响应，取消WebView的响应
            decisionHandler(.cancel)
            AlertUtil.shared.alert(title: "JS To Native", msg: urlStr)
        }
    }
}
```


### 1.2 Native发送消息给JS

`Native`发送给`JS`则使用



-------------

## 参考

1. https://blog.csdn.net/dolacmeng/article/details/79623708





难点是处理各种回调

其中 WebViewJavascriptBridge && WKWebViewJavascriptBridge 作为接口层主要负责提供方便的接口，隐藏实现细节，其实现细节都是通过实现层 WebViewJavascriptBridgeBase 去做的，而 WebViewJavascriptBridge_JS 作为 JS 层其实存储了一段 JS 代码，在需要的时候注入到当前 WebView 组件中，最终实现 Native 与 JS 的交互

WebViewJavascriptBridge 的实现原理上是利用假 Request 方法实现的，所以需要监听 WebView 组件的代理方法获取加载之前的 Request.URL 并做处理

假 Request 的发起有两种方式，-1:location.href -2:iframe。通过 location.href 有个问题，就是如果 JS 多次调用原生的方法也就是 location.href 的值多次变化，Native 端只能接受到最后一次请求，前面的请求会被忽略掉，所以这里 WebViewJavascriptBridge 选择使用 iframe，后面不再解释。
