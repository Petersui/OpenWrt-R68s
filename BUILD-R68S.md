# R68S（电犀牛 FastRhino）LEDE 固件自动编译

给你截图里那套配置：LEDE master + istore 应用商店 + Docker，产物是可直接刷的 `sysupgrade.img.gz`。

## 目录结构

```
r68s-build/
├── .github/workflows/build-r68s.yml   # GitHub Actions 工作流（云端编译）
├── configs/r68s.config                # 编译配置（target + 包选择）
├── scripts/diy-part1.sh               # 加 istore 源
└── scripts/diy-part2.sh               # 改管理地址/主机名/root 密码
```

## 固件规格

| 项 | 值 |
|---|---|
| 硬件 | FastRhino R68S（RK3568，LEDE 子型号 `fastrhino_r68s`） |
| 源码 | coolsnowwolf/lede，master 分支 |
| 系统 | LuCI + squashfs |
| 商店 | istore（linkease 官方源，`luci-app-store` + taskd） |
| 容器 | docker + dockerd + docker-compose + LuCI Dockerman |
| 管理地址 | http://192.168.6.1 |
| 登录 | root / password |
| 产物 | `bin/targets/rockchip/armv8/*squashfs-sysupgrade.img.gz` |

## 怎么跑起来（三种方式任选）

### A. 推到你的 GitHub 仓库，Actions 点一下

1. 建一个仓库（私有/公开都行），把本目录所有文件（含 `.github/`）传上去
2. Actions 页 → 选 `Build LEDE for FastRhino R68S` → Run workflow
3. 等 60-90 分钟，编完自动出 Release（含 `.img.gz`），去 Releases 页下载

### B. 用 token 由我全部代办

需要的 token 权限（Fine-grained PAT，只勾这一个仓库）：

- Contents: Read and write
- Actions: Read and write
- Workflows: Read and write
- Metadata: Read-only（自动带上）

我做的事：建分支 → 推这 4 个文件 → 触发 `workflow_dispatch` → 轮询任务状态 → 编完下载 `sysupgrade.img.gz` 交给你。

### C. 自己的 Linux 机器本地编

```bash
sudo apt install -y build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
  gettext git libncurses5-dev libssl-dev python3-setuptools rsync swig unzip zlib1g-dev \
  file wget libelf-dev
git clone --depth 1 -b master https://github.com/coolsnowwolf/lede
cd lede && cp ../configs/r68s.config .config
bash ../scripts/diy-part1.sh && ./scripts/feeds update -a && ./scripts/feeds install -a
bash ../scripts/diy-part2.sh && make defconfig
make -j$(nproc) download && make -j$(nproc)
```

## 刷机

**SD 卡（最省事）**：解压 `.img.gz` 得到 `.img`，用 balenaEtcher / `dd` 写到卡，插卡上电。
**eMMC（保留原系统可回退）**：板子进 maskrom 模式，用 `rkdeveloptool`：

```bash
rkdeveloptool ld                                  # 识别设备
rkdeveloptool db rk3568_spl_loader_*.bin          # 下载 loader
rkdeveloptool wl 0 r68s-....img                   # 整盘写入
rkdeveloptool rd                                  # 重启
```

`rkdeveloptool` 本机已装（`/usr/local/bin/rkdeveloptool`，`-V` 可验证）。

## 已知注意点

- **Docker + fw4**：LEDE 新版防火墙是 nftables，Docker 起容器若报 iptables 错，LuCI 里把防火墙后端/`dockerd` 的 iptables 选项调成 nft 兼容，或关掉 fw4 的 `nftables` 严格模式。
- **首次启动**：约 2-3 分钟，期间不要断电。
- **U-Boot**：`sysupgrade.img.gz` 是从 SD/已有系统升级用；纯空 eMMC 首次刷建议走 maskrom + rkdeveloptool 整盘写入。
