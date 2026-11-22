# AutoPanel 夸克网盘上传上限修复

记录 AutoPanel 中夸克网盘 `exp_svip` 会员类型未识别时遇到的本地上传上限问题，以及使用 Ghidra 重新定位相关参数的方法。

用户已在原环境中用 [autopanel-fix.sh](autopanel-fix.sh) 完成修复。脚本负责校验、安装和回滚，它需要另行准备与指定 SHA-256 一致的 `autopanel.unpacked`。仓库目前缺少生成该文件的步骤，已有该文件的用户可按下文安装。

## 文档

| 文档 | 用途 |
| --- | --- |
| [安装、验证与回滚](docs/install.md) | 查看适用构建、命令、备份路径及验证方式 |
| [Ghidra 定位路线](docs/ghidra.md) | 从可执行文件和 `exp_svip` 线索追到上传管线实际使用的阈值 |
| [参数索引](docs/parameters.md) | 按构建查找参数路径、函数、分支、单位及验证状态 |
