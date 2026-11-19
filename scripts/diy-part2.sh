#!/bin/bash
# 编译前第二步：本地化定制（在 feeds 安装完成后执行，运行目录：lede/）
set -e

# 1) 管理地址改成 192.168.6.1
sed -i 's/192\.168\.1\.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 2) 主机名 R68S
sed -i 's/OpenWrt/R68S/g' package/base-files/files/bin/config_generate

# 3) root 密码设为 password（md5-crypt 哈希，首启动写入 /etc/shadow）
HASH='$1$HBnVgIRE$JQU7mP2CdO2AdHl1g6lV80'
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-r68s-rootpw <<EOF
#!/bin/sh
[ -f /etc/shadow ] || exit 0
sed -i 's|^root:[^:]*:|root:${HASH}:|' /etc/shadow
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-r68s-rootpw

echo "--- 定制完成：IP 192.168.6.1 / 主机名 R68S / root 密码 password ---"
