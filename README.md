# AutoPanel 夸克网盘上传上限修复

AutoPanel 未识别夸克网盘的 `exp_svip` 会员类型时，上传可能在本地大小检查处失败。本文记录已在原环境验证成功的修复流程，适用于下方 SHA-256 对应的构建。

当前提供的补丁将未知会员类型的本地默认上限从 **4 GiB 提高到 16 GiB**，不是 200 GB 补丁。约 10 GiB 文件已在原实例越过检查开始上传；会员权益与最终上传许可仍由夸克服务端决定。

想了解这次排查如何完成，可以阅读[逆向实录：从提取文件到还原上传逻辑](docs/reverse-engineering.md)。文中包含 Ghidra 的具体操作、原始截图、会员信息调用链、等效伪代码和两处补丁字节。

## 1. 准备文件并核对构建

在 **运行 AutoPanel 的 Linux x86_64 环境**中，通过独立 SSH 会话以 root 身份执行。先等待正在进行的任务完成，安装会重启 Supervisor 管理的 `autopanel` 服务。

下载 [autopanel-fix.sh](autopanel-fix.sh) 和 [autopanel.unpacked 修复文件](https://github.com/KongFFF/autopanel-quark-upload-limit/raw/refs/heads/main/autopanel.unpacked)，并上传到运行 AutoPanel 的实例。脚本会校验、安装和回滚；修复文件的生成过程见[逆向实录](docs/reverse-engineering.md)。

在脚本所在目录执行以下命令，将示例路径替换成修复文件的实际路径。

```bash
PATCH=/path/to/autopanel.unpacked
sha256sum /usr/bin/autopanel "$PATCH"
```

| 文件 | 预期 SHA-256 |
| --- | --- |
| 原版 `/usr/bin/autopanel` | `fd3a94c9c0173df78b62703f26946559793e9a43365b335df57e0c270f8e16ed` |
| 修复版 `autopanel.unpacked` | `0c5add05dba0575411b3c8f43812e194c4c7ef3ea1003a8b36a6a196ad05547d` |

首次安装前，两项都应和表中一致。若当前可执行文件已经是修复版的哈希，可以直接进行上传验证。遇到其他哈希时，先确认是哪个构建。

## 2. 安装修复

在同一个终端执行以下命令。

```bash
bash autopanel-fix.sh install "$PATCH"
```

脚本检查架构、依赖与服务状态，并将原版备份到 `/root/autopanel-backup/autopanel.original`。输入 `YES` 后，脚本会替换可执行文件并重启服务。显示 `Executable checksum verified.` 表示运行中的进程已通过修复版哈希校验。

## 3. 验证上传

打开 AutoPanel Web UI，用同一个夸克账号、同一目标目录和原先失败的文件重新上传。确认任务完成，并检查网盘上的文件大小与源文件一致。

## 4. 回滚

在服务处于 `RUNNING` 状态时执行以下命令，按提示输入 `YES`。

```bash
bash autopanel-fix.sh rollback
sha256sum /usr/bin/autopanel
```

确认输出的 SHA-256 与上表的原版一致。备份路径、服务状态检查和切换异常时的行为见[安装、验证与回滚详解](docs/install.md)。

## 逆向记录与可修改参数

- [逆向实录](docs/reverse-engineering.md)：提取和解压文件、安装工具、搜索与交叉引用、会员解析与上传检查、制作补丁。
- [可修改参数索引](docs/parameters.md)：会员上限、最小文件大小、缓存时间、HTTP 超时等位置与验证状态。
- [证据与构建记录](docs/evidence.md)：原会话出处、三种文件状态、函数索引、结构体与补丁差异附件。
