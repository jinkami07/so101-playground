#!/bin/bash
# Mac用 LeRobotセットアップ (SO-101 + SmolVLA)
# 実行: bash setup/01_install_mac.sh

set -e

echo "=== LeRobot セットアップ開始 (Mac M-series) ==="

# 1. conda環境の作成
echo "[1/5] conda環境 'so101' を作成..."
conda create -y -n so101 python=3.12

# conda activate はサブシェルでは効かないため eval で初期化
eval "$(conda shell.bash hook)"
conda activate so101

# 2. ffmpegのインストール (conda-forgeから)
echo "[2/5] ffmpeg 7.1.1 をインストール..."
conda install -y ffmpeg=7.1.1 -c conda-forge

# 3. LeRobotのクローン & インストール
echo "[3/5] LeRobotをクローン & インストール..."
if [ ! -d "lerobot" ]; then
    git clone https://github.com/huggingface/lerobot.git lerobot
fi
cd lerobot
pip install -e ".[feetech,smolvla]"
cd ..

# 4. HuggingFace CLI ログイン
echo "[4/5] HuggingFace にログイン..."
echo "  → ブラウザでトークンを取得: https://huggingface.co/settings/tokens"
huggingface-cli login

# 5. 動作確認
echo "[5/5] インストール確認..."
python -c "import lerobot; print(f'LeRobot version: {lerobot.__version__}')"
lerobot-find-port --help > /dev/null 2>&1 && echo "lerobot-find-port: OK" || echo "lerobot-find-port: コマンド確認失敗 (要調査)"

echo ""
echo "=== セットアップ完了 ==="
echo "次のステップ:"
echo "  conda activate so101"
echo "  bash setup/02_find_hardware.sh  # ハードウェア接続確認"
