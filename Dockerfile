# 1. 最初からVOICEVOXが入っている公式イメージを土台にするまる！
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. Python 3.12 をインストールするための準備だもん
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3.12-distutils \
    python3-pip \
    ffmpeg \
    && apt-get clean

# 3. pip を Python 3.12 用にセットアップするまる
RUN wget https://bootstrap.pypa.io/get-pip.py && python3.12 get-pip.py

WORKDIR /app

# 4. Botに必要なライブラリを Python 3.12 に入れるまる
COPY requirements.txt .
RUN python3.12 -m pip install --no-cache-dir -r requirements.txt
# VOICEVOX起動に必要なものも 3.12 側に入れておくまる
RUN python3.12 -m pip install --no-cache-dir uvicorn fastapi requests numpy pydantic jinja2 aiofiles python-multipart

# 5. プログラムをコピー
COPY . .

# 6. 起動スクリプト（Python 3.12 を明示的に使って起動するまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOXエンジンを起動するだもん！ ---"\n\
cd /opt/voicevox_engine\n\
# 公式イメージ内の run.py を Python 3.12 で動かすから TypeAlias エラーも出ないまる！\n\
python3.12 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機 ---"\n\
sleep 60\n\
cd /app\n\
python3.12 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]