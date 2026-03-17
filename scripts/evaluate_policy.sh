#!/bin/bash
# SmolVLA 学習済みモデルでの推論・評価
# 実行: bash scripts/evaluate_policy.sh
# 前提:
#   - conda activate so101
#   - キャリブレーション済み
#   - .env を設定済み (POLICY_NAME または POLICY_PATH を設定)

set -e
source "$(dirname "$0")/../.env" 2>/dev/null || {
    echo "エラー: .env が見つかりません"
    exit 1
}

# --- ポリシーパスの決定 ---
# HuggingFace Hub上のモデル or ローカルチェックポイント
if [ -n "${POLICY_PATH}" ] && [ -d "${POLICY_PATH}" ]; then
    POLICY="${POLICY_PATH}"
    echo "ローカルチェックポイントを使用: ${POLICY}"
else
    POLICY="${HF_USER}/smolvla_${DATASET_NAME}"
    echo "HuggingFace Hub のモデルを使用: ${POLICY}"
fi

# --- 評価設定確認 ---
echo ""
echo "=== 評価設定 ==="
echo "  Robot Port : ${FOLLOWER_PORT}"
echo "  Policy     : ${POLICY}"
echo "  Task       : ${TASK_DESCRIPTION}"
echo "  Episodes   : 20"
echo ""
echo "  推論デバイス: CPU (Mac M-series は MPS も可)"
echo ""
echo "設定が正しければ Enter を押してください"
read -r

# --- デバイス選択 ---
# Mac M-series では MPS が利用可能な場合 mps を使うと高速
DEVICE="cpu"
python -c "import torch; assert torch.backends.mps.is_available()" 2>/dev/null && {
    echo "MPS が利用可能です。MPS推論を使用しますか? [y/N]"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] && DEVICE="mps"
}

# --- 推論 & 評価データ収録 ---
echo ""
echo "=== 評価開始 (${DEVICE}) ==="

EVAL_DATASET="${HF_USER}/eval_${POLICY_NAME:-smolvla_${DATASET_NAME}}"

lerobot-record \
    --robot.type=so101_follower \
    --robot.port="${FOLLOWER_PORT}" \
    --robot.id="${FOLLOWER_ID}" \
    --robot.cameras="{front: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30}}" \
    --dataset.repo_id="${EVAL_DATASET}" \
    --dataset.single_task="${TASK_DESCRIPTION}" \
    --dataset.num_episodes=20 \
    --policy.path="${POLICY}" \
    --policy.device="${DEVICE}"

echo ""
echo "=== 評価完了 ==="
echo "評価データセット: https://huggingface.co/datasets/${EVAL_DATASET}"
echo ""
echo "成功率の確認:"
echo "  lerobot-visualize-dataset --repo-id ${EVAL_DATASET} --episode-index 0"
echo ""
echo "目標: 20エピソード中 >50% 成功"
