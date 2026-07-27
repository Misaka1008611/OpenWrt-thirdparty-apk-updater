# OpenWrt 第三方 APK 更新检查工具

`tpkg` 是一个给 ImmortalWrt / OpenWrt 用的小工具，用来检查 GitHub Releases 上的第三方 `.apk` 包是否有更新，并在确认后下载替换到指定目录。

它是纯 Shell 脚本，目标是兼容路由器上的 `ash`，只依赖 `curl` 或 `wget`，以及系统常见的 `sed`、`awk`、`find`。

## 功能

- 检查本地 APK 和 GitHub 最新 Release 里的 APK 文件名是否一致
- 发现新版本时显示本地文件、远端文件、release tag 和下载地址
- 支持 `check`、`update`、`install`、`list`、`config`
- 下载成功后才替换本地文件
- 默认把旧文件备份到 `.tpkg-backup`
- 下载前会确认文件后缀是 `.apk`，不会把 `.ipk` 下载回来
- 可以按配置限制架构，例如 `x86_64`、`all`

## 一键安装

可以在路由器上这样安装：

```sh
wget -O- https://raw.githubusercontent.com/Misaka1008611/OpenWrt-thirdparty-apk-updater/main/install.sh | sh
```

如果你的系统没有 `wget`，但有 `curl`：

```sh
curl -fsSL https://raw.githubusercontent.com/Misaka1008611/OpenWrt-thirdparty-apk-updater/main/install.sh | sh
```

默认安装位置：

```sh
/usr/bin/tpkg
/etc/config/tpkg
```

安装后运行：

```sh
tpkg check
```

## 手动安装

```sh
cp tpkg /usr/bin/tpkg
chmod +x /usr/bin/tpkg
cp tpkg.conf /etc/config/tpkg
```

## 使用方法

列出已配置的软件包：

```sh
tpkg list
```

检查全部软件包：

```sh
tpkg check
```

只检查某一个软件包：

```sh
tpkg check luci-app-lucky
```

更新全部软件包：

```sh
tpkg update
```

只更新某一个软件包：

```sh
tpkg update luci-app-lucky
```

跳过确认，直接更新：

```sh
tpkg update -y
```

只预览，不下载、不替换：

```sh
tpkg update -n
```

指定 APK 目录：

```sh
tpkg -d /mnt/sdc1/OpenWrt/apk check
```

## 配置说明

默认配置文件是 `/etc/config/tpkg`。

默认 APK 目录在配置文件里：

```sh
APK_DIR=${APK_DIR:-/mnt/sdc1/OpenWrt/apk}
DOWNLOAD_DIR=${DOWNLOAD_DIR:-/tmp/tpkg-downloads}
KEEP_BACKUP=${KEEP_BACKUP:-1}
```

每个包一行，格式是：

```text
包名|GitHub仓库|APK文件名匹配规则|架构
```

例如：

```text
bandix-plus|timsaya/openwrt-bandix-plus|^bandix-plus-.*_x86_64\.apk$|x86_64
luci-app-bandix-plus|timsaya/luci-app-bandix-plus|^luci-app-bandix-plus-.*_all\.apk$|all
lucky|sirpdboy/luci-app-lucky|^lucky-.*\.apk$|any
```

架构字段支持：

- `x86_64`：远端文件必须以 `_x86_64.apk` 结尾
- `all`：远端文件必须以 `_all.apk` 结尾
- `any`：只要求远端文件是 `.apk`

## 更新逻辑

`tpkg` 不强行解析各种上游版本号，而是比较 APK 文件名：

- 本地文件名和远端最新 Release 的匹配文件名一样：显示 `OK`
- 本地没有该文件：显示 `NEW`
- 文件名不同：显示 `UPDATE`

这样可以兼容这些常见版本格式：

```text
lucky-2.27.2-r1.apk
luci-i18n-lucky-zh-cn-26.021.55893~28c17bc.apk
bandix-plus-0.1.1-r2_x86_64.apk
```

## 当前内置仓库

- `timsaya/openwrt-bandix-plus`
- `timsaya/luci-app-bandix-plus`
- `eamonxg/luci-theme-aurora`
- `eamonxg/luci-app-aurora-config`
- `sirpdboy/luci-app-lucky`
- `wukongdaily/luci-app-run`
- `ttc0419/uuplugin`

## 发布到 GitHub

如果你准备公开这个项目，建议再添加一个 `LICENSE` 文件。个人工具一般可以用 MIT License。
