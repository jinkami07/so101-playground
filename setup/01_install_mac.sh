#!/bin/bash
# Mac用 LeRobotセットアップ (SO-101 + SmolVLA)
# 実行: bash setup/01_install_mac.sh

set -e

echo "=== LeRobot セットアップ開始 (Mac M-series) ==="

# 1. uv確認
echo "[1/5] uv を確認..."
if ! command -v uv &>/dev/null; then
    echo "  uv が見つかりません。インストールします..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.local/bin/env"
fi

# 2. venv作成
echo "[2/5] venv '.venv' を作成..."
uv venv --python 3.12
source .venv/bin/activate

# 3. ffmpegのインストール (Homebrew)
echo "[3/5] ffmpeg をインストール..."
if ! command -v ffmpeg &>/dev/null; then
    brew install ffmpeg
else
    echo "  ffmpeg は既にインストール済み"
fi

# 4. LeRobotのクローン & インストール
echo "[4/5] LeRobotをクローン & インストール..."
if [ ! -d "lerobot" ]; then
    git clone https://github.com/huggingface/lerobot.git lerobot
fi
cd lerobot
uv pip install -e ".[feetech,smolvla]"
cd ..

# 5. HuggingFace CLI ログイン
echo "[5/5] HuggingFace にログイン..."
echo "  → ブラウザでトークンを取得: https://huggingface.co/settings/tokens"
.venv/bin/hf login

echo ""
echo "=== セットアップ完了 ==="
echo "次のステップ:"
echo "  source .venv/bin/activate"
echo "  bash setup/02_find_hardware.sh  # ハードウェア接続確認"
