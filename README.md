# AutoPanel 夸克网盘上传上限修复

AutoPanel 未识别夸克网盘的 `exp_svip` 会员类型时，上传可能在本地大小检查处失败。本文记录已在原环境验证成功的修复流程，适用于下方 SHA-256 对应的构建。

## 1. 准备文件并核对构建

在 **运行 AutoPanel 的 Linux x86_64 环境**中，通过独立 SSH 会话以 root 身份执行。先等待正在进行的任务完成，安装会重启 Supervisor 管理的 `autopanel` 服务。

准备 [autopanel-fix.sh](autopanel-fix.sh) 和已生成的 `autopanel.unpacked` 修复文件。脚本会校验、安装和回滚。仓库目前尚未提供修复文件或其本地生成步骤，已有对应文件的用户可以继续。

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

- [Ghidra 定位路线](docs/ghidra.md)记录如何从 `exp_svip` 的字符串引用回查上传大小判断。
- [可修改参数索引](docs/parameters.md)记录参数对应的构建、目标文件、函数与验证状态。

目前已确认目标文件及构建哈希。实际修改的函数、阈值与单位、补丁生成步骤，以及其他参数的位置，待补入原始定位记录。
