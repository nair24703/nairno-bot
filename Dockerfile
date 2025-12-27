# 1. まず公式イメージを「素材」として読み込む
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest AS source

# 2. 実際に動かすのは、私たちがコントロールできる Python 3.10 環境
FROM python:3.10-slim

USER root

# 3. OSの部品（FFmpegなど）をインストール
RUN apt-get update && apt-get install -y ffmpeg libsndfile1 && apt-get clean

# 4. 公式イメージから VOICEVOX の「プログラム本体」だけをコピーするまる！
COPY --from=source /opt/voicevox_engine /opt/voicevox_engine

WORKDIR /app

# 5. 【ここが超重要！】
# 公式環境に頼らず、自分たちで必要なライブラリを全部入れるまる！
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# run.py が動くために必要なライブラリを「これでもか！」というくらい全部入れるまる
RUN pip install --no-cache-dir \
    uvicorn fastapi requests numpy pydantic==1.10.11 \
    jinja2 aiofiles python-multipart \
    semver pyyaml platformdirs psutil python-soxr

COPY . .

# 6. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# PYTHONPATH を設定して、隣にあるフォルダを読み込めるようにするまる\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine \n\
\n\
# 私たちが用意した Python 環境で run.py を叩くまる！\n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
