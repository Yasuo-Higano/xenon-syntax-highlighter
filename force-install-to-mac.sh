#!/bin/bash

set -e

# 1. VSIXファイルのパスを受け取る
if [ -z "$1" ]; then
  echo "Usage: $0 path/to/your-extension.vsix"
  exit 1
fi

VSIX_PATH="$1"

# 2. VSIXファイルが存在するか確認
if [ ! -f "$VSIX_PATH" ]; then
  echo "Error: file '$VSIX_PATH' not found."
  exit 1
fi

# 3. 一時作業ディレクトリ
TMP_DIR=$(mktemp -d)

# 4. VSIXを展開
unzip -q "$VSIX_PATH" -d "$TMP_DIR"

# 5. macOS上のCursor拡張ディレクトリ（デフォルト）
CURSOR_EXT_DIR="$HOME/Library/Application Support/Cursor/extensions"
mkdir -p "$CURSOR_EXT_DIR"

# 6. 拡張名とコピー先ディレクトリを取得
EXT_NAME=$(basename "$VSIX_PATH" .vsix)
TARGET_DIR="$CURSOR_EXT_DIR/$EXT_NAME"

# 7. 既存の同名拡張があれば削除
if [ -d "$TARGET_DIR" ]; then
  echo "Removing existing extension: $TARGET_DIR"
  rm -rf "$TARGET_DIR"
fi

# 8. 展開された中身のうち、extension/ フォルダがある場合、それをコピー
if [ -d "$TMP_DIR/extension" ]; then
  cp -r "$TMP_DIR/extension" "$TARGET_DIR"
else
  cp -r "$TMP_DIR" "$TARGET_DIR"
fi

echo "✅ Installed extension to: $TARGET_DIR"

# 9. 後始末
rm -rf "$TMP_DIR"

echo "🔁 Please restart Cursor to apply the extension."
