/*
 * 文件：IsSystemUIFontAndForShaping.s
 * 描述：字体回退系统中的字体检查函数
 * 功能：检查字体是否为系统UI字体且用于文本整形
 * 作者：逆向工程分析
 * 日期：2024
 */

/*
 * 函数：TFont::IsSystemUIFontAndForShaping
 * 参数：
 *   this - TFont对象指针
 *   a2   - 输出参数，存储是否为整形字体的布尔值
 * 返回值：
 *   成功返回1，失败返回0
 * 功能：
 *   检查当前字体是否为系统UI字体，并且该字体用于文本整形处理
 *   这对于字体回退机制很重要，因为系统UI字体需要特殊处理
 */
__int64 __fastcall TFont::IsSystemUIFontAndForShaping(TFont *this, bool *a2)
{
  bool *v2; // x19 - 保存输出参数指针
  TFont *v9; // x20 - 保存this指针
  int v11; // w21 - 存储字体选项标志
  bool v12; // w8 - 临时布尔值
  __int64 result; // x0 - 函数返回值

  v2 = a2;  // 保存输出参数指针
  _X8 = (char *)this + 16;  // 获取字体描述符指针偏移
  __asm { LDAPR           X9, [X8], [X8] }  // 加载字体描述符
  if ( !_X9 )  // 检查字体描述符是否为空
    goto LABEL_8;  // 如果为空，跳转到失败处理
  v9 = this;  // 保存this指针
  __asm { LDAPR           X8, [X8], [X8] }  // 再次加载字体描述符
  v11 = *(_DWORD *)(*(_QWORD *)(_X8 + 40) + 16LL);  // 获取字体选项标志
  if ( (unsigned int)TDescriptor::GetSystemUIFontOptions(this) & v11 )  // 检查是否为系统UI字体
  {
    // 检查字体是否用于文本整形（位5表示整形标志）
    v12 = (*((_BYTE *)v9 + 12) & 0x20) == 0;
    result = 1LL;  // 返回成功
  }
  else
  {
LABEL_8:
    v12 = 0;  // 设置为非整形字体
    result = 0LL;  // 返回失败
  }
  *v2 = v12;  // 设置输出参数
  return result;  // 返回结果
}

/*
 * 技术说明：
 * 
 * 1. 函数用途：
 *    - 此函数是字体回退系统的重要组成部分
 *    - 用于判断字体是否为系统UI字体以及是否用于文本整形
 *    - 系统UI字体在字体回退时需要特殊处理
 * 
 * 2. 关键检查点：
 *    - 字体描述符有效性检查
 *    - 系统UI字体选项检查（通过TDescriptor::GetSystemUIFontOptions）
 *    - 文本整形标志检查（位5，0x20）
 * 
 * 3. 返回值含义：
 *    - 返回值1：字体是系统UI字体
 *    - 返回值0：字体不是系统UI字体或描述符无效
 *    - 输出参数：指示字体是否用于文本整形
 * 
 * 4. 在字体回退中的作用：
 *    - 帮助系统选择合适的回退字体
 *    - 确保UI文本的正确显示
 *    - 支持多语言文本的正确整形
 * 
 * 5. 逆向工程注意事项：
 *    - 此代码来自macOS字体系统的逆向分析
 *    - 使用了ARM64汇编指令
 *    - 涉及Core Text框架的内部实现
 */