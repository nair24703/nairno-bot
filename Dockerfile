# 1. VOICEVOX公式イメージをベースにする
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. Botに必要な最低限のツールだけ入れる
RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

# 3. Bot用（discord.pyなど）のライブラリだけ入れる
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト（ここが重要だまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# python3 run.py ではなく、公式が用意した実行ファイルを直接動かすまる！\n\
# これなら uvicorn も pyopenjtalk も全部内蔵されているからエラーにならないだもん！\n\
./voicevox_engine --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
