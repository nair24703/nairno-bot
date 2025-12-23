# 1. 安定版の 0.14.10 イメージを直接指定するまる！
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-0.14.10

USER root

# 2. 必要なものを入れるまる
RUN apt-get update && apt-get install -y ffmpeg python3-pip && apt-get clean

# 3. 0.14.10 に最適なライブラリバージョンを固定して入れるまる
RUN pip3 install --no-cache-dir \
    uvicorn==0.20.0 \
    fastapi==0.88.0 \
    pydantic==1.10.11 \
    requests numpy jinja2 aiofiles python-multipart

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY . .

# 4. 起動スクリプト（このバージョンなら TypeAlias は不要だもん！）
RUN echo '#!/bin/bash\n\
echo "--- 安定版 VOICEVOX 0.14.10 を起動するまる！ ---"\n\
\n\
cd /opt/voicevox_engine\n\
# 0.14.10 なら python3 run.py で素直に動くはずだまる\n\
python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機 ---"\n\
sleep 60\n\
cd /app\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]