# 1. VOICEVOXの公式イメージをベースにする
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    ffmpeg \
    && apt-get clean

WORKDIR /app

# 3. ライブラリのインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプトの修正（実行ディレクトリを明示）
RUN echo '#!/bin/bash\n\
cd /opt/voicevox_engine && ./run & \n\
cd /app && sleep 15 && python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]