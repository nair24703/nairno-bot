# 1. ベースイメージ
FROM voicevox/voicevox_engine:cpu-ubuntu22.04-latest

USER root

# 2. 必要なツールをインストール（2GB制限に配慮したダイエット版）
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

# 4. 軽量化
RUN rm -rf /opt/voicevox_engine/docs /opt/voicevox_engine/test

COPY . .

# 5. 起動スクリプト（執念の全検索・デバッグ機能付き）
RUN echo '#!/bin/bash\n\
echo "--- DEBUG: DIRECTORY LISTING ---" \n\
ls -d /* \n\
\n\
echo "--- SEARCHING FOR run.py IN ENTIRE SYSTEM ---" \n\
# システム全体から run.py を探し、その場所を ENGINE_FILE に保存するまる！ \n\
ENGINE_FILE=$(find / -name "run.py" -not -path "/app/*" 2>/dev/null | head -n 1) \n\
\n\
if [ -n "$ENGINE_FILE" ]; then \n\
    ENGINE_DIR=$(dirname "$ENGINE_FILE") \n\
    echo "Found run.py at: $ENGINE_FILE" \n\
    echo "Engine directory: $ENGINE_DIR" \n\
    cd "$ENGINE_DIR" \n\
    export PYTHONPATH=$PYTHONPATH:"$ENGINE_DIR" \n\
    python3 "$ENGINE_FILE" --host 0.0.0.0 --accept_all_terms & \n\
else \n\
    echo "ERROR: run.py could not be found anywhere!" \n\
    # 最後の手段：バイナリ形式の実行ファイルがないか探すまる \n\
    VOICEVOX_BIN=$(find / -name "voicevox_engine" -type f -not -path "/app/*" 2>/dev/null | head -n 1) \n\
    if [ -n "$VOICEVOX_BIN" ]; then \n\
        echo "Found binary at: $VOICEVOX_BIN" \n\
        "$VOICEVOX_BIN" --host 0.0.0.0 --accept_all_terms & \n\
    fi \n\
fi \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
