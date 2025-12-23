# 1. 最新の Python 3.11 環境（安定していて軽いまる）
FROM python:3.11-slim

USER root

# 2. 必要な道具（wget, 7zip, FFmpeg）を揃えるまる
RUN apt-get update && apt-get install -y \
    wget p7zip-full ffmpeg libsndfile1 \
    && apt-get clean

# 3. VOICEVOXエンジンの「実行ファイル版」を直接ダウンロードするまる
# 0.14.10 は 1ファイルで配布されているから 404 になりにくいだもん
WORKDIR /opt
RUN wget https://github.com/VOICEVOX/voicevox_engine/releases/download/0.14.10/voicevox_engine-linux-cpu-0.14.10.7z \
    && 7z x voicevox_engine-linux-cpu-0.14.10.7z \
    && mv linux-cpu voicevox_engine

WORKDIR /app

# 4. Bot側のライブラリをインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. プログラムをコピー
COPY . .

# 6. 起動スクリプト（もう Python 3.8 のしがらみはないまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX 起動開始だもん！ ---"\n\
cd /opt/voicevox_engine\n\
chmod +x ./run\n\
./run --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機 ---"\n\
sleep 60\n\
\n\
cd /app\n\
echo "--- Bot 起動だまる！ ---"\n\
python bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]