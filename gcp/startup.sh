#!/bin/bash
# GCP VM 起動時自動セットアップ (Ubuntu 22.04 + NVIDIA L4)
# このスクリプトは VM 初回起動時に自動実行されます

set -e
LOG="/var/log/smolvla-setup.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== SmolVLA GCP セットアップ開始: $(date) ==="

# --- システムパッケージ ---
apt-get update -y
apt-get install -y \
    git curl wget unzip \
    build-essential \
    libgl1-mesa-glx libglib2.0-0 \
    ffmpeg \
    tmux htop nvtop

# --- NVIDIA ドライバ & CUDA (L4対応) ---
# Deep Learning VM イメージを使う場合は不要 (既インストール)
if ! command -v nvidia-smi &>/dev/null; then
    echo "NVIDIA ドライバをインストール..."
    apt-get install -y linux-headers-$(uname -r)
    distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L "https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list" \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    apt-get update -y
    apt-get install -y nvidia-driver-535 cuda-toolkit-12-2
fi

# --- Miniconda のインストール ---
CONDA_DIR="/opt/miniconda"
if [ ! -d "$CONDA_DIR" ]; then
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$CONDA_DIR"
    rm /tmp/miniconda.sh
fi
export PATH="$CONDA_DIR/bin:$PATH"

# 全ユーザーが conda を使えるようにする
cat >> /etc/environment <<'EOF'
PATH="/opt/miniconda/bin:$PATH"
EOF

# --- conda 環境の作成 ---
eval "$($CONDA_DIR/bin/conda shell.bash hook)"
conda create -y -n so101 python=3.12

conda activate so101
conda install -y ffmpeg=7.1.1 -c conda-forge

# --- LeRobot のインストール ---
LEROBOT_DIR="/opt/lerobot"
if [ ! -d "$LEROBOT_DIR" ]; then
    git clone https://github.com/huggingface/lerobot.git "$LEROBOT_DIR"
fi
cd "$LEROBOT_DIR"
pip install -e ".[smolvla]"

# GPU 版 PyTorch の確認 (LeRobot が CPU版をインストールした場合は上書き)
python -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')" || true

# CUDA が使えない場合は GPU版に入れ替え
python -c "import torch; assert torch.cuda.is_available()" 2>/dev/null || {
    echo "GPU版 PyTorch を再インストール..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
}

# --- W&B のインストール ---
pip install wandb

# --- JupyterLab (任意) ---
pip install jupyterlab

# --- 作業ディレクトリの準備 ---
mkdir -p /workspace
chmod 777 /workspace

echo "=== セットアップ完了: $(date) ==="
echo "接続後に実行:"
echo "  source /opt/miniconda/etc/profile.d/conda.sh"
echo "  conda activate so101"
echo "  cd /workspace"
echo "  nvidia-smi  # GPU確認"
