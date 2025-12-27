# 1. VOICEVOX公式イメージ（Python 3.8が入ってる）をベースにする
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. OSの部品（FFmpeg）と、Bot用のライブラリを入れるための pip を用意するまる
RUN apt-get update && apt-get install -y ffmpeg python3-pip && apt-get clean

WORKDIR /app

# 3. あなたの Bot 用のライブラリ（discord.py, groqなど）をインストール
# ※ ここで uvicorn や soxr を指定するとエラーになる可能性があるので、
#    もし requirements.txt にそれらが入っていたら、一旦 discord.py 等だけに絞るのが安全だまる！
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト（公式の環境をそのまま使うまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# 公式イメージの Python 3.8 で run.py を起動するまる！\n\
# これなら pyopenjtalk も絶対に見つかるはずだもん！\n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
# Botも同じ Python 3.8 で動かすまる！\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
