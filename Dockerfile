# 1. VOICEVOX公式イメージをそのまま使う
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 最小限のツール(pip)とFFmpegだけ入れる
RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

# 3. あなたの Bot 用のライブラリだけを入れる
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト（run.py を直接 Python3 で動かすまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# PYTHONPATH を設定して、隣にある voicevox_engine フォルダを読み込めるようにするまる\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine \n\
\n\
# run.py を起動！これが正解のファイルだもん！\n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
