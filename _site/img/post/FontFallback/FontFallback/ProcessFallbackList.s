/**
 * CoreText 字体描述符源 - 处理字体回退列表函数
 * 函数名: TDescriptorSource::ProcessFallbackList
 * 功能: 处理字体回退列表，支持字符串、字典和数组类型的组件
 * 
 * 参数:
 *   a1 (__int64): 字体回退列表数组指针
 *   a2 (__int64): 字体描述符源对象指针
 *   a3 (__int64): 字体特性标志（1=表情符号字体，其他=普通字体）
 *   a4 (__int64): 语言数组指针
 * 
 * 返回值:
 *   __int64: 操作结果
 */
__int64 __fastcall TDescriptorSource::ProcessFallbackList(__int64 a1, __int64 a2, __int64 a3, __int64 a4)
{
  __int64 v4; // 语言数组指针
  int v5; // 字体特性标志
  __int64 v6; // 字体描述符源对象指针
  __int64 v7; // 字体回退列表数组指针
  __int64 result; // 返回值
  __int64 v9; // 循环计数器
  __CFString *v11; // 当前字体回退项
  __int64 v12; // 组件类型ID
  __CFString *v13; // 表情符号字体名称
  signed __int64 v14; // 字体描述符标志
  __int64 v15; // 语言数组长度
  __int64 v16; // 语言循环计数器
  __int64 v17; // 语言数组长度
  __int64 v18; // 语言数组长度副本
  __int64 v19; // 语言循环计数器
  __int64 v20; // 当前语言代码
  __int64 v26; // 数组索引
  __int64 v28; // 数组项指针
  __int64 v29; // 数组项副本
  __int64 v30; // 数组项的第一个元素
  __int64 v34; // 数组长度
  __int64 v35; // 数组长度副本
  __int64 v36; // 循环计数器
  __int64 v37; // 数组项指针
  __int64 v38; // 字体回退列表数组指针副本 [xsp+8h] [xbp-68h]
  __int64 v39; // 字体回退列表数组长度 [xsp+10h] [xbp-60h]
  __int64 v40; // 可变数组 [xsp+18h] [xbp-58h]

  // 保存参数
  v4 = a4;  // 语言数组指针
  v5 = a3;  // 字体特性标志
  v6 = a2;  // 字体描述符源对象指针
  v7 = a1;  // 字体回退列表数组指针
  
  // 获取字体回退列表数组的长度
  result = CFArrayGetCount(a1);
  v39 = result;
  if ( result )
  {
    v9 = 0LL;
    _X23 = &v40;
    v38 = v7;
    
    // 遍历字体回退列表数组
    do
    {
      // 获取当前字体回退项
      v11 = (__CFString *)CFArrayGetValueAtIndex(v7, v9);
      v12 = CFGetTypeID(v11);
      
      // 如果当前项不是字符串类型
      if ( v12 != CFStringGetTypeID() )
      {
        // 检查是否为字典类型（语言特定的字体配置）
        result = CFDictionaryGetTypeID();
        if ( v12 == result )
        {
          // 如果提供了语言数组，遍历语言查找匹配的字体
          if ( v4 )
          {
            result = CFArrayGetCount(v4);
            if ( result )
            {
              v15 = result;
              v16 = 0LL;
              do
              {
                result = CFArrayGetValueAtIndex(v4, v16);
                if ( v11 )
                {
                  result = CFDictionaryGetValue(v11, result);
                  if ( result )
                    // 处理找到的字体配置
                    result = TDescriptorSource::ProcessFallbackComponent(v6, result, 0LL, v5);
                }
                ++v16;
              }
              while ( v15 != v16 );
            }
          }
        }
        else
        {
          // 检查是否为数组类型（嵌套的字体回退列表）
          result = CFArrayGetTypeID();
          if ( v12 == result )
          {
            // 创建可变数组副本
            v40 = -6148914691236517206LL;
            TCFMutableArray::TCFMutableArray(&v40, v11);
            
            // 如果提供了语言数组，处理语言特定的字体
            if ( v4 )
            {
              v17 = CFArrayGetCount(v4);
              if ( v17 )
              {
                v18 = v17;
                v19 = 0LL;
                do
                {
                  v20 = CFArrayGetValueAtIndex(v4, v19);
                  __asm { LDAPR           X0, [X23], [X23] }
                  
                  // 查找匹配语言的字体配置
                  if ( CFArrayGetCount(_X0) >= 1 )
                  {
                    v26 = 0LL;
                    while ( 1 )
                    {
                      __asm { LDAPR           X0, [X23], [X23] }
                      v28 = CFArrayGetValueAtIndex(_X0, v26);
                      v29 = v28;
                      v30 = CFArrayGetValueAtIndex(v28, 0LL);
                      
                      // 检查是否匹配当前语言
                      if ( v30 == v20 || v20 && v30 && (unsigned int)CFEqual(v30, v20) )
                        break;
                      ++v26;
                      __asm { LDAPR           X0, [X23], [X23] }
                      if ( v26 >= CFArrayGetCount(_X0) )
                        goto LABEL_38;
                    }
                    
                    // 处理匹配的字体配置
                    TDescriptorSource::ProcessFallbackComponent(v6, v29, 1LL, v5);
                    __asm { LDAPR           X0, [X23], [X23] }
                    // 移除已处理的配置
                    CFArrayRemoveValueAtIndex(_X0, v26);
                  }
LABEL_38:
                  ++v19;
                }
                while ( v19 != v18 );
              }
            }
            
            // 处理剩余的字体配置
            __asm { LDAPR           X25, [X23], [X23] }
            if ( _X25 )
            {
              v34 = CFArrayGetCount(_X25);
              if ( v34 )
              {
                v35 = v34;
                v36 = 0LL;
                do
                {
                  v37 = CFArrayGetValueAtIndex(_X25, v36);
                  // 处理剩余的字体配置
                  TDescriptorSource::ProcessFallbackComponent(v6, v37, 1LL, v5);
                  ++v36;
                }
                while ( v35 != v36 );
              }
            }
            result = objc_release(v40);
            v7 = v38;
          }
        }
        goto LABEL_23;
      }
      
      // 处理字符串类型的字体名称
      if ( v5 == 1 )
      {
        // 处理表情符号字体的特殊情况
        if ( !(dyld_program_sdk_at_least(567463457243267071LL) & 1) )
        {
          v13 = _CTGetEmojiFontName(1);
          if ( v13 == v11 )
            goto LABEL_46;
          v14 = 1024LL;
          if ( !v11 || !v13 )
            goto LABEL_22;
          if ( (unsigned int)CFEqual(v11, v13) )
LABEL_46:
            v11 = _CTGetEmojiFontName(0);
        }
        v14 = 1024LL;  // 表情符号字体标志
      }
      else
      {
        v14 = 65537LL;  // 普通字体标志
      }
      
LABEL_22:
      // 将字体名称添加到字体描述符源
      result = TDescriptorSource::AppendFontDescriptorFromName(v6, v11, v14);
      
LABEL_23:
      ++v9;
    }
    while ( v9 != v39 );
  }
  return result;
}