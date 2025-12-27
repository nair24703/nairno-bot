# 1. ベースイメージ（22.04版）
FROM voicevox/voicevox_engine:cpu-ubuntu22.04-latest

USER root

# 2. ダイエットとツールインストールを徹底するまる
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    ffmpeg \
    && pip3 install --no-cache-dir uvicorn fastapi "pydantic>=2.0" pydantic-settings typing-extensions \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && find /opt/voicevox_engine -name "__pycache__" -type d -exec rm -rf {} +

WORKDIR /app

# 3. Bot用ライブラリ
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 不要なファイルを消して2GB枠を死守するまる
RUN rm -rf /opt/voicevox_engine/docs /opt/voicevox_engine/test

COPY . .

# 5. 起動スクリプト（ここが魔法の修正だまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine \n\
\n\
# run.py がどこにあるか探して実行するまる！ \n\
# もし見つからなければ、モジュールとして起動を試みるだもん \n\
if [ -f "/opt/voicevox_engine/run.py" ]; then \n\
    python3 /opt/voicevox_engine/run.py --host 0.0.0.0 --accept_all_terms & \n\
else \n\
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
