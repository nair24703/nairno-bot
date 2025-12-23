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
# VOICEVOXエンジンの実行ファイルは通常 /opt/voicevox_engine にあります
RUN echo '#!/bin/bash\n\
(cd /opt/voicevox_engine && ./run) & \n\
sleep 20 \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]