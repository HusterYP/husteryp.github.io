/**
 * CoreText 字体级联列表获取函数
 * 函数名: CTFontCopyDefaultCascadeListForLanguages
 * 功能: 根据指定语言获取字体的默认级联列表
 * 
 * 参数:
 *   a1 (__int64): CTFont 对象的指针
 *   a2 (__int64): 语言代码数组的指针 (CFArrayRef)
 * 
 * 返回值:
 *   __int64: CFArrayRef - 字体级联列表的副本，失败时返回 NULL
 */
__int64 __fastcall CTFontCopyDefaultCascadeListForLanguages(__int64 a1, __int64 a2)
{
  __int64 v9;  // 返回的字体级联列表数组
  __int64 v11; // 本地变量，用于存储中间结果数组 [xsp+8h] [xbp-18h]

  // 参数有效性检查：如果传入的字体对象为空，直接返回 NULL
  if ( !a1 )
    return 0LL;
    
  // 初始化本地变量为特殊值 (-6148914691236517206LL = 0xAAAAAAAAAAAAAAAA)
  // 这个值通常用作未初始化或占位符值
  v11 = -6148914691236517206LL;
  
  // 将本地变量的地址保存到 X19 寄存器中
  // X19 是 ARM64 架构中的通用寄存器，用于函数调用约定
  _X19 = &v11;
  
  // 调用 TFont 类的 CreateDefaultCascadeList 静态方法
  // 参数1: *(a1 + 40) - 从 CTFont 对象偏移 40 字节处获取内部字体对象
  // 参数2: a2 - 语言代码数组
  // 参数3: &v11 - 输出参数，用于接收生成的级联列表
  TFont::CreateDefaultCascadeList(*(_QWORD *)(a1 + 40), a2, &v11);
  
  // ARM64 汇编指令：LDAPR (Load-Acquire with Release semantics)
  // 从 X19 指向的地址加载数据到 X8 寄存器
  // 这是一个原子操作，确保内存访问的一致性
  __asm { LDAPR           X8, [X19], [X19] }
  
  // 检查 X8 寄存器中的值是否非空
  if ( _X8 )
  {
    // 再次使用 LDAPR 指令从 X19 指向的地址加载数据到 X1 寄存器
    __asm { LDAPR           X1, [X19], [X19] }
    
    // 使用 Core Foundation 的 CFArrayCreateCopy 函数创建数组副本
    // 参数1: kCFAllocatorDefault_ptr - 默认内存分配器
    // 参数2: _X1 - 源数组（字体级联列表）
    // 返回: 新创建的数组副本
    v9 = CFArrayCreateCopy(*(_QWORD *)kCFAllocatorDefault_ptr, _X1);
  }
  else
  {
    // 如果源数组为空，设置返回值为 NULL
    v9 = 0LL;
  }
  
  // 释放本地变量 v11 的内存
  // 这是 Objective-C 的引用计数管理，防止内存泄漏
  objc_release(v11);
  
  // 返回生成的字体级联列表副本
  return v9;
}