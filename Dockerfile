# 1. 確実に存在するタグ「0.14.10」を直接指定するまる！
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 必要なものを入れるまる
RUN apt-get update && apt-get install -y ffmpeg python3-pip && apt-get clean

# 3. 安定して動くようにライブラリのバージョンを調整するまる
# 最新のVOICEVOXエンジン（0.14.x）に合うように、Pydantic V1系を維持するだもん
RUN pip3 install --no-cache-dir \
    uvicorn fastapi==0.88.0 pydantic==1.10.11 \
    requests numpy jinja2 aiofiles python-multipart

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY . .

# 4. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOXエンジンを起動するまる！ ---"\n\
\n\
cd /opt/voicevox_engine\n\
# run.py がない場合を考えて、複数の起動方法を試すまる\n\
if [ -f "./run" ]; then\n\
    ./run --host 0.0.0.0 --accept_all_terms &\n\
else\n\
    python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
fi\n\
\n\
echo "--- 60秒待機（花丸の準備中だもん） ---"\n\
sleep 60\n\
cd /app\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]