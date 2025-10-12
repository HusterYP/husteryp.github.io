/**
 * CoreText 基础字体 - 创建系统默认字体回退列表函数
 * 函数名: TBaseFont::CreateSystemDefaultFallbacks
 * 功能: 为基础字体对象创建系统默认的字体回退列表
 * 
 * 参数:
 *   a1 (__int64): TBaseFont 对象指针
 *   a2 (signed __int64): CSS 字体族名字符串指针
 *   a3 (__int64): 语言数组指针
 *   a4 (int): 系统UI字体标志
 *   a5 (__int64 *): 输出参数指针，用于接收生成的字体回退数组
 * 
 * 返回值:
 *   __int64: 操作结果
 */
__int64 __usercall TBaseFont::CreateSystemDefaultFallbacks@<X0>(__int64 a1@<X0>, signed __int64 a2@<X1>, __int64 a3@<X2>, int a4@<W3>, __int64 *a5@<X8>)
{
  int v6; // 系统UI字体标志
  __int64 v7; // 语言数组指针
  __int64 v8; // 基础字体对象指针
  __int64 *v9; // 输出参数指针
  __int64 v16; // CSS 字体族名字符串指针
  __int64 v19; // 临时变量
  __int64 v20; // 临时变量
  __int64 v21; // 数组计数
  __int64 v22; // 字体回退数组对象指针
  _QWORD *v25; // 临时变量
  const char *v26; // 方法选择器字符串
  _QWORD *v27; // 字体回退数组对象指针
  void *v28; // 数组计数方法调用结果
  void *v29; // 可变数组分配器
  const char *v30; // 方法选择器字符串
  void *v31; // 可变数组分配器
  const char *v32; // 方法选择器字符串
  __int64 v33; // 基础字体对象指针
  __int64 v37; // 字体URL字符串
  __int64 v38; // 字体URL哈希值
  __int64 v41; // 字体名称字符串
  unsigned __int64 v42; // 哈希值
  const char *v43; // 方法选择器字符串
  const char *v46; // 方法选择器字符串
  void *v47; // 枚举计数
  void *v48; // 枚举计数副本
  __int64 v49; // 枚举状态指针
  void *v50; // 循环计数器
  __int64 v51; // 字体描述符指针
  __int64 v54; // 字体名称字符串
  __int64 v55; // 字体属性字符串
  __int64 v56; // 字体属性字符串副本
  int v57; // 字符串比较结果
  const char *v58; // 方法选择器字符串
  const char *v59; // 方法选择器字符串
  const char *v60; // 方法选择器字符串
  __int64 result; // 返回值
  void *v62; // 栈变量 [xsp+10h] [xbp-160h]
  _QWORD *v63; // 字体回退数组对象指针 [xsp+18h] [xbp-158h]
  void *v64; // 语言数组指针 [xsp+20h] [xbp-150h]
  __int64 v65; // 字体名称字符串 [xsp+28h] [xbp-148h]
  __int64 v66; // 字体描述符源对象 [xsp+30h] [xbp-140h]
  __int64 v67; // 字体属性字符串 [xsp+38h] [xbp-138h]
  __int128 v68; // 枚举状态 [xsp+40h] [xbp-130h]
  __int128 v69; // 枚举状态 [xsp+50h] [xbp-120h]
  __int128 v70; // 枚举状态 [xsp+60h] [xbp-110h]
  __int128 v71; // 枚举状态 [xsp+70h] [xbp-100h]
  __int64 v72; // 字体回退数组对象指针 [xsp+80h] [xbp-F0h]
  void *v73; // 父类指针 [xsp+88h] [xbp-E8h]
  __int64 v74; // 字体URL [xsp+90h] [xbp-E0h]
  __int64 v75; // 栈保护值 [xsp+110h] [xbp-60h]

  // 保存参数
  v6 = a4;  // 系统UI字体标志
  v7 = a3;  // 语言数组指针
  v8 = a1;  // 基础字体对象指针
  v9 = a5;  // 输出参数指针
  
  // 设置栈保护
  v75 = *(_QWORD *)__stack_chk_guard_ptr;
  
  // 从基础字体对象偏移 96 字节处获取字体名称
  _X8 = a1 + 96;
  __asm { LDAPR           X0, [X8], [X8] }
  
  // 检查字体名称是否等于特定值，如果是则使用默认字体族名
  if ( _X0 == &stru_1FC3E8 || (v16 = a2, _X0) && (unsigned int)CFEqual(_X0, &stru_1FC3E8) )
    v16 = 4503599629423912LL;
  // 初始化字体描述符源对象
  v66 = -6148914691236517206LL;
  TDescriptorSource::TDescriptorSource((TDescriptorSource *)&v74);
  _X19 = &v66;
  
  // 复制默认字体替换列表
  TDescriptorSource::CopyDefaultSubstitutionListForLanguages(v16, v7);
  
  // 获取字体替换列表
  __asm { LDAPR           X0, [X19], [X19] }
  v19 = objc_retain(_X0);
  v20 = v19;
  if ( v19 )
  {
    v21 = CFArrayGetCount(v19);
    objc_release(v20);
    
    // 检查字体替换列表是否为空
    if ( v21 < 1 )
      goto LABEL_33;
      
    // 初始化输出参数
    *v9 = -6148914691236517206LL;
    
    // 分配 CTFontFallbacksArray 对象
    v22 = objc_alloc(&OBJC_CLASS____CTFontFallbacksArray);
    _X8 = &v66;
    __asm { LDAPR           X8, [X8], [X8] }
    v64 = _X8;
    
    if ( !v22 )
      goto LABEL_33;
      
    // 初始化字体回退数组对象
    v72 = v22;
    v73 = off_20B5D8;
    v25 = objc_msgSendSuper2(&v72, (const char *)off_20B418);
    if ( v25 )
    {
      v27 = v25;
      v25[2] = v8;  // 设置基础字体对象
      
      // 获取语言数组计数
      v28 = objc_msgSend_count(v64, v26);
      
      // 创建可变数组用于存储字体描述符
      v29 = (void *)objc_alloc(OBJC_CLASS___NSMutableArray_ptr);
      v27[5] = objc_msgSend_initWithCapacity_(v29, v30, v28);
      
      // 创建可变数组用于存储占位符
      v31 = (void *)objc_alloc(OBJC_CLASS___NSMutableArray_ptr);
      v27[6] = objc_msgSend_initWithCapacity_(v31, v32, v28);
      
      // 设置系统UI字体标志
      *((_DWORD *)v27 + 16) = v6;
      
      v33 = v27[2];
      v74 = -6148914691236517206LL;
      _X20 = &v74;
      
      // 获取字体URL
      (*(void (__fastcall **)(__int64))(*(_QWORD *)v33 + 200LL))(v33);
      __asm { LDAPR           X8, [X20], [X20] }
      v63 = v27;
      
      // 计算字体URL的哈希值
      if ( _X8 )
      {
        __asm { LDAPR           X0, [X20], [X20] }
        v37 = CFURLGetString(_X0);
        v38 = CFHash(v37);
      }
      else
      {
        _X8 = v33 + 96;
        __asm { LDAPR           X0, [X8], [X8] }
        v41 = objc_retain(_X0);
        v38 = CFHash(v41);
        objc_release(v41);
      }
      objc_release(v74);
      
      // 初始化哈希值
      v42 = v38 + 2654435769LL;
      v62 = objc_msgSend_null(OBJC_CLASS___NSNull_ptr, v43);
      
      // 获取字体名称
      _X8 = v8 + 96;
      __asm { LDAPR           X0, [X8], [X8] }
      v65 = objc_retain(_X0);
      
      // 初始化枚举状态
      v68 = 0u;
      v69 = 0u;
      v70 = 0u;
      v71 = 0u;
      
      // 开始枚举字体描述符
      v47 = objc_msgSend_countByEnumeratingWithState_objects_count_(v64, v46, &v68, &v74, 16LL);
      if ( v47 )
      {
        v48 = v47;
        v49 = *(_QWORD *)v69;
        do
        {
          v50 = 0LL;
          do
          {
            // 检查枚举是否被修改
            if ( *(_QWORD *)v69 != v49 )
              objc_enumerationMutation(v64);
              
            // 获取当前字体描述符
            v51 = *(_QWORD *)(*((_QWORD *)&v68 + 1) + 8LL * (_QWORD)v50);
            
            // 复制字体属性
            TDescriptor::CopyAttribute(*(TDescriptor **)(v51 + 40), 1uLL, (const __CFString *)0x10000000201EC8LL);
            _X8 = &v67;
            __asm { SWPAL           XZR, X26, [X8] }
            objc_release(v67);
            
            // 比较字体名称
            v54 = objc_retain(v65);
            v55 = objc_retain(_X26);
            v56 = v55;
            if ( v54 == v55 )
            {
              objc_release(v55);
              objc_release(v54);
            }
            else
            {
              if ( v54 && v55 )
              {
                v57 = CFEqual(v54, v55);
                objc_release(v56);
                objc_release(v54);
                if ( v57 )
                  goto LABEL_27;
              }
              else
              {
                objc_release(v55);
                objc_release(v54);
              }
              
              // 更新哈希值
              v42 ^= (v42 << 6) + 2654435769u + (v42 >> 2) + CFHash(_X26);
              
              // 添加字体描述符到数组
              objc_msgSend_addObject_((void *)v63[5], v58, v51);
              objc_msgSend_addObject_((void *)v63[6], v59, v62);
              ++v63[4];
            }
LABEL_27:
            objc_release(_X26);
            v50 = (char *)v50 + 1;
          }
          while ( v48 != v50 );
          
          // 继续枚举
          v48 = objc_msgSend_countByEnumeratingWithState_objects_count_(v64, v60, &v68, &v74, 16LL);
        }
        while ( v48 );
      }
      
      // 设置最终哈希值和字体特性
      v20 = (__int64)v63;
      v63[7] = v42;
      v63[3] = (*(__int64 (**)(void))(*(_QWORD *)v63[2] + 800LL))();
      objc_release(v65);
    }
    else
    {
LABEL_33:
      v20 = 0LL;
    }
  }
  else
  {
    objc_release(0LL);
  }
  
  // 设置输出参数并清理资源
  *v9 = v20;
  result = objc_release(v66);
  *(_QWORD *)__stack_chk_guard_ptr;
  return result;
}