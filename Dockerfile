# 1. VOICEVOX公式イメージをそのまま使うまる！
# これなら python-soxr も pydantic も最初から完璧に入ってるだもん！
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. Botを動かすのに必要な最小限のツール(pip)だけ入れるまる
RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

# 3. あなたの Bot 用のライブラリ（discord.py, groq など）をインストール
# 公式イメージの環境を壊さないように、requirements.txtの中身だけを入れるまる
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. プログラムをコピー
COPY . .

# 5. 起動スクリプト
# 公式イメージではエンジンは /opt/voicevox_engine にあるまる
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