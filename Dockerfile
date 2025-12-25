# 1. VOICEVOX公式イメージをそのまま使う
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 最小限のツール(pip)と、あなたのBotが必要な FFmpeg だけ入れる
RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

# 3. あなたの Bot 用のライブラリ（discord.py, groq など）だけを入れる
# ※ ここで uvicorn や soxr を入れようとしないのがコツだまる！
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト
# 公式が /opt/voicevox_engine/run に用意した「完成品」をそのまま叩くまる！
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
# 公式の実行ファイル(バイナリ)を直接動かすから、ライブラリ不足は起きないまる！ \n\
./run --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]