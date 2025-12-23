# 1. VOICEVOX公式イメージ
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 依存パッケージのインストール
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    ffmpeg \
    && apt-get clean

# 3. VOICEVOX本体が動くために必要な最新ライブラリをインストール
# Pydanticのバージョン指定を外して、最新（2系）が入るようにするまる！
RUN pip3 install --no-cache-dir \
    uvicorn \
    fastapi \
    requests \
    numpy \
    pydantic \
    jinja2 \
    aiofiles \
    python-multipart

WORKDIR /app

# 4. Bot側のライブラリをインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. プログラムのコピー
COPY . .

# 6. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOXエンジンを全力で起動するまる！ ---"\n\
cd /opt/voicevox_engine\n\
/usr/bin/python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機（VOICEVOXが起きるのを待つ） ---"\n\
sleep 60\n\
cd /app\n\
/usr/bin/python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]