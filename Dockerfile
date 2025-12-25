# 1. まず公式イメージを「素材」として読み込む（ここから中身を盗むまる！）
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest AS source

# 2. 実際に動かすのは、新しくてクリーンな Python 環境だまる
FROM python:3.10-slim

USER root

# 3. 必要な部品（FFmpegなど）をインストール
RUN apt-get update && apt-get install -y ffmpeg libsndfile1 && apt-get clean

# 4. 【ここが重要！】公式イメージから「中身」を直接コピーして持ってくるまる！
# これならダウンロードしないから、URLが間違ってるとか 404 とかは絶対に起きないだもん！
COPY --from=source /opt/voicevox_engine /opt/voicevox_engine

WORKDIR /app

# 5. Botに必要なライブラリをインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# 依存関係を最新に保つために、ここでも必要なものを入れるまる
RUN pip install --no-cache-dir \
    uvicorn fastapi requests numpy pydantic \
    jinja2 aiofiles python-multipart \
    semver pyyaml platformdirs psutil python-soxr

COPY . .

# 6. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---"\n\
cd /opt/voicevox_engine\n\
# PYTHONPATHを設定して部品を見つけやすくするまる\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine\n\
python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- waiting for 60 seconds ---"\n\
sleep 60\n\
\n\
cd /app\n\
echo "--- Discord Bot STARTING ---"\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]