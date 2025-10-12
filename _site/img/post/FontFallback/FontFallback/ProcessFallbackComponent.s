/**
 * CoreText 字体描述符源 - 处理字体回退组件函数
 * 函数名: TDescriptorSource::ProcessFallbackComponent
 * 功能: 处理字体回退列表中的单个组件（字符串或数组）
 * 
 * 参数:
 *   a1 (__int64): 字体描述符源对象指针
 *   a2 (__int64): 字体回退组件指针（字符串或数组）
 *   a3 (__int64): 起始索引（用于数组处理）
 *   a4 (int): 字体特性标志（1=表情符号字体，其他=普通字体）
 * 
 * 返回值:
 *   __int64: 操作结果
 */
__int64 __fastcall TDescriptorSource::ProcessFallbackComponent(__int64 a1, __int64 a2, __int64 a3, int a4)
{
  int v4; // 字体特性标志
  __int64 v5; // 起始索引
  __int64 v6; // 字体回退组件指针
  __int64 v7; // 字体描述符源对象指针
  __int64 v8; // 组件类型ID
  signed __int64 v9; // 字体描述符标志
  __int64 result; // 返回值
  __int64 v11; // 数组长度

  // 保存参数
  v4 = a4;  // 字体特性标志
  v5 = a3;  // 起始索引
  v6 = a2;  // 字体回退组件指针
  v7 = a1;  // 字体描述符源对象指针
  
  // 获取组件的类型ID
  v8 = CFGetTypeID(a2);
  
  // 根据字体特性标志设置字体描述符标志
  if ( v4 == 1 )
    v9 = 1024LL;    // 表情符号字体标志
  else
    v9 = 65537LL;   // 普通字体标志
    
  // 如果组件是字符串类型，直接处理
  if ( v8 == CFStringGetTypeID() )
    return TDescriptorSource::AppendFontDescriptorFromName(v7, v6, v9);
    
  // 检查组件是否为数组类型
  result = CFArrayGetTypeID();
  if ( v8 == result )
  {
    // 获取数组长度
    result = CFArrayGetCount(v6);
    if ( result > v5 )
    {
      v11 = result;
      
      // 从指定索引开始遍历数组
      do
      {
        // 获取数组中的字体名称
        result = CFArrayGetValueAtIndex(v6, v5);
        if ( result )
          // 将字体名称添加到字体描述符源
          result = TDescriptorSource::AppendFontDescriptorFromName(v7, result, v9);
        ++v5;
      }
      while ( v11 != v5 );
    }
  }
  return result;
}