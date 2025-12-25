# 1. 安定した Python 3.10 環境
FROM python:3.10-slim

USER root

# 2. 必要な部品（FFmpeg, wget, 7zip）をインストール
RUN apt-get update && apt-get install -y \
    ffmpeg \
    wget \
    p7zip-full \
    libsndfile1 \
    && apt-get clean

# 3. VOICEVOXエンジン（Linux CPU版）をダウンロードして設置
# 公式イメージを丸ごと読み込むより、こっちの方がビルドが安定するまる！
WORKDIR /opt
RUN wget https://github.com/VOICEVOX/voicevox_engine/releases/download/0.14.10/voicevox_engine-linux-cpu-0.14.10.7z \
    && 7z x voicevox_engine-linux-cpu-0.14.10.7z \
    && mv linux-cpu voicevox_engine \
    && rm voicevox_engine-linux-cpu-0.14.10.7z

WORKDIR /app

# 4. Botとエンジンの動作に必要なライブラリを全て一気に入れるまる
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir \
    uvicorn fastapi requests numpy pydantic==1.10.11 \
    jinja2 aiofiles python-multipart \
    semver pyyaml platformdirs psutil python-soxr

COPY . .

# 5. 起動スクリプト（バイナリ版は ./run を叩くだけでOKだまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---"\n\
cd /opt/voicevox_engine\n\
chmod +x ./run\n\
./run --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- waiting for 60 seconds ---"\n\
sleep 60\n\
\n\
cd /app\n\
echo "--- Discord Bot STARTING ---"\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]