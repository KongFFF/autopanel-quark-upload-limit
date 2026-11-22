# 安装、验证与回滚

适用于运行在 Linux x86_64、由 Supervisor 管理的这一对 AutoPanel 构建。脚本以文件 SHA-256 识别构建，AutoPanel 的发行版本号和镜像标签尚未确认。

| 项目 | 脚本要求 |
| --- | --- |
| 运行身份 | root |
| 目标文件 | `/usr/bin/autopanel`，必须是普通文件且不能是符号链接 |
| 本地服务 | Supervisor 任务 `autopanel`，Socket 为 `unix:///tmp/supervisor.sock` |
| 原始文件 SHA-256 | `fd3a94c9c0173df78b62703f26946559793e9a43365b335df57e0c270f8e16ed` |
| 修复文件 SHA-256 | `0c5add05dba0575411b3c8f43812e194c4c7ef3ea1003a8b36a6a196ad05547d` |
| 修复文件默认路径 | `/root/autopanel-test16g/autopanel.unpacked` |
| 原始文件备份 | `/root/autopanel-backup/autopanel.original` |

## 安装

先准备上表所列的[修复文件](https://github.com/KongFFF/autopanel-quark-upload-limit/raw/refs/heads/main/autopanel.unpacked)和[安装脚本](../autopanel-fix.sh)。当前补丁将未知会员类型的默认上限从 4 GiB 调到 16 GiB，并非 200 GB 补丁；具体修改与生成过程见[逆向实录](reverse-engineering.md)。请使用独立 SSH 会话，等正在进行的任务完成后，再到运行 AutoPanel 的环境中以 root 身份执行。将示例路径替换为实际路径。

```bash
sha256sum /usr/bin/autopanel /path/to/autopanel.unpacked
bash autopanel-fix.sh install /path/to/autopanel.unpacked
```

若修复文件已放在默认路径，可执行 `bash autopanel-fix.sh install`。脚本在换入前检查文件哈希、架构、动态依赖和 Supervisor 状态。输入 `YES` 后，脚本停止服务，在同一目录内替换可执行文件，再启动服务。

## 验证

看到 `Executable checksum verified.` 表示脚本已确认 Supervisor 任务运行，并从 `/proc/<PID>/exe` 验证了正在运行的文件。随后打开 Web UI，用相同账号和上传路径复测原先失败的文件，确认上传完成及远端文件大小。记录测试文件的字节数和结果，方便在同一构建上复现。原会话记录了约 10 GiB 的 `model_world_size_1_rank_0.pt` 开始正常上传，作者后续确认原实例问题已解决；现有材料未收录完整完成日志或更大文件的边界测试。

## 回滚

在 Supervisor 中的 `autopanel` 任务运行时执行，下线任务前同样需要输入 `YES`。

```bash
bash autopanel-fix.sh rollback
sha256sum /usr/bin/autopanel
supervisorctl -s unix:///tmp/supervisor.sock status autopanel
```

回滚成功后，文件 SHA-256 应与上表的原始值一致，服务应为 `RUNNING`。安装切换异常时，脚本会尝试恢复备份并重启。回滚切换异常时，脚本会尝试重启并以失败状态退出，此时需实际检查磁盘上的文件哈希和服务状态。
