# 1. 安定した Python 3.10 環境
FROM python:3.10-slim

USER root

# 2. 必要な部品をインストール (curl と jq を追加したまる)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    wget \
    p7zip-full \
    libsndfile1 \
    curl \
    jq \
    && apt-get clean

# 3. VOICEVOXエンジンを【自動で】探して設置
# GitHubのデータから「linux-cpu」が含まれるダウンロードURLを自動で抜き出すまる！
WORKDIR /opt
RUN export DOWNLOAD_URL=$(curl -s https://api.github.com/repos/VOICEVOX/voicevox_engine/releases/latest \
    | jq -r '.assets[] | select(.name | contains("linux-cpu")) | .browser_download_url') \
    && echo "Downloading from: $DOWNLOAD_URL" \
    && wget -O voicevox_engine.7z "$DOWNLOAD_URL" \
    && 7z x voicevox_engine.7z \
    && mv linux-cpu voicevox_engine \
    && rm voicevox_engine.7z

WORKDIR /app

# 4. Botとエンジンの動作に必要なライブラリ
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir \
    uvicorn fastapi requests numpy pydantic \
    jinja2 aiofiles python-multipart \
    semver pyyaml platformdirs psutil python-soxr

COPY . .

# 5. 起動スクリプト
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