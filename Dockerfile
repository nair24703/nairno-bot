# 1. VOICEVOX公式イメージ
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 必要なパッケージと、VOICEVOXを動かすためのライブラリをインストール
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    ffmpeg \
    && apt-get clean

# 【重要】VOICEVOXの実行に必要なライブラリをOS側に直接入れるまる！
RUN pip3 install --no-cache-dir \
    uvicorn \
    fastapi \
    requests \
    numpy \
    pydantic==1.10.11

WORKDIR /app

# 3. Bot側のライブラリをインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. プログラムのコピー
COPY . .

# 5. 規約に同意して起動
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOXエンジンを起動するまる！ ---"\n\
cd /opt/voicevox_engine\n\
python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機してBotを立ち上げるまる ---"\n\
sleep 60\n\
cd /app\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]