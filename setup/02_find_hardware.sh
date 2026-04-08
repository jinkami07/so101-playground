#!/bin/bash
# SO-101 ポート & カメラ発見スクリプト
# 実行: bash setup/02_find_hardware.sh
# 前提: source .venv/bin/activate 済み

echo "=== SO-101 ハードウェア確認 ==="
echo ""

# --- シリアルポート確認 ---
echo "[ポート一覧] 現在接続されているシリアルデバイス:"
ls /dev/tty.usbmodem* 2>/dev/null || echo "  (usbmodem デバイスなし)"
ls /dev/tty.usbserial* 2>/dev/null || echo "  (usbserial デバイスなし)"
echo ""

echo "[LeRobot ポート発見] Feetech サーボのポートを自動検出:"
echo "  → USBを抜き差ししてポートを特定します"
echo "  コマンド: lerobot-find-port"
echo ""

# lerobot-find-port コマンドの実行 (インタラクティブ)
echo "Follower アームのポートを探しますか? [y/N]"
read -r ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    lerobot-find-port
fi

# --- カメラ確認 ---
echo ""
echo "[カメラ一覧] 接続されているカメラデバイス:"
# macOSではsystem_profilerで確認
system_profiler SPCameraDataType 2>/dev/null | grep -E "^    [^ ]" | head -20 || true

echo ""
echo "[LeRobot カメラ発見] OpenCVカメラのインデックスを確認:"
python3 - <<'PYEOF'
import cv2
available = []
for i in range(5):
    cap = cv2.VideoCapture(i)
    if cap.read()[0]:
        available.append(i)
    cap.release()
if available:
    print(f"  利用可能なカメラインデックス: {available}")
    for idx in available:
        cap = cv2.VideoCapture(idx)
        w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        print(f"    index={idx}: {w}x{h}")
        cap.release()
else:
    print("  カメラが見つかりませんでした")
PYEOF

echo ""
echo "=== 確認完了 ==="
echo "ポートが判明したら .env を更新してください:"
echo "  FOLLOWER_PORT=/dev/tty.usbmodem..."
echo "  LEADER_PORT=/dev/tty.usbmodem..."
