#!/bin/bash
# SmolVLA 学習スクリプト (GCP L4 上で実行)
# 実行: bash gcp/train_smolvla.sh
# 前提:
#   - conda activate so101
#   - .env を /workspace にコピー済み (scp .env user@VM:/workspace/)
#   - nvidia-smi で GPU が確認できること

set -e
cd /workspace
source .env 2>/dev/null || {
    echo "エラー: /workspace/.env が見つかりません"
    echo "  scp .env <user>@<VM_IP>:/workspace/.env"
    exit 1
}

# --- 設定確認 ---
echo "=== SmolVLA 学習設定 ==="
echo "  HF_USER       : ${HF_USER}"
echo "  DATASET_NAME  : ${DATASET_NAME}"
echo "  WANDB_PROJECT : ${WANDB_PROJECT}"
echo "  GPU           : $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo 'GPU未検出')"
echo ""

# --- HuggingFace ログイン ---
huggingface-cli login --token "${HUGGINGFACE_TOKEN}" --add-to-git-credential

# --- W&B ログイン ---
wandb login "${WANDB_API_KEY:-$(wandb auth 2>/dev/null)}" 2>/dev/null || wandb login

# --- データセットのキャッシュを事前ダウンロード (任意) ---
echo "データセットを事前ダウンロード中..."
python -c "
from lerobot.common.datasets.lerobot_dataset import LeRobotDataset
ds = LeRobotDataset('${HF_USER}/${DATASET_NAME}')
print(f'  エピソード数: {ds.num_episodes}')
print(f'  フレーム数  : {len(ds)}')
"

# --- SmolVLA 学習 ---
echo ""
echo "=== 学習開始 ==="
OUTPUT_DIR="outputs/train/smolvla_${DATASET_NAME}"

lerobot-train \
    --policy.path=lerobot/smolvla_base \
    --dataset.repo_id="${HF_USER}/${DATASET_NAME}" \
    --batch_size=64 \
    --steps=20000 \
    --output_dir="${OUTPUT_DIR}" \
    --policy.device=cuda \
    --policy.dtype=bfloat16 \
    --policy.gradient_checkpointing=true \
    --policy.repo_id="${HF_USER}/smolvla_${DATASET_NAME}" \
    --wandb.enable=true \
    --wandb.project="${WANDB_PROJECT}"

echo ""
echo "=== 学習完了 ==="
echo "チェックポイント: ${OUTPUT_DIR}/checkpoints/last/pretrained_model"
echo ""
echo "HuggingFace Hub にアップロード済み: https://huggingface.co/${HF_USER}/smolvla_${DATASET_NAME}"
echo ""
echo "Mac への転送:"
echo "  scp -r <user>@<VM_IP>:/workspace/${OUTPUT_DIR}/checkpoints/last/pretrained_model outputs/"
