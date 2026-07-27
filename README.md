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
tpkg token <github_token>
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

交互式选择更新：

```sh
tpkg update
```

只更新某一个软件包时，也会进入交互确认：

```sh
tpkg update luci-app-lucky
```

交互界面里：

- `↑/↓` 或 `j/k`：移动
- 空格：选中/取消
- `a`：全选
- `n`：全不选
- 回车：更新选中的包
- `q`：退出

如果系统没有 `stty`，会自动切换到编号输入模式：

- 输入 `1 3 5`：切换这些编号的选中状态
- `a`：全选
- `n`：全不选
- `y` 或直接回车：更新选中的包
- `q`：退出

交互模式会列出所有能识别到远端 APK 的包。`NEW` 和 `UPDATE` 默认选中，`OK` 默认不选；如果手动选中 `OK`，会重新下载安装，用于测试或修复本地文件。

只检查某一个软件包：

```sh
tpkg check luci-app-lucky
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

```yaml
apk_dir: /mnt/sdc1/OpenWrt/apk
download_dir: /tmp/tpkg-downloads
keep_backup: 1
arch_priority: x86_64, all, any
github_token:
```

`github_token` 是必填项，用来避免 GitHub API 很快触发 `403` 限流。安装后用命令写入：

```sh
tpkg token github_pat_xxx
```

这个命令会更新 `/etc/config/tpkg`，并把配置文件权限改成 `600`。也可以临时用环境变量：

```sh
GITHUB_TOKEN=github_pat_xxx tpkg check
```

## 获取 GitHub Token

建议使用 Fine-grained personal access token：

1. 打开 GitHub Token 页面：
   `https://github.com/settings/personal-access-tokens/new`
2. `Token name` 随便写，例如 `tpkg`
3. `Expiration` 选择一个有效期，例如 90 天或 1 年
4. `Repository access` 选择只访问公开仓库；如果页面要求选择资源范围，保持最小范围即可
5. `Permissions` 不需要额外开启写权限；这个工具只读取 public release 信息
6. 点击 `Generate token`
7. 复制生成的 token，在路由器上执行：

```sh
tpkg token github_pat_xxx
```

GitHub token 只会显示一次，生成后请马上保存。`tpkg config` 不会显示明文 token，只会显示是否已设置。

软件包配置在 `packages:` 下，每个软件包写成一段。通常只需要写 `name` 和 `release`：

```yaml
packages:
  - name: 包名
    release: GitHub Release 地址
```

例如：

```yaml
packages:
  - name: bandix-plus
    release: https://github.com/timsaya/openwrt-bandix-plus/releases

  - name: luci-app-bandix-plus
    release: https://github.com/timsaya/luci-app-bandix-plus/releases

  - name: lucky
    release: https://github.com/sirpdboy/luci-app-lucky/releases
```

默认匹配规则：

- 只匹配以 `包名-` 开头的 `.apk` 文件
- 不会下载 `.ipk`
- 如果同一个 release 里有多个匹配文件，按 `arch_priority` 从左到右选择
- 默认优先级是 `x86_64, all, any`

如果遇到特殊仓库，也可以在 package 里加可选的 `match`：

```yaml
  - name: bandix-plus
    release: https://github.com/timsaya/openwrt-bandix-plus/releases
    match: '^bandix-plus-.*_x86_64\.apk$'
```

还有两个特殊可选字段：

```yaml
  - name: lucky
    release: https://github.com/sirpdboy/luci-app-lucky/releases
    archive: '^SNAPSHOT-x86_64\.tar\.gz$'

  - name: uuplugin
    release: https://github.com/ttc0419/uuplugin/releases
    release_mode: semver
```

- `archive`：远端 release 提供的是 `.tar.gz`，APK 在压缩包里时使用。`tpkg` 会下载压缩包，按包名和架构优先级从里面挑 `.apk`
- `release_mode: semver`：不用 GitHub 的 `/latest`，而是从 release 列表里选择第一个 `v数字` tag，适合 `latest` tag 不是最新版本的仓库

`arch_priority` 支持：

- `x86_64`：远端文件必须以 `_x86_64.apk` 或 `-x86_64.apk` 结尾
- `all`：远端文件必须以 `_all.apk` 或 `-all.apk` 结尾
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
