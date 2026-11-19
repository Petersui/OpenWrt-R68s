#!/bin/bash
# 编译前第一步：追加 istore 应用商店源（linkease 官方源）
# 运行目录：lede/
set -e

if ! grep -q '^src-git istore' feeds.conf.default; then
	echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default
fi

echo "--- feeds.conf.default ---"
cat feeds.conf.default
