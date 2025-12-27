# 1. ベースイメージ（22.04版）
FROM voicevox/voicevox_engine:cpu-ubuntu22.04-latest

USER root

# 2. 軽量化しつつ必要なツールを導入
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

# 4. 2GB制限を回避するための掃除（docsなどを削除）
RUN rm -rf /opt/voicevox_engine/docs /opt/voicevox_engine/test

COPY . .

# 5. 起動スクリプト（執念の全自動探索バージョンだまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE SEARCHING ---" \n\
\n\
# エンジンのルートディレクトリと、その一つ下のディレクトリもパスに加えるまる！\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine:/opt/voicevox_engine/voicevox_engine \n\
\n\
# run.py を執念で探し出すまる！ \n\
ENGINE_PATH=$(find /opt/voicevox_engine -name "run.py" | head -n 1) \n\
\n\
if [ -n "$ENGINE_PATH" ]; then \n\
    echo "Found run.py at: $ENGINE_PATH" \n\
    python3 "$ENGINE_PATH" --host 0.0.0.0 --accept_all_terms & \n\
else \n\
    echo "run.py not found, trying module mode..." \n\
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
