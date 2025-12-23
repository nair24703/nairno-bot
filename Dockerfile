# 1. VOICEVOX公式イメージを使用
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

# 5. 【重要】起動スクリプトの修正
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOXを探す旅に出るまる！ ---"\n\
find / -name "run" -type f 2>/dev/null\n\
echo "--- 調査完了だもん！ ---"\n\
/opt/voicevox_engine/run --host 0.0.0.0 & \n\
sleep 60 \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]