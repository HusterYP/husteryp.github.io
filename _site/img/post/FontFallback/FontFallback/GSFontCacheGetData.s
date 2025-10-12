/*
 * 文件：GSFontCacheGetData.s
 * 描述：字体缓存数据获取函数
 * 功能：根据指定的键值从字体缓存中获取相应的字体数据
 * 作者：逆向工程分析
 * 日期：2024
 */

/*
 * 函数：GSFontCacheGetData
 * 参数：
 *   a1 - 字体缓存键值（NSString对象）
 *   a2 - 备用参数（可能用于特定查询）
 * 返回值：
 *   返回对应的字体数据结构指针
 * 功能：
 *   从系统字体缓存中根据键值获取特定的字体数据
 *   支持多种预设字体回退配置的查询
 */
void *__fastcall GSFontCacheGetData(void *a1, const char *a2)
{
  void *v2; // x19 - 保存输入键值
  const char *v3; // x1 - 临时字符串指针
  __int64 *v4; // x8 - 字体回退数据指针
  const char *v5; // x1 - 临时字符串指针
  const char *v7; // x1 - 临时字符串指针
  const char *v8; // x1 - 临时字符串指针
  __CFString *v9; // x2 - Core Foundation字符串对象

  v2 = a1;  // 保存输入键值
  // 检查是否为默认字体回退键值
  if ( (unsigned int)objc_msgSend_isEqualToString_(a1, a2, &stru_6BEB8) )
  {
    v4 = &kDefaultFontFallbacks;  // 获取默认字体回退配置
    return (void *)*v4;
  }
  // 检查是否为Core Text预设字体回退键值
  if ( (unsigned int)objc_msgSend_isEqualToString_(v2, v3, &stru_6BED8) )
  {
    v4 = &CTPresetFallbacks;  // 获取Core Text预设字体回退配置
    return (void *)*v4;
  }
  // 检查是否为特定字体缓存键值（stru_6BEF8）
  if ( !((unsigned __int64)objc_msgSend_isEqualToString_(v2, v5, &stru_6BEF8) & 1) )
  {
    // 检查不同的字体缓存键值
    if ( (unsigned int)objc_msgSend_isEqualToString_(v2, v7, &stru_6BF18) )
    {
      v9 = &stru_6BF38;  // 设置对应的字符串引用
    }
    else if ( (unsigned int)objc_msgSend_isEqualToString_(v2, v8, &stru_6BF58) )
    {
      v9 = &stru_6BF78;  // 设置对应的字符串引用
    }
    else
    {
      // 检查最后一个预定义键值
      if ( !(unsigned int)objc_msgSend_isEqualToString_(v2, v8, &stru_6BF98) )
        // 如果都不匹配，使用通用字典查找
        return objc_msgSend_objectForKey_(&unk_1EB8F0, v8, v2);
      v9 = &stru_6BFB8;  // 设置最后一个字符串引用
    }
    // 使用键值下标方式获取字体缓存数据
    return objc_msgSend_objectForKeyedSubscript_(&unk_1EB8F0, v8, v9);
  }
  // 返回默认字体缓存对象
  return &unk_1EB8F0;
}

/*
 * 技术说明：
 * 
 * 1. 函数用途：
 *    - 这是字体缓存系统的核心查询函数
 *    - 根据不同的键值返回相应的字体回退配置数据
 *    - 支持多种预定义的字体回退策略
 * 
 * 2. 支持的键值类型：
 *    - stru_6BEB8: 默认字体回退配置
 *    - stru_6BED8: Core Text预设字体回退配置
 *    - stru_6BEF8: 特定字体缓存配置
 *    - stru_6BF18: 字体缓存配置类型1
 *    - stru_6BF58: 字体缓存配置类型2
 *    - stru_6BF98: 字体缓存配置类型3
 *    - 其他: 通过字典查找机制处理
 * 
 * 3. 数据结构：
 *    - kDefaultFontFallbacks: 默认字体回退列表
 *    - CTPresetFallbacks: Core Text预设字体回退列表
 *    - unk_1EB8F0: 字体缓存字典对象
 * 
 * 4. 查找策略：
 *    - 优先使用预定义的键值匹配
 *    - 使用objc_msgSend_isEqualToString_进行字符串比较
 *    - 对于未匹配的键值，使用通用字典查找
 *    - 支持键值下标访问方式
 * 
 * 5. 在字体回退系统中的作用：
 *    - 为字体回退机制提供配置数据源
 *    - 支持不同场景下的字体回退策略
 *    - 优化字体查找性能
 * 
 * 6. 逆向工程注意事项：
 *    - 使用了Objective-C运行时消息发送机制
 *    - 涉及Core Foundation和Core Text框架
 *    - 字符串常量地址需要运行时解析
 *    - 字体缓存数据结构复杂，需要进一步分析
 */