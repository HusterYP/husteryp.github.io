/**
 * CoreText 字体回退 - 复制字体回退列表函数
 * 函数名: TFontFallbacks::CopyFontFallbacks
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
  __CFString *v6; // 次要语言代码字符串
  __CFString *v7; // 主要语言代码字符串
  __int64 v8; // 字体描述符对象指针
  _QWORD *v9; // 输出参数指针
  __int64 v16; // 临时变量
  __int64 v22; // 临时变量
  __int64 v23; // 字体回退数组指针
  __int64 v24; // 字体回退项指针
  __int64 v28; // 可变数组指针
  __int64 v29; // 有序语言数组指针
  int v30; // 比较结果
  __int64 v31; // 语言匹配标志
  __CFString *v32; // 回退语言字符串
  __int64 v34; // 字典值指针
  __int64 v36; // 数组指针
  __int64 v44; // 临时变量
  __int64 v45; // 数组指针
  __int64 v46; // 数组计数
  __int64 v54; // 栈变量 [xsp+0h] [xbp-80h]
  __int64 v55; // 栈变量 [xsp+8h] [xbp-78h]
  __int64 v56; // 栈变量 [xsp+10h] [xbp-70h]
  __int64 v57; // 栈变量 [xsp+18h] [xbp-68h]
  __int64 v58; // 栈变量 [xsp+20h] [xbp-60h]
  __int64 v59; // 栈变量 [xsp+28h] [xbp-58h]

  // 保存参数到局部变量和寄存器
  _X22 = a5;  // 语言数组指针
  v6 = a4;    // 次要语言代码
  v7 = a3;    // 主要语言代码
  v8 = a2;    // 字体描述符对象
  v9 = a1;    // 输出参数指针
  // 初始化栈变量为特殊值 (0xAAAAAAAAAAAAAAAA)
  v57 = -6148914691236517206LL;
  
  // 从字体描述符对象偏移 8 字节处获取字典指针
  _X8 = a2 + 8;
  __asm { LDAPR           X0, [X8], [X8] }
  
  // 在字典中查找主要语言代码对应的字体回退数组
  v16 = CFDictionaryGetValue(_X0, a3);
  v57 = objc_retain(v16);
  
  // 检查是否找到了对应的字体回退数组
  _X8 = &v57;
  __asm { LDAPR           X9, [X8], [X8] }
  if ( !_X9 )
  {
    // 如果没有找到，尝试使用默认字体回退
    v55 = -6148914691236517206LL;
    v56 = 0LL;
    
    // 如果没有次要语言，使用主要语言
    if ( !v6 )
      v6 = v7;
      
    // 调用默认字体回退函数
    _X24 = &v55;
    CopyDefaultFontFallbacks();
    
    // 获取默认字体回退字典
    __asm { LDAPR           X0, [X24], [X24] }
    v22 = objc_retain(_X0);
    if ( v22 )
    {
      v23 = v22;
      // 在默认字体回退字典中查找对应语言的字体列表
      v24 = CFDictionaryGetValue(v22, v6);
      objc_release(v23);
      
      // 检查是否找到了有效的字体列表
      if ( v24 && CFArrayGetCount(v24) >= 1 )
      {
        // 如果没有提供语言数组，从字体描述符对象中获取
        if ( !_X22 )
        {
          _X8 = v8 + 16;
          __asm { LDAPR           X22, [X8], [X8] }
        }
        
        // 获取默认字体回退字典
        _X8 = &v55;
        __asm { LDAPR           X25, [X8], [X8] }
        
        // 创建可变数组用于存储处理后的字体回退列表
        v28 = CFArrayCreateMutable(*(_QWORD *)kCFAllocatorDefault_ptr, 0LL, kCFTypeArrayCallBacks_ptr);
        v58 = -6148914691236517206LL;
        v59 = v28;
        
        // 初始化字体描述符源对象
        TDescriptorSource::TDescriptorSource((TDescriptorSource *)&v58);
        
        // 创建有序语言数组
        v29 = CreateOrderedLanguages(_X22);
        
        // 判断语言类型，设置相应的标志
        if ( v6 == &stru_1F5508 )  // 可能是 "en" 英语
        {
          v31 = 1LL;  // 英语标志
        }
        else if ( v6 )
        {
          v30 = CFEqual(v6, &stru_1F5508);
          v31 = 1LL;
          // 检查是否为 CJK (中日韩) 语言
          if ( v6 != &stru_1F69A8 && !v30 )
            v31 = (unsigned int)CFStringHasPrefix(v6, &stru_1F69A8) != 0;
        }
        else
        {
          v31 = 0LL;  // 无语言标志
        }
        
        // 处理字体回退列表
        _X27 = &v59;
        TDescriptorSource::ProcessFallbackList(v24, (__int64)&v59, v31, v29);
        
        // 获取通用字体回退列表
        v34 = CFDictionaryGetValue(_X25, &stru_1F69C8);
        if ( v34 )
        {
          v36 = v34;
          // 如果通用字体回退列表不为空，也进行处理
          if ( CFArrayGetCount(v34) )
            TDescriptorSource::ProcessFallbackList(v36, (__int64)&v59, v31, v29);
        }
        // 原子交换操作，获取处理后的字体回退数组
        __asm { SWPAL           XZR, X8, [X27] }
        v54 = _X8;
        
        // 释放临时对象
        objc_release(v29);  // 有序语言数组
        _X0 = objc_release(v59);  // 可变数组
        
        // 原子操作，将结果保存到输出变量
        _X8 = &v54;
        __asm { SWPAL           XZR, X8, [X8,#0x80+var_80] }
        _X22 = &v56;
        __asm { SWPAL           X8, X0, [X22] }
        objc_release(_X0);
        objc_release(v54);
        
        // 检查生成的字体回退数组是否有效
        __asm { LDAPR           X0, [X22], [X22] }
        v44 = objc_retain(_X0);
        if ( v44 )
        {
          v45 = v44;
          v46 = CFArrayGetCount(v44);
          objc_release(v45);
          
          // 如果数组不为空，缓存到字体描述符对象中
          if ( v46 >= 1 )
          {
            _X8 = v8 + 8;
            __asm { LDAPR           X0, [X8], [X8] }
            _X8 = &v56;
            __asm { LDAPR           X2, [X8], [X8] }
            // 将字体回退数组缓存到字典中
            CFDictionarySetValue(_X0, v7, _X2);
          }
        }
        else
        {
          objc_release(0LL);
        }
        goto LABEL_33;
      }
    }
    else
    {
      objc_release(0LL);
    }
    // 处理特定语言的回退逻辑
    if ( v6 == &stru_1F55A8 )  // 可能是特定语言代码
      goto LABEL_19;
    if ( v6 )
    {
      if ( (unsigned int)CFEqual(v6, &stru_1F55A8) )
      {
LABEL_19:
        v32 = &stru_1F5588;  // 设置回退语言
LABEL_20:
        // 递归调用，使用回退语言
        TFontFallbacks::CopyFontFallbacks(v9, v8, v32, 0LL, _X22);
LABEL_34:
        // 清理资源
        objc_release(v55);
        objc_release(v56);
        return objc_release(v57);
      }
      // 处理另一种特定语言
      if ( v6 == &stru_1F55E8 || (unsigned int)CFEqual(v6, &stru_1F55E8) )
      {
        v32 = &stru_1F5528;  // 设置回退语言
        goto LABEL_20;
      }
      // 处理第三种特定语言
      if ( v6 == &stru_1F55C8 || (unsigned int)CFEqual(v6, &stru_1F55C8) )
      {
        v32 = &stru_1F5508;  // 设置回退语言 (可能是英语)
        goto LABEL_20;
      }
    }
LABEL_33:
    // 设置输出参数
    _X8 = &v56;
    __asm { SWPAL           XZR, X8, [X8] }
    *v9 = &v56;
    goto LABEL_34;
  }
  // 如果找到了字体回退数组，直接使用
  __asm { SWPAL           XZR, X8, [X8] }
  *v9 = &v57;
  return objc_release(v57);
}