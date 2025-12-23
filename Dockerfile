# 1. VOICEVOXとPythonが同居するベースイメージを使用
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 必要なシステムパッケージ（FFmpegなど）をインストール
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    ffmpeg \
    && apt-get clean

# 3. 作業ディレクトリの設定
WORKDIR /app

# 4. ライブラリのインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. プログラム本体をコピー
COPY . .

# 6. VOICEVOXエンジンとBotを同時に起動するスクリプトを作成
RUN echo '#!/bin/bash\n\
./voicevox_engine/run & \n\
sleep 10 \n\
python3 bot.py' > start.sh && chmod +x start.sh

# 7. 実行
CMD ["./start.sh"]