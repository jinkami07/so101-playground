#!/bin/bash
# SO-101 テレオペレーション + データセット収録
# 実行: bash scripts/record_dataset.sh
# 前提:
#   - conda activate so101
#   - キャリブレーション済み (bash setup/03_calibrate.sh)
#   - .env を設定済み

set -e
source "$(dirname "$0")/../.env" 2>/dev/null || {
    echo "エラー: .env ファイルが見つかりません"
    echo "  cp .env.example .env && vi .env"
    exit 1
}

# --- 設定確認 ---
echo "=== データセット収録設定 ==="
echo "  Follower Port : ${FOLLOWER_PORT}"
echo "  Leader Port   : ${LEADER_PORT}"
echo "  HF_USER       : ${HF_USER}"
echo "  DATASET_NAME  : ${DATASET_NAME}"
echo "  TASK          : ${TASK_DESCRIPTION}"
echo ""
echo "設定が正しければ Enter を押してください (Ctrl+C で中止)"
read -r

# --- テレオペ動作確認 (任意) ---
echo "テレオペ動作確認を行いますか? (30秒間) [y/N]"
read -r ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    timeout 30 lerobot-teleoperate \
        --robot.type=so101_follower \
        --robot.port="${FOLLOWER_PORT}" \
        --robot.id="${FOLLOWER_ID}" \
        --robot.cameras="{front: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30}}" \
        --teleop.type=so101_leader \
        --teleop.port="${LEADER_PORT}" \
        --teleop.id="${LEADER_ID}" || true
    echo ""
    echo "動作確認完了。データ収録に進みますか? [y/N]"
    read -r ans2
    [[ "$ans2" =~ ^[Yy]$ ]] || exit 0
fi

# --- データ収録 ---
echo ""
echo "=== データ収録開始 ==="
echo "SmolVLAベストプラクティス:"
echo "  - 最低50エピソード/タスクを収録"
echo "  - 物体の位置を5箇所以上変えて収録"
echo "  - 各エピソードで同じタスク説明文を使用"
echo ""

lerobot-record \
    --robot.type=so101_follower \
    --robot.port="${FOLLOWER_PORT}" \
    --robot.id="${FOLLOWER_ID}" \
    --robot.cameras="{front: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30}}" \
    --teleop.type=so101_leader \
    --teleop.port="${LEADER_PORT}" \
    --teleop.id="${LEADER_ID}" \
    --dataset.repo_id="${HF_USER}/${DATASET_NAME}" \
    --dataset.num_episodes=50 \
    --dataset.single_task="${TASK_DESCRIPTION}"

echo ""
echo "=== 収録完了 ==="
echo "データセット: https://huggingface.co/datasets/${HF_USER}/${DATASET_NAME}"
echo ""
echo "データセット可視化:"
echo "  lerobot-visualize-dataset \\"
echo "    --repo-id ${HF_USER}/${DATASET_NAME} \\"
echo "    --episode-index 0"
echo ""
echo "次のステップ: GCPで学習 → bash gcp/train_smolvla.sh"
