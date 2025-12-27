# 1. ベースイメージ
FROM voicevox/voicevox_engine:cpu-ubuntu22.04-latest

USER root

# 2. 必要なツールをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    ffmpeg \
    && pip3 install --no-cache-dir uvicorn fastapi "pydantic>=2.0" pydantic-settings typing-extensions \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. Bot用ライブラリ
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

# 4. 起動スクリプト（公式のデフォルト実行ファイルを自動で叩くまる！）
RUN echo '#!/bin/bash\n\
echo "--- STARTING VOICEVOX ENGINE ---" \n\
# /opt/voicevox_engine の中にある「実行可能ファイル」を自動で探して動かすまる！ \n\
TARGET=$(find /opt/voicevox_engine -maxdepth 1 -executable -type f | head -n 1) \n\
if [ -n "$TARGET" ]; then \n\
    echo "Executing engine at: $TARGET" \n\
    "$TARGET" --host 0.0.0.0 --accept_all_terms & \n\
else \n\
    echo "Fallback: Trying python module mode..." \n\
    python3 -m voicevox_engine --host 0.0.0.0 --accept_all_terms & \n\
fi \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
