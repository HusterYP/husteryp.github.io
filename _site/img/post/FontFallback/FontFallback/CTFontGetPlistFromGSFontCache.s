/**
 * CoreText 字体 - 从 GS 字体缓存获取属性列表函数
 * 函数名: CTFontGetPlistFromGSFontCache
 * 功能: 从 GS (Graphics Services) 字体缓存中获取指定字体的属性列表数据
 * 
 * 参数:
 *   a1 (const __CFString *): 字体名称字符串指针
 *   a2 (char): 控制标志（位0=1时直接获取，位0=0时检查全局状态）
 * 
 * 返回值:
 *   __int64: 字体属性列表数据指针，失败时返回 NULL
 */
__int64 __fastcall CTFontGetPlistFromGSFontCache(const __CFString *a1, char a2)
{
  const __CFString *v2; // 字体名称字符串指针
  __int64 result; // 返回值

  // 保存字体名称参数
  v2 = a1;
  
  // 检查控制标志的最低位
  if ( a2 & 1 )
    goto LABEL_9;  // 如果设置了直接获取标志，跳过状态检查
    
  // 确保全局状态已初始化（使用 dispatch_once 确保只初始化一次）
  if ( qword_22A508 != -1 )
    dispatch_once(&qword_22A508, &__block_literal_global_6);
    
  // 检查全局状态是否允许从字体缓存获取数据
  if ( _MergedGlobals_31 == 1 )
LABEL_9:
    // 从 GS 字体缓存获取字体数据
    result = GSFontCacheGetData_ptr(v2);
  else
    // 如果全局状态不允许，返回 NULL
    result = 0LL;
    
  return result;
}