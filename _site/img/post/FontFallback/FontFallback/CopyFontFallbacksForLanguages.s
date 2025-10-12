/**
 * CoreText 字体回退 - 为多种语言复制字体回退列表函数
 * 函数名: TFontFallbacks::CopyFontFallbacksForLanguages
 * 功能: 为多个语言代码复制相应的字体回退列表
 * 
 * 参数:
 *   a1 (__int64): 字体描述符对象指针
 *   a2 (__int64): 主要语言代码字符串指针
 *   a3 (__int64): 语言代码数组指针 (CFArrayRef)
 *   a4 (__int64): 输出参数指针，用于接收生成的字体回退数组
 * 
 * 返回值:
 *   __int64: 操作结果
 */
__int64 __usercall TFontFallbacks::CopyFontFallbacksForLanguages@<X0>(__int64 a1@<X0>, __int64 a2@<X1>, __int64 a3@<X2>, __int64 a4@<X8>)
{
  __CFString *v4; // 主要语言代码字符串
  __int64 v5; // 语言代码数组指针
  __int64 v6; // 有效的语言代码数组
  __int64 v7; // 系统有序语言数组
  __int64 v8; // 系统有序语言数组长度
  __int64 v10; // 输入语言数组长度
  __int64 v11; // 循环计数器上限
  __int64 v12; // 循环计数器
  __int64 v14; // 当前语言代码
  __int64 v21; // 规范化的语言代码
  _QWORD *v24; // 输出参数指针
  __int64 v25; // 字体描述符对象指针
  __int64 v26; // 栈变量 [xsp+18h] [xbp-58h]

  // 保存参数
  v4 = (__CFString *)a2;  // 主要语言代码
  v24 = (_QWORD *)a4;     // 输出参数指针
  v25 = a1;               // 字体描述符对象
  
  // 如果没有提供语言数组，直接调用单语言版本
  if ( !a3 )
    return TFontFallbacks::CopyFontFallbacks((_QWORD *)a4, a1, (__CFString *)a2, 0LL, 0LL);
    
  v5 = a3;  // 语言代码数组
  
  // 创建可变数组用于存储有效的语言代码
  v6 = CFArrayCreateMutable(*(_QWORD *)kCFAllocatorDefault_ptr, 0LL, kCFTypeArrayCallBacks_ptr);
  
  // 确保系统有序语言数组已初始化 (使用 dispatch_once 确保只初始化一次)
  if ( qword_229B28 != -1 )
    dispatch_once_f(&qword_229B28, 0LL, (dispatch_function_t)GetOrderedLanguages(void)::$_0::__invoke);
    
  // 获取系统有序语言数组
  v7 = qword_229B20;
  if ( qword_229B20 )
    v8 = CFArrayGetCount(qword_229B20);
  else
    v8 = 0LL;
    
  // 获取输入语言数组的长度
  v10 = CFArrayGetCount(v5);
  if ( v10 )
  {
    v11 = v10;
    v12 = 0LL;
    _X22 = &v26;
    
    // 遍历输入的语言代码数组
    do
    {
      // 获取当前语言代码
      v14 = CFArrayGetValueAtIndex(v5, v12);
      v26 = -6148914691236517206LL;
      
      // 规范化语言标识符
      LanguageIdentifierByNormalizing(v14, 0LL);
      
      // 检查规范化后的语言代码是否在系统支持的语言列表中
      __asm { LDAPR           X3, [X22], [X22] }
      if ( (unsigned int)CFArrayContainsValue(v7, 0LL, v8, _X3) )
      {
        // 如果支持，添加到有效语言数组中
        __asm { LDAPR           X0, [X22], [X22] }
        v21 = objc_retain(_X0);
        CFArrayAppendValue(v6, v21);
        objc_release(v21);
      }
      objc_release(v26);
      ++v12;
    }
    while ( v11 != v12 );
  }
  
  // 如果找到了有效的语言代码
  if ( CFArrayGetCount(v6) )
  {
    // 将主要语言代码插入到数组开头
    CFArrayInsertValueAtIndex(v6, 0LL, v4);
    v26 = -6148914691236517206LL;
    _X21 = &v26;
    
    // 将语言代码数组连接成字符串 (使用逗号分隔符)
    ArrayComponentsJoinedByString(v6, &stru_1F6568);
    
    // 移除开头的主要语言代码
    CFArrayRemoveValueAtIndex(v6, 0LL);
    
    // 调用字体回退函数，传入连接后的语言字符串
    __asm { LDAPR           X2, [X21], [X21] }
    TFontFallbacks::CopyFontFallbacks(v24, v25, _X2, v4, v6);
    objc_release(v26);
  }
  else
  {
    // 如果没有找到有效语言，使用单语言版本
    TFontFallbacks::CopyFontFallbacks(v24, v25, v4, 0LL, 0LL);
  }
  
  // 释放有效语言数组并返回
  return objc_release(v6);
}