# 1. Python 3.12 が入った軽量なイメージを使うまる！
FROM python:3.12-slim

USER root

# 2. 必要なツールと FFmpeg をインストール
RUN apt-get update && apt-get install -y \
    ffmpeg \
    wget \
    p7zip-full \
    libsndfile1 \
    && apt-get clean

# 3. VOICEVOXエンジン（Linux CPU版）をダウンロードして設置するまる
WORKDIR /opt
RUN wget https://github.com/VOICEVOX/voicevox_engine/releases/download/0.14.10/voicevox_engine-linux-cpu-0.14.10.7z.001 \
    && 7z x voicevox_engine-linux-cpu-0.14.10.7z.001 \
    && mv linux-cpu voicevox_engine

WORKDIR /app

# 4. BotとVOICEVOXに必要なライブラリをインストール
# Python 3.12 なら TypeAlias も標準装備だもん！
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir uvicorn fastapi requests numpy pydantic jinja2 aiofiles python-multipart

# 5. プログラムをコピー
COPY . .

# 6. 起動スクリプト（Python 3.12 で颯爽と起動するまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOXエンジンを Python 3.12 で起動するまる！ ---"\n\
cd /opt/voicevox_engine\n\
# 3.12では python3 ではなく python コマンドで動くまる\n\
python ./run --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機（花丸が起きるのを待ってね） ---"\n\
sleep 60\n\
cd /app\n\
python bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]