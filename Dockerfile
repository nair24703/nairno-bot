# 1. 素材として公式イメージを読み込む
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest AS source

# 2. ベースは Python 3.11
FROM python:3.11-slim

USER root

# 3. 必要なOSの部品をインストール
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    && apt-get clean

# 4. 公式から「プログラムとライブラリが詰まったフォルダ」を丸ごとコピー
# さっきエラーが出た site-packages のコピーはやめて、ここだけに集中するまる！
COPY --from=source /opt/voicevox_engine /opt/voicevox_engine

WORKDIR /app

# 5. 私たちの Bot 用のライブラリをインストール
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# pyopenjtalk など、エンジンに必要なものを「今の環境」でも使えるように叩き込むまる
# ビルド済みのバイナリが降ってくることを祈るまる！
RUN pip install --no-cache-dir \
    "uvicorn[standard]" fastapi "pydantic>=2.0" pydantic-settings soxr pyopenjtalk

COPY . .

# 6. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# エンジン内のライブラリ（もしあれば）と、今の環境のライブラリ両方を見るようにするまる\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine:/opt/voicevox_engine/voicevox_engine \n\
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
