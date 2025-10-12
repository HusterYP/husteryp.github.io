/**
 * CoreText 字体描述符源 - 创建预设字体回退列表函数
 * 函数名: TDescriptorSource::CreatePresetFallbacks
 * 功能: 根据字体族名创建预设的字体回退列表
 * 
 * 参数:
 *   a1 (__int64): 字体族名字符串指针
 *   a2 (_QWORD *): 输出参数指针，用于接收字符集信息
 *   a3 (__int64): 语言数组指针
 *   a4 (__int64): 字体特性标志
 *   a5 (_QWORD *): 输出参数指针，用于接收生成的字体回退数组
 * 
 * 返回值:
 *   __int64: 操作结果
 */
__int64 __usercall TDescriptorSource::CreatePresetFallbacks@<X0>(__int64 a1@<X1>, _QWORD *a2@<X2>, __int64 a3@<X3>, __int64 a4@<X4>, _QWORD *a5@<X8>)
{
  __int64 v6; // 语言数组指针
  _QWORD *v7; // 字符集输出参数指针
  __int64 v8; // 字体族名字符串指针
  __int64 result; // 返回值
  __int64 v11; // 预设字体回退字典指针
  __int64 v12; // 有序语言数组指针
  __int64 v13; // 字体回退配置数组指针
  bool v14; // 字符集标志
  __int64 v15; // 字体回退配置数组副本
  __int64 v16; // 类型ID
  __int64 v17; // 数组长度
  __int64 v18; // 循环上限
  __int64 v19; // 循环计数器
  __CFString *v20; // 当前字体回退项
  __int64 v21; // 类型ID
  __int64 v22; // 语言数组长度
  __int64 v23; // 语言数组长度副本
  __int64 v24; // 语言循环计数器
  __int64 v25; // 当前语言代码
  __int64 v26; // 字体名称
  const char *v27; // 字体名称字符串
  __CFString *v28; // 表情符号字体名称
  __CFString *v29; // 替换字体名称
  __int64 v37; // 字体描述符数组 [xsp+8h] [xbp-58h]

  // 保存参数到寄存器和局部变量
  _X22 = a4;  // 字体特性标志
  v6 = a3;    // 语言数组指针
  v7 = a2;    // 字符集输出参数指针
  v8 = a1;    // 字体族名字符串指针
  _X19 = a5;  // 输出参数指针
  
  // 获取 CoreText 预设字体回退字典
  result = GetCTPresetFallbacksDictionary();
  if ( !result )
    goto LABEL_37;
    
  v11 = result;
  
  // 创建有序语言数组
  v12 = CreateOrderedLanguages(v6);
  if ( !v12 )
  {
LABEL_36:
    result = objc_release(v12);
LABEL_37:
    *_X19 = 0LL;
    return result;
  }
  
  // 在预设字体回退字典中查找字体族名对应的配置
  v13 = CFDictionaryGetValue(v11, v8);
  if ( v13 && (v15 = v13, v16 = CFGetTypeID(v13), v16 == CFArrayGetTypeID()) )
  {
    // 创建可变数组用于存储字体描述符
    v37 = CFArrayCreateMutable(*(_QWORD *)kCFAllocatorDefault_ptr, 0LL, kCFTypeArrayCallBacks_ptr);
    v17 = CFArrayGetCount(v15);
    if ( v17 )
    {
      v18 = v17;
      v19 = 0LL;
      
      // 遍历字体回退配置数组
      do
      {
        v20 = (__CFString *)CFArrayGetValueAtIndex(v15, v19);
        v21 = CFGetTypeID(v20);
        
        // 如果当前项是字典类型，说明是按语言区分的预设字体
        if ( v21 == CFDictionaryGetTypeID() )
        {
          v22 = CFArrayGetCount(v12);
          if ( v22 )
          {
            v23 = v22;
            v24 = 0LL;
            
            // 遍历用户的语言列表，在字典中查找匹配的预设字体
            do
            {
              v25 = CFArrayGetValueAtIndex(v12, v24);
              if ( v20 )
              {
                v26 = CFDictionaryGetValue(v20, v25);
                if ( v26 )
                  // 添加字体描述符到数组
                  TDescriptorSource::AppendFontDescriptorFromName(&v37, v26, 1024LL);
              }
              ++v24;
            }
            while ( v23 != v24 );
          }
        }
        else
        {
          // 如果是字符串类型，直接作为预设字体名
          
          // 处理表情符号字体的特殊情况
          if ( !(dyld_program_sdk_at_least(567463457243267071LL) & 1) )
          {
            v28 = _CTGetEmojiFontName(1);
            if ( v28 == v20 || v20 && (v27 = (const char *)v28) != 0LL && (unsigned int)CFEqual(v20, v28) )
              v20 = _CTGetEmojiFontName(0);
          }
          
          // 处理特定字体前缀的替换逻辑
          if ( _X22 & 4 && (v20 == &stru_1F6448 || v20 && (unsigned int)CFStringHasPrefix(v20, &stru_1F6448)) )
          {
            v29 = (__CFString *)objc_msgSend_objectForKeyedSubscript_(&unk_20BCA8, v27, v20);
            if ( v29 )
              v20 = v29;
          }
          
          // 添加字体描述符到数组
          TDescriptorSource::AppendFontDescriptorFromName(&v37, v20, 1024LL);
        }
        ++v19;
      }
      while ( v19 != v18 );
    }
    
    // 原子操作：将字体描述符数组保存到输出参数
    _X8 = &v37;
    __asm { SWPAL           XZR, X22, [X8] }
    objc_release(v37);
  }
  else
  {
    _X22 = 0LL;
  }
  
  // 设置输出参数
  *_X19 = _X22;
  
  // 检查结果是否有效
  __asm { LDAPR           X8, [X19], [X19] }
  if ( !_X8 )
  {
    objc_release(*_X19);
    goto LABEL_36;
  }
  
  // 如果需要，复制预定义字符集
  if ( v7 )
    *v7 = TDescriptorSource::CopyPredefinedCharacterSet((TDescriptorSource *)&stru_1F6528, 0LL, v14);
    
  // 释放有序语言数组并返回
  return objc_release(v12);
}