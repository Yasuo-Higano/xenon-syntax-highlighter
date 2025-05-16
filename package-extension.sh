#!/bin/bash

# エラー時に中断
set -e

# 現在の日時を取得してバージョン名に使用
DATE=$(date +"%Y%m%d%H%M")
VERSION=$(grep '"version"' package.json | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d ' ')
PKG_NAME=$(grep '"name"' package.json | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d ' ')
VSIX_NAME="${PKG_NAME}-${VERSION}.vsix"

echo "===== Xenon Syntax Highlight 拡張機能パッケージ作成 ====="
echo "バージョン: ${VERSION}"
echo "パッケージ名: ${VSIX_NAME}"

# 出力フォルダがなければ作成
mkdir -p dist

# ソースコードをクリーンビルド
echo "ソースコードをコンパイルしています..."
rm -rf out
mkdir -p out
npm run compile

# SVGのアイコンがあれば変換（オプション）
if [ -f "icons/xenon-dark.png" ] && [[ $(file icons/xenon-dark.png) == *"SVG"* ]]; then
  echo "SVGアイコンをPNGに変換しています..."
  if command -v convert &> /dev/null; then
    convert icons/xenon-dark.png icons/xenon-dark.png
    convert icons/xenon-light.png icons/xenon-light.png
  else
    echo "警告: ImageMagickがインストールされていないため、SVG→PNG変換をスキップします"
  fi
fi

# 拡張機能のパッケージ化
echo "拡張機能をパッケージ化しています..."
vsce package --no-yarn -o "dist/${VSIX_NAME}" --baseContentUrl https://github.com/yourusername/xenon-syntax-highlight || {
  echo "パッケージ化に失敗しました。警告を無視して強制的にパッケージ化します..."
  vsce package --no-yarn -o "dist/${VSIX_NAME}" --baseContentUrl https://github.com/yourusername/xenon-syntax-highlight --allow-missing-repository
}

echo "パッケージが dist/${VSIX_NAME} に作成されました"
echo "完了!" 