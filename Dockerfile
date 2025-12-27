# 1. まず公式イメージを素材として読み込む
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest AS source

# 2. Python 3.11 環境を使うまる！（soxr がこれを欲しがってるだもん）
FROM python:3.11-slim

USER root

# 3. OSの部品（FFmpegなど）をインストール
RUN apt-get update && apt-get install -y ffmpeg libsndfile1 && apt-get clean

# 4. 公式からプログラム本体をコピー
COPY --from=source /opt/voicevox_engine /opt/voicevox_engine

WORKDIR /app

# 5. ライブラリのインストール
# まず pip を最新にして、それから Bot 用とエンジン用を入れるまる
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# ここで 3.11 を使っていれば python-soxr は正常に入るまる！
RUN pip install --no-cache-dir \
    uvicorn fastapi requests numpy pydantic==1.10.11 \
    jinja2 aiofiles python-multipart \
    semver pyyaml platformdirs psutil python-soxr

COPY . .

# 6. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine \n\
\n\
# Python 3.11 環境で run.py を叩くまる！\n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
