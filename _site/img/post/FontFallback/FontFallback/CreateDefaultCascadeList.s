/**
 * CoreText 字体 - 创建默认级联列表函数
 * 函数名: TFont::CreateDefaultCascadeList
 * 功能: 为字体对象创建默认的字体级联列表
 * 
 * 参数:
 *   result (__int64): TFont 对象指针
 *   a2 (__int64): 语言代码数组指针 (CFArrayRef)
 *   a3 (_QWORD *): 输出参数指针，用于接收生成的字体级联列表
 * 
 * 返回值:
 *   __int64: 操作结果
 */
__int64 __usercall TFont::CreateDefaultCascadeList@<X0>(__int64 result@<X0>, __int64 a2@<X1>, _QWORD *a3@<X8>)
{
  _QWORD *v3; // 输出参数指针
  __int64 v4; // 基础字体对象指针
  unsigned int *v5; // 字体对象指针（用于类型转换）
  __int64 v7; // 系统UI字体标志
  __int64 v13; // 规范化的语言数组 [xsp+0h] [xbp-30h]
  bool v14; // 是否为系统UI字体标志 [xsp+Fh] [xbp-21h]

  // 保存输出参数指针
  v3 = a3;
  
  // 从字体对象偏移 408 字节处获取基础字体对象指针
  v4 = *(_QWORD *)(result + 408);
  if ( v4 )
  {
    // 将字体对象转换为无符号整数指针，用于访问内部字段
    v5 = (unsigned int *)result;
    
    // 初始化规范化语言数组
    v13 = -6148914691236517206LL;
    _X22 = &v13;
    
    // 创建规范化的语言数组
    CreateCanonicalLanguages(a2);
    
    // 检查字体是否为系统UI字体并用于文本整形
    v7 = TFont::IsSystemUIFontAndForShaping((TFont *)v5, &v14);
    
    // 获取规范化语言数组
    __asm { LDAPR           X4, [X22,#0x30+var_30], [X22,#0x30+var_30] }
    
    // 调用基础字体的创建回退函数
    // 参数1: v4 - 基础字体对象
    // 参数2: v7 - 系统UI字体标志
    // 参数3: ((v5[3] >> 6) & 7) - 从字体对象的第3个字段提取的字体特性标志
    // 参数4: 0LL - 保留参数
    // 参数5: _X4 - 规范化语言数组
    // 参数6: v3 - 输出参数指针
    TBaseFont::CreateFallbacks(v4, v7, ((unsigned __int64)v5[3] >> 6) & 7, 0LL, _X4, v3);
    
    // 释放规范化语言数组
    result = objc_release(v13);
  }
  else
  {
    // 如果没有基础字体对象，设置输出为 NULL
    *a3 = 0LL;
  }
  return result;
}