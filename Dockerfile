# 1. ベースイメージ
FROM voicevox/voicevox_engine:cpu-ubuntu22.04-latest

USER root

# 2. ツールインストール
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

# 4. 起動スクリプト（エラーの原因だったオプションを消したまる！）
RUN echo '#!/bin/bash\n\
echo "--- STARTING VOICEVOX ENGINE ---" \n\
\n\
# 突き止めたパスを直接叩くまる！ \n\
# --accept_all_terms を消して起動するだもん \n\
/opt/voicevox_engine/run --host 0.0.0.0 & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
