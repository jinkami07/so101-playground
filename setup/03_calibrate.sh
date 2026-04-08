#!/bin/bash
# SO-101 キャリブレーション手順
# 実行: bash setup/03_calibrate.sh
# 前提: source .venv/bin/activate 済み / .env を読み込み済み

set -e
source "$(dirname "$0")/../.env" 2>/dev/null || {
    echo "エラー: .env ファイルが見つかりません"
    echo "  cp .env.example .env && vi .env で設定してください"
    exit 1
}

echo "=== SO-101 キャリブレーション ==="
echo ""
echo "Follower Port : ${FOLLOWER_PORT}"
echo "Leader Port   : ${LEADER_PORT}"
echo "Follower ID   : ${FOLLOWER_ID}"
echo "Leader ID     : ${LEADER_ID}"
echo ""

# キャリブレーションデータの保存先
CALIB_DIR="$HOME/.cache/lerobot/calibration"
echo "キャリブレーションデータ保存先: ${CALIB_DIR}"
echo ""

# --- Follower キャリブレーション ---
echo "[Step 1] Follower アームをキャリブレーション"
echo "  → アームをホームポジション(自然に垂れた状態)にしてください"
echo "  → 準備ができたら Enter を押してください"
read -r

lerobot-calibrate \
    --robot.type=so101_follower \
    --robot.port="${FOLLOWER_PORT}" \
    --robot.id="${FOLLOWER_ID}"

echo ""
echo "[Step 2] Leader アームをキャリブレーション (リーダーがある場合)"
echo "  → Leader アームを接続している場合のみ実行"
echo "  → スキップする場合は Ctrl+C"
echo "  → 準備ができたら Enter を押してください"
read -r

lerobot-calibrate \
    --robot.type=so101_leader \
    --robot.port="${LEADER_PORT}" \
    --robot.id="${LEADER_ID}"

echo ""
echo "=== キャリブレーション完了 ==="
echo "次のステップ: bash scripts/record_dataset.sh"
echo ""
echo "動作確認:"
echo "  lerobot-teleoperate \\"
echo "    --robot.type=so101_follower \\"
echo "    --robot.port=${FOLLOWER_PORT} \\"
echo "    --robot.id=${FOLLOWER_ID} \\"
echo "    --teleop.type=so101_leader \\"
echo "    --teleop.port=${LEADER_PORT} \\"
echo "    --teleop.id=${LEADER_ID}"
