# HINLINK H28K ImmortalWrt 固件

本仓库用于自动编译 HINLINK H28K（Rockchip RK3528）固件。项目只保存编译配置、构建脚本和板级补丁，不包含 ImmortalWrt 上游源码。

> 仅供个人使用和配置留档，请自行确认硬件适配性。

## 支持版本

| ImmortalWrt 系列 | 补丁目录 | 内容 |
| --- | --- | --- |
| 24.10.x | `patches/24.10/` | RK3528 内核回移 + H28K 板级支持 + U-Boot 2025.10 |
| 25.12.x | `patches/25.12/` | 5 个 H28K 板级补丁 |

补丁只会应用所选版本目录中的 `*.patch` 文件，并按文件名字典序执行。补丁文件名前的编号就是应用顺序。

**已测试版本**: 24.10.5, 24.10.6, 25.12.1

## 版本配置

编辑 [config/firmware.conf](config/firmware.conf) 中的 `release_version`。填写系列号会自动选择该系列最新正式版：

```ini
# 自动选择最新 25.12.x
release_version=25.12
```

填写完整版本号则固定构建指定版本：

```ini
release_version=25.12.1
```

同一文件还控制 LAN 地址、root 密码、默认 LuCI 主题和官方 ABI 校验：

```ini
lan_ip=192.168.0.2
password=your-password
default_theme=fluent
check_official_abi=true
```

`config/packages.conf` 每行定义一个额外的 `git clone` 软件包；`config/hinlink-h28k.config` 保存目标、软件包和分区配置。
构建时使用所选正式版 `feeds.buildinfo` 锁定的官方 feeds 提交。

## 构建脚本

| 脚本 | 职责 |
| --- | --- |
| `scripts/config.sh` | 共享配置读取和校验 |
| `scripts/select_release.sh` | 选择 ImmortalWrt 精确版本或系列最新版 |
| `scripts/apply_patches.sh` | 应用版本目录中的补丁 |
| `scripts/prepare_kernel_config.sh` | 提取官方内核配置；24.10 计算 ABI 时排除 RK3528 时钟选项 |
| `scripts/build_config.sh` | 注入固件参数、启用官方 kmod 源并校验 ABI |

## 默认组件

- `luci-theme-fluent`
- `luci-app-nikki`
- `kmod-mt7921u`
- `openssh-sftp-server`

## 设备信息

- 型号：HINLINK H28K
- SoC：Rockchip RK3528
- 架构：ARMv8 / AArch64
- LAN：`eth0`
- WAN：`eth1`
- 固件设备名：`hinlink_h28k`
