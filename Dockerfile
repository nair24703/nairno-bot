# 1. 素材として公式イメージを読み込む
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest AS source

# 2. ベースは Python 3.11
FROM python:3.11-slim

USER root

# 3. 最小限必要なOSの部品を入れる
RUN apt-get update && apt-get install -y ffmpeg libsndfile1 && apt-get clean

# 4. 公式から「プログラム本体」をコピー
COPY --from=source /opt/voicevox_engine /opt/voicevox_engine

WORKDIR /app

# 5. ライブラリのインストール
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# エンジンが欲しがっている部品を、今の環境に全部覚えさせるまる！
RUN pip install --no-cache-dir \
    "uvicorn[standard]" fastapi "pydantic>=2.0" pydantic-settings soxr semver pyyaml platformdirs

COPY . .

# 6. 起動スクリプト（ここが解決の鍵まる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# 私たちが pip install した場所（/usr/local/lib/python3.11/site-packages）を \n\
# PYTHONPATH の先頭に持ってくることで、semver などを確実に見つけさせるまる！ \n\
export PYTHONPATH=/usr/local/lib/python3.11/site-packages:/opt/voicevox_engine:/opt/voicevox_engine/voicevox_engine:$PYTHONPATH \n\
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
