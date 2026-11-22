# Ghidra 定位路线

完整操作与分析已整理为[逆向 AutoPanel 夸克网盘上传逻辑并修复 4 GiB 限制](reverse-engineering.md)。

主要路线是：提取 `/usr/bin/autopanel` → UPX 解压副本 → GoReSym 导出函数与类型 → Ghidra 导入 ELF 并分析 → 打开 `UploaderChecker` → 查看业务 CALL → 追踪 `Quota.MemberType` 来源 → 修改并核对两处默认常量。

该构建没有收录 `EXP_SVIP`，直接搜索这个字符串未必能找到入口。应优先搜索 `UploaderChecker`、`MaxUploadSize` 或完整超限错误文本，并核对包路径。

具体函数地址、参数值和修改状态见[参数索引](parameters.md)，构建哈希和原始记录出处见[证据与构建记录](evidence.md)。
