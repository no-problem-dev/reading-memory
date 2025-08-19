#!/bin/sh

# Xcode Cloudがクローン後に実行するスクリプト
# このスクリプトでプロジェクトの場所をXcode Cloudに教える

echo "Setting up Xcode Cloud for subdirectory project..."

# プロジェクトのパスを環境変数として設定
export XCODE_PROJECT_PATH="$CI_WORKSPACE/reading-memory-ios"

# プロジェクトディレクトリの存在確認
if [ ! -d "$XCODE_PROJECT_PATH" ]; then
    echo "Error: Project directory not found at $XCODE_PROJECT_PATH"
    exit 1
fi

echo "Project directory found at: $XCODE_PROJECT_PATH"

# Xcode Cloudの作業ディレクトリを変更
cd "$XCODE_PROJECT_PATH"

# 必要に応じて依存関係の解決
# 例: Swift Package Manager
# swift package resolve

echo "Xcode Cloud setup completed"