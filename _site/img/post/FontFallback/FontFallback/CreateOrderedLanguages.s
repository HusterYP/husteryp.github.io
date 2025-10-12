/*
 * 函数: CreateOrderedLanguages
 * ----------------------------
 * @brief  创建一个有序的语言列表，用于字体后备决策。它会智能地合并和排序来自调用者、App和系统的语言偏好。
 * @param  a1 (__int64)  一个CFArrayRef，包含了调用者指定的语言代码列表。
 * @return (__int64)     返回一个新的、经过排序的CFArrayRef。
 */
__int64 __fastcall CreateOrderedLanguages(__int64 a1)
{
  __int64 v1; // x20
  __int64 v3; // x19
  // ... 其他变量声明 ...

  v1 = a1; // v1 保存调用者传入的语言列表

  // =================================================================
  // 1. 准备三个语言列表源
  // =================================================================

  // 使用 dispatch_once_f 确保 GetOrderedLanguages() 只被执行一次。
  // 这个函数会获取用户在系统“设置”中配置的全局语言列表，并将其缓存在全局变量 qword_229B20 中。
  if ( qword_229B28 != -1 )
    dispatch_once_f(&qword_229B28, 0LL, (dispatch_function_t)GetOrderedLanguages(void)::$_0::__invoke);

  // 创建一个可变数组 v33 (system_langs_copy)，作为系统全局语言列表的一个可修改副本。
  TCFMutableArray::TCFMutableArray(&v33, qword_229B20);

  // 创建一个空的可变数组 v32 (result_array)，用于存放最终排序好的结果。
  v32 = CFArrayCreateMutable(*(_QWORD *)kCFAllocatorDefault_ptr, 0LL, kCFTypeArrayCallBacks_ptr);

  // 获取当前App的语言偏好列表 v3 (app_langs)。
  v3 = CFLocaleCopyPreferredLanguages();

  // 调用一个辅助函数，它会合并 App 语言列表 (v3) 和调用者指定的语言列表 (v1)，
  // 并进行规范化处理，生成一个初步的、有序的“请求语言列表” _X20 (normalized_langs)。
  CreateArrayOfNormalizedLanguagesWithOrder(v3, v1, 0);

  __asm { LDAPR           X20, [X21], [X21] } // 将 normalized_langs 加载到 _X20

  // =================================================================
  // 2. 核心排序算法
  // =================================================================
  // 检查 normalized_langs 是否存在且非空
  if ( _X20 )
  {
    v10 = CFArrayGetCount(_X20);
    if ( v10 )
    {
      // 遍历“请求语言列表” (normalized_langs) 中的每一种语言
      do
      {
        // 获取当前语言 v15 (current_lang)
        v15 = CFArrayGetValueAtIndex(_X20, v12);

        // **核心逻辑**: 检查 current_lang 是否也存在于“系统语言副本” (system_langs_copy) 中
        if ( (unsigned int)CFArrayContainsValue(_X24, 0LL, v18, v15) )
        {
          // **如果存在**，说明这个语言是“高优先级”的（App/调用者和系统都要求）。
          // a. 从“系统语言副本”中移除这个语言，防止后续重复添加。
          v22 = CFArrayGetFirstIndexOfValue(_X24, 0LL, v21, v15);
          CFArrayRemoveValueAtIndex(_X0, v22);

          // b. 将这个高优先级的语言添加到“最终结果数组” (result_array) 的末尾。
          CFArrayAppendValue(_X0, v15);
        }
        ++v12;
      }
      while ( v11 != v12 );
    }
  }

  // =================================================================
  // 3. 组合最终列表
  // =================================================================

  __asm { LDAPR           X20, [X25], [X25] } // 将 system_langs_copy 中“剩余”的语言加载到 _X20
  
  // 将 system_langs_copy 中剩余的语言（即那些仅存在于系统偏好中，但App/调用者未指定的语言）
  // 全部追加到 result_array 的末尾。
  CFArrayAppendArray(_X21, _X20, 0LL, v28);

  // ... 清理和释放所有临时创建的对象 ...
  objc_release(v31);
  objc_release(v3);
  objc_release(v32);
  objc_release(v33);
  
  // 返回最终构建好的、有序的语言列表 (result_array)
  return _X20;
}