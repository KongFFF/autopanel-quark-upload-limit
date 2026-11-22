# 证据与构建记录

本文记录[逆向实录](reverse-engineering.md)中重要结论的出处，方便继续研究时核对。主文按有效操作顺序编排，原始会话顺序与正文顺序不必一致。

## 材料与页码

主要材料是作者提供的《夸克网盘上传失败排查》会话导出：PDF 导出于 2026 年 11 月 22 日 17:00，Markdown 导出于 16:59。实际排查与修补记录集中在 2026 年 11 月 19 日。PDF 保留了上传的 Ghidra 截图，Markdown 便于检索代码与命令。

下表的 PDF 页码指 **removed.pdf 文件内从 1 开始的实际页序**。该文件有 492 页，页面印刷页脚仍使用原导出的 501 页编号，后段会出现偏移。按消息时间也可以找到对应内容。

| 结论或步骤 | 原会话消息时间，2026 年 11 月 19 日 | PDF 实际页序或核对材料 |
| --- | --- | --- |
| 初始报错包含 4.0 GiB 与 EXP_SVIP | 11:07:34 | 第 1 页及后续报错文字 |
| 原程序 UPX 检测通过，解压后为 56,922,528 字节 ELF | 13:52:05、13:52:48 | 第 113–114 页附近，命令输出 |
| Windows GoReSym 函数解析与参数帮助 | 14:16:16 至 14:18:24 | 第 134–135 页附近；本地保留的 `autopanel-analysis.json` |
| Java 与 Ghidra 的实际版本 | 14:57 附近至 15:30:40 | 会话中 `java -version`、安装文件名及 Ghidra 日志 |
| 自动分析的成功设置 | 15:36:01 | 第 167 页，Golang Symbols 选项截图 |
| MaxUploadSize 完整会员映射 | 15:56:22 | 第 178 页开始的用户粘贴代码 |
| upPre 请求路径、字段及 int64 大小 | 16:00:43 | 用户粘贴的完整 `upPre` 代码 |
| HTTP 90 秒默认分支与 DefaultClient 例外 | 17:04:01 | 第 269–270 页附近的 `BuildHTTPClient` 代码 |
| UserMemberResp 与 Quota 类型恢复 | 20:02:31 | 用户粘贴的类型；本地保留的 `quark-structs.txt` |
| UploaderChecker 的业务 CALL 位于 00F3B1D2 | 21:32:21 | 第 424 页，References 窗口截图 |
| quarkSvc.Upload 的检查次序、15 字节最小值 | 21:34:21 | 第 429 页开始的完整调用方代码 |
| quarkSvc 字段布局 | 21:43:53 | 第 433 页，Structure Editor 截图 |
| RefreshInfo 赋值与 UserInfo 的 300 秒缓存 | 21:48:04 | 第 438 页开始的用户粘贴代码 |
| /member 响应解析和容量字段复制 | 21:51:31 | 第 446 页开始的 `QuarkApi.Quota` 代码 |
| UserMemberResp 类型描述符确认 | 21:57:56 | 第 451 页，类型注释与交叉引用截图 |
| UploaderChecker 完整比较与错误构造 | 22:08:10 | 第 464 页开始的用户粘贴代码 |
| Uploader 的文件准备与 Upload 调用主干 | 22:09:20 后的回答 | 第 466 页附近；完整上传代码附件未包含在导出正文中 |
| 4 GiB → 16 GiB 修改与 Original File 导出方法 | 22:12:14 | 第 468–470 页附近 |
| Windows 原版、补丁及 Linux 补丁 SHA-256 | 22:25:11、22:26:20 | 第 472 页起的终端输出 |
| 独立 SSH 切换后，约 10 GiB 文件开始正常上传 | 22:41:49 | 第 490 页的用户反馈 |

本次整理另对本地 `de4b…15fc2` 解压版和仓库中的 `0c5a…5547d` 补丁进行了完整字节比较，并按 ELF LOAD 段确认地址映射。这是本次整理新增的静态核验，不是原会话当时已经输出的比较结果。

## 可公开复查的附件

- [函数索引](evidence/functions.json)：从保留的 GoReSym 结果中按完整名称筛选，附构建哈希与十六进制入口。
- [结构体记录](evidence/quark-structs.txt)：保留的 UserMemberResp 和 Quota 类型节选，转存为 UTF-8。
- [补丁差异](evidence/binary-diff.json)：两个文件的哈希、大小和全部差异字节。
- [Go 分析选项截图](images/ghidra-analysis-options.png)：PDF 实际第 167 页。
- [UploaderChecker 调用引用截图](images/uploader-checker-references.png)：PDF 实际第 424 页。
- [quarkSvc 结构体截图](images/quark-service-structure.png)：PDF 实际第 433 页。

这三张图片从 PDF 中直接提取，未重绘。仓库未包含完整私人会话、Cookie、账号工作目录或整份大型类型 JSON。

## 结论的适用范围

会员映射、比较边界、15 字节最小值、300 秒缓存和 HTTP 默认超时分支来自用户粘贴的反编译代码。补丁修改点还经过本地二进制差异核验。正文中的 Go 代码为语义等效改写，并非可直接重新构建 AutoPanel 的完整源码。

原会话明确记录的运行结果是约 10 GiB 文件“开始正常上传”；作者在本次整理需求中进一步说明原实例覆盖后成功解决。现有材料没有收录完整上传完成日志、远端校验和或 200 GB 边界测试，因此不将它们写成已完成的测试。

`QuarkApi.Upload()` 内部的全部分片、重试和完成确认流程未在该会话中分析完。`quark.Uploader()` 的原代码附件在两种导出中显示为占位，正文只采用该轮回答已经记录的调用主干。今后若继续研究这些分支，应以二进制重新反编译核对。

## 工具参考

- [UPX 5.3.0 官方发布页](https://github.com/upx/upx/releases/tag/v5.3.0)
- [GoReSym 用法与参数](https://github.com/mandiant/GoReSym#usage)
- [Ghidra 12.2 安装要求](https://github.com/NationalSecurityAgency/ghidra/blob/Ghidra_12.2_build/GhidraDocs/GettingStarted.md)
- [Ghidra Original File 导出说明](https://github.com/NationalSecurityAgency/ghidra/blob/Ghidra_12.2_build/Ghidra/Features/Base/src/main/help/help/topics/ExporterPlugin/exporter.htm#original_file)
