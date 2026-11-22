# AutoPanel 参数索引

本表对应[构建记录](evidence.md)中的 Linux amd64 解压版 `de4b…15fc2`，地址均为该 ELF 的虚拟地址。操作方法见[逆向实录](reverse-engineering.md)。“已定位”表示已在反编译代码中确定作用；只有未知会员默认上限的两处常量实际纳入了仓库补丁。

## 上传大小和会员映射

| 参数或行为 | 函数与入口 | 原值或条件 | 仓库补丁与验证 |
| --- | --- | --- | --- |
| 未识别会员类型的实际上传上限 | `quark.UploaderChecker`，`0x00F2CCA0`；赋值指令 `0x00F2CD9B` | `0x100000000`，4 GiB | 改为 `0x400000000`，16 GiB；二进制差异已核对，原实例约 10 GiB 文件越过检查开始上传 |
| 超限错误中显示的默认额度 | 同一函数；赋值指令 `0x00F2CE77` | `0x100000000`，4 GiB | 同步改为 16 GiB；已核对机器码，未单独记录超过 16 GiB 的运行测试 |
| `vip`、`svip`、`super_vip` 上限 | `Quota.MaxUploadSize`，`0x00F1F240`；以及 `UploaderChecker` 中的分支 | `0x1900000000`，100 GiB | 已定位，未修改；不代表当前官方权益 |
| `zvip`、`svip+`、`z_vip` 上限 | 同上 | `0x3200000000`，200 GiB | 已定位，未修改；未测试 200 GiB 文件 |
| 独立配额方法的默认上限 | `api.Quota.MaxUploadSize`，`0x00F1F240`；指针接收器入口 `0x00F29EC0` | 未识别类型返回 4 GiB | 未修改；不能仅改这处来替代实际上传检查 |
| 大小比较边界 | `quark.UploaderChecker` | `fileInfo.Size() <= limit` 时通过 | 保留；等于上限可以通过此项检查 |
| 上传最小文件大小 | `service.(*quarkSvc).Upload`，`0x00F3B100` | 小于 `0xF` 即 15 字节时返回 `ErrUploadMiniNumSizeLimit` | 已定位，未修改；原会话也记录了 `quark.Uploader` 内的同类检查，应联查 |

上表的函数名省略共同前缀 `apanel/pkg/`；`api` 位于 `quark/api`，`service` 位于 `netdisk/service`。完整名称见[函数索引](evidence/functions.json)。

会员类型先经 `strings.ToLower` 再匹配。`EXP_SVIP → exp_svip` 仍不属于已识别的六种名称。16 GiB 补丁影响所有未识别会员类型，不是针对 `EXP_SVIP` 的精确映射。

## 缓存和 HTTP 配置

| 参数或行为 | 函数与入口 | 已还原的规则 | 修改与验证状态 |
| --- | --- | --- | --- |
| 用户信息缓存有效时间 | `service.(*quarkSvc).UserInfo`，`0x00F3BD20` | 距 `updatedAt` 小于 300 秒时返回缓存，否则调用 `RefreshInfo()` | 已定位，未修改；不是每 300 秒自动执行的后台任务 |
| HTTP 客户端默认超时分支 | `github.com/levigross/grequests.BuildHTTPClient`，`0x007B3CA0` | 在创建自定义客户端的路径上，超时为 0 时使用 `90000000000` 纳秒，即 90 秒 | 已定位，未修改；另有提前返回 `net/http.DefaultClient` 的路径，显式超时也可覆盖，不应认作所有上传请求的统一上限 |
| 请求 Cookie 来源 | `api.(*QuarkApi).Quota`，`0x00F29640`，及 `UserInfo`，`0x00F292C0` | 从 `FsConfig.Cookie` 构造请求头 | 已定位来源；不属于应公开写死的参数 |
| 会员与容量 API 基址和请求参数 | 同上 | `Quota` 使用 `QuarkConf.Api + /member`、`fr`、`pr`；用户信息接口使用配置基址加 `/account/info` | 已定位，未修改；应先追查配置来源 |
| 上传预处理文件大小 | `api.(*QuarkApi).upPre`，`0x00F26380` | 将文件大小作为 int64 写入 `size`，发送 `POST /file/upload/pre` | 已定位；没有在该函数中看到会员大小上限比较 |

例如，要研究超时，应搜索 `BuildHTTPClient`，查看调用方究竟传入什么值、是否命中默认客户端路径，再讨论改默认值。将 90 秒常量改大并不保证每条上传路径都会受影响。

## 尚未确认用途的常量

`quarkSvc.Upload()` 构造 `UploaderParam` 时存在 `puVar3[0x29] = 0x1000000`，即 **16,777,216**，位于参数对象偏移 `0x148`。本次记录尚未将该字段完整关联到最终读取位置，不能仅凭这个数值就称它为“16 MiB 分片大小”或并发参数，也没有对它制作补丁。

继续分析时，可以在 Data Type Manager 或 GoReSym 的类型输出中查找 `quark.UploaderParam`，确定字段名，再追踪 `Uploader()` 和 `QuarkApi.Upload()` 中的消费位置。只有确认单位和调用关系后，才将其移入已定位参数表。

## 会员数据结构定位

| 对象 | 字段 | 对象内偏移 | 含义 |
| --- | --- | --- | --- |
| `service.quarkSvc` | `quota` | `0x20` | 指向 `api.Quota` 的指针 |
| `service.quarkSvc` | `updatedAt` | `0x28` | 用户信息刷新时间 |
| `api.Quota` | `MemberType` | `0x20`、`0x28` | 字符串指针、字符串长度 |
| `api.UserMemberResp` | `Data.MemberType` | `0x28`、`0x30` | 响应中 `data.member_type` 的字符串指针、长度 |

`UserMemberResp` 的运行时类型描述符在本构建中位于 `0x013601A0`。这是类型元数据地址，不是某次请求的响应对象地址。结构节选见[类型记录](evidence/quark-structs.txt)。

## 后续新增记录

新增参数时同时记录构建 SHA-256、函数或字符串入口、真实调用关系、原值与新值、单位、边界条件、机器码差异、测试输入和结果。对于其他构建，重新定位并建立独立记录，不直接沿用本页地址。
