# 1. まずVOICEVOX公式から「中身」だけ借りるまる
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest AS engine

# 2. 実際に動かすのは、新しくてクリーンな Python 環境だまる
FROM python:3.10-slim

USER root

# 3. 必要な部品（FFmpegなど）をインストール
RUN apt-get update && apt-get install -y ffmpeg libsndfile1 && apt-get clean

# 4. 公式イメージからVOICEVOXのエンジンをコピーして持ってくるまる！
COPY --from=engine /opt/voicevox_engine /opt/voicevox_engine

WORKDIR /app

# 5. Botに必要なライブラリをインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 【ここを修正！】semver と、エンジンに必要な部品をすべて追加したまる
RUN pip install --no-cache-dir \
    uvicorn fastapi requests numpy pydantic \
    jinja2 aiofiles python-multipart \
    semver pyyaml

COPY . .

# 6. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---"\n\
cd /opt/voicevox_engine\n\
python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- waiting for 60 seconds ---"\n\
sleep 60\n\
\n\
cd /app\n\
echo "--- Discord Bot STARTING ---"\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]