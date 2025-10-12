/**
 * CoreText 字体描述符源 - 复制默认替换列表函数
 * 函数名: TDescriptorSource::CopyDefaultSubstitutionListForLanguages
 * 功能: 为指定语言复制默认的字体替换列表
 * 
 * 参数:
 *   a1 (__int64): 字体描述符源对象指针
 *   a2 (__int64): 语言代码数组指针 (CFArrayRef)
 *   a3 (__int64): 输出参数，用于接收生成的字体替换列表
 * 
 * 返回值:
 *   __int64: 解锁操作的返回值
 */
__int64 __usercall TDescriptorSource::CopyDefaultSubstitutionListForLanguages@<X0>(__int64 a1@<X0>, __int64 a2@<X1>, __int64 a3@<X8>)
{
  __int64 v3; // 语言代码数组指针的副本
  __int64 v4; // 字体描述符源对象指针的副本
  __int64 v5; // 输出参数指针的副本
  TDescriptorSource *v6; // 锁对象指针

  // 保存参数到局部变量
  v3 = a2;  // 语言代码数组
  v4 = a1;  // 字体描述符源对象
  v5 = a3;  // 输出参数
  
  // 获取字体回退缓存锁 (327680LL = 0x50000，可能是锁选项)
  // 这个锁确保字体回退缓存的线程安全访问
  v6 = (TDescriptorSource *)os_unfair_lock_lock_with_options(&TDescriptorSource::sFontFallbacksLock, 327680LL);
  
  // 确保字体回退缓存已初始化
  // 如果缓存不存在，会创建并填充默认的字体回退数据
  TDescriptorSource::EnsureFontFallbacksCache(v6);
  
  // 调用 TFontFallbacks 类的静态方法，为指定语言复制字体回退列表
  // 参数1: TDescriptorSource::sFontFallbacksCache - 全局字体回退缓存
  // 参数2: v4 - 字体描述符源对象
  // 参数3: v3 - 语言代码数组
  // 参数4: v5 - 输出参数，接收生成的替换列表
  TFontFallbacks::CopyFontFallbacksForLanguages(TDescriptorSource::sFontFallbacksCache, v4, v3, v5);
  
  // 释放字体回退缓存锁并返回
  return os_unfair_lock_unlock(&TDescriptorSource::sFontFallbacksLock);
}