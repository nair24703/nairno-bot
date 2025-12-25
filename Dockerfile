# 1. 有志の軽量イメージ（これ自体はすごく優秀だまる！）
FROM yushulx/voicevox:latest

USER root

# 2. パッケージの更新
RUN apt-get update && apt-get install -y ffmpeg python3-pip && apt-get clean

WORKDIR /app

# 3. ライブラリのインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---"\n\
cd /nfs/voicevox_engine\n\
python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- waiting for 60 seconds ---"\n\
sleep 60\n\
\n\
cd /app\n\
echo "--- Discord Bot STARTING ---"\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]