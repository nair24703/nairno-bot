# 1. 素材として公式イメージを読み込む
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest AS source

# 2. ベースは Python 3.11
FROM python:3.11-slim

USER root

# 3. 最小限必要なOSの部品だけ入れる
RUN apt-get update && apt-get install -y ffmpeg libsndfile1 && apt-get clean

# 4. 【ここが重要！】
# 公式イメージがインストール済みの「ライブラリ全部」を、今の環境に無理やりねじ込むまる！
# これで pyopenjtalk も uvicorn も最初から「ある」状態になるだもん！
COPY --from=source /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=source /opt/voicevox_engine /opt/voicevox_engine

WORKDIR /app

# 5. あなたの Bot 用のライブラリだけを入れる
# ここで pyopenjtalk をビルドさせないのが勝利の鍵だまる！
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# もしこれでも足りないと言われた時のための保険だまる
RUN pip install --no-cache-dir "pydantic>=2.0" pydantic-settings

COPY . .

# 6. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
# 全てのパスを繋いで、3.8用のライブラリも 3.11 で無理やり読み込ませるまる！\n\
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.11/site-packages:/opt/voicevox_engine \n\
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
