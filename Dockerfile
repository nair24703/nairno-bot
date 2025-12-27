# 1. 素材として公式イメージを読み込む
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest AS source

# 2. ベースは Python 3.11
FROM python:3.11-slim

USER root

# 3. 必要なOSの部品（FFmpeg、OpenJTalkのコンパイルに必要なもの）をインストール
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    cmake \
    g++ \
    && apt-get clean

# 4. 【ここが魔法の1行だまる！】
# 公式イメージの「ライブラリ置き場」から、pyopenjtalk を含む全ての部品をコピーするまる！
COPY --from=source /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.11/site-packages
# プログラム本体もコピー
COPY --from=source /opt/voicevox_engine /opt/voicevox_engine

WORKDIR /app

# 5. 私たちの Bot 用のライブラリだけを足すまる
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# もし足りないものがあっても、ここで補完するまる
RUN pip install --no-cache-dir \
    "uvicorn[standard]" fastapi "pydantic>=2.0" pydantic-settings soxr

COPY . .

# 6. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# 全てのパスを繋いで、どこからでも部品が見えるようにするまる！\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine:/usr/local/lib/python3.11/site-packages \n\
\n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
