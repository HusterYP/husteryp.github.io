/**
 * CoreText 基础字体 - 创建字体回退列表函数
 * 函数名: TBaseFont::CreateFallbacks
 * 功能: 为基础字体对象创建字体回退列表
 * 
 * 参数:
 *   result (__int64): TBaseFont 对象指针
 *   a2 (__int64): 系统UI字体标志
 *   a3 (__int64): 字体特性标志
 *   a4 (__int64): 保留参数
 *   a5 (__int64): 语言数组指针
 *   a6 (_QWORD *): 输出参数指针，用于接收生成的字体回退列表
 * 
 * 返回值:
 *   __int64: 操作结果
 */
__int64 __usercall TBaseFont::CreateFallbacks@<X0>(__int64 result@<X0>, __int64 a2@<X1>, __int64 a3@<X2>, __int64 a4@<X3>, __int64 a5@<X4>, _QWORD *a6@<X8>)
{
  __int64 v6; // 字体特性标志
  __int64 v7; // 语言数组指针
  int v8; // 系统UI字体标志
  TBaseFont *v9; // 基础字体对象指针
  _QWORD *v11; // 保留参数指针
  __int64 v12; // 预设字体回退字典指针
  __int64 v13; // 预设字体回退字典副本
  __int64 v24; // 临时变量
  __int64 v25; // 临时变量
  __int64 v26; // 数组计数
  signed __int64 v27; // CSS字体族名
  __int64 v33; // 字体描述符源对象 [xsp+0h] [xbp-50h]
  __int64 v34; // 字体回退数组 [xsp+8h] [xbp-48h]

  // 保存参数
  v6 = a3;  // 字体特性标志
  v7 = a5;  // 语言数组指针
  v8 = a2;  // 系统UI字体标志
  v9 = (TBaseFont *)result;  // 基础字体对象
  _X19 = a6;  // 输出参数指针
  
  // 初始化输出参数为 NULL
  *a6 = 0LL;
  
  // 检查字体特性标志的最低位是否为 1 (启用字体回退)
  if ( a3 & 1 )
  {
    // 如果系统UI字体标志不为 0，尝试创建预设字体回退
    if ( (_DWORD)a2 )
    {
      v11 = (_QWORD *)a4;
      
      // 从字体对象偏移 560 字节处获取预设字体回退字典
      v12 = (*(__int64 (**)(void))(*(_QWORD *)result + 560LL))();
      if ( v12 )
      {
        v13 = v12;
        
        // 初始化字体描述符源对象
        TDescriptorSource::TDescriptorSource((TDescriptorSource *)&v33);
        _X26 = &v34;
        
        // 创建预设字体回退列表
        _X0 = TDescriptorSource::CreatePresetFallbacks(v13, v11, v7, v6, &v34);
        
        // 原子操作：将结果保存到输出参数
        __asm
        {
          SWPAL           XZR, X8, [X26]
          SWPAL           X8, X0, [X19]
        }
        
        // 释放临时对象
        objc_release(_X0);
        objc_release(v34);
      }
    }
    
    // 检查预设字体回退是否成功创建
    __asm { LDAPR           X0, [X19], [X19] }
    v24 = objc_retain(_X0);
    if ( v24 )
    {
      v25 = v24;
      v26 = CFArrayGetCount(v24);
      result = objc_release(v25);
      
      // 如果预设字体回退不为空，直接返回
      if ( v26 )
        return result;
    }
    else
    {
      objc_release(0LL);
    }
    
    // 如果预设字体回退为空，创建系统默认字体回退
    v27 = TBaseFont::GetCSSFamily(v9);
    _X23 = &v34;
    
    // 创建系统默认字体回退列表
    _X0 = TBaseFont::CreateSystemDefaultFallbacks((__int64)v9, v27, v7, v8, &v34);
    
    // 原子操作：将结果保存到输出参数
    __asm
    {
      SWPAL           XZR, X8, [X23]
      SWPAL           X8, X0, [X19]
    }
    
    // 释放临时对象
    objc_release(_X0);
    result = objc_release(v34);
  }
  return result;
}