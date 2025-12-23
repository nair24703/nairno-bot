# 1. VOICEVOX公式イメージ
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. PythonとFFmpegのインストール
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    ffmpeg \
    && apt-get clean

WORKDIR /app

# 3. ライブラリのインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. プログラムのコピー
COPY . .

# 5. 【決定版】python3を使って run.py を直接起動するまる！
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOXエンジンを起動するだもん！ ---"\n\
cd /opt/voicevox_engine\n\
# python3 で run.py を呼び出し、全ホスト(0.0.0.0)からの接続を許可するまる\n\
python3 run.py --host 0.0.0.0 &\n\
\n\
echo "--- 60秒待機してBotを立ち上げるまる ---"\n\
sleep 60\n\
cd /app\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]