# 1. ベースイメージ
FROM voicevox/voicevox_engine:cpu-ubuntu22.04-latest

USER root

# 2. 必要なツールをインストール（libopus-dev を追加！）
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    ffmpeg \
    libopus-dev \
    && pip3 install --no-cache-dir uvicorn fastapi "pydantic>=2.0" pydantic-settings typing-extensions \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. Bot用ライブラリ
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

# 4. 起動スクリプト（エラーの原因だったオプションを消したまる！）
RUN echo '#!/bin/bash\n\
echo "--- STARTING VOICEVOX ENGINE ---" \n\
/opt/voicevox_engine/run --host 0.0.0.0 & \n\
\n\
# ここで sleep せずに直接 Bot を起動し、Bot側で VOICEVOX の準備を待つようにします\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
