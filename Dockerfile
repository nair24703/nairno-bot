# 1. VOICEVOX公式イメージをベースにするまる
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 必要な最小限のツールと、あなたのBotが必要な FFmpeg だけ入れるまる
RUN apt-get update && apt-get install -y \
    python3-pip \
    ffmpeg \
    libsndfile1 \
    && apt-get clean

WORKDIR /app

# 3. あなたの Bot 用のライブラリ（discord.py, groq など）だけを入れるまる
# ※ ここで python-soxr を入れようとしないのが最大のコツだもん！
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# 公式イメージの環境をそのまま使うために PYTHONPATH を通すまる\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine \n\
\n\
# 依存関係エラーを避けるため、公式の run.py を直接 python3 で叩くまる！ \n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
