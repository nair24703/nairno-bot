# 1. VOICEVOX公式イメージをベースにする
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 必要なツールをインストール
RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

# 3. Bot用のライブラリと、エンジン実行に必須なライブラリを「全部」入れるまる！
# これで ModuleNotFoundError は出なくなるだもん！
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
RUN pip3 install --no-cache-dir \
    uvicorn fastapi requests numpy pydantic==1.10.11 \
    jinja2 aiofiles python-multipart \
    semver pyyaml platformdirs psutil python-soxr

# 4. プログラムをコピー
COPY . .

# 5. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---"\n\
cd /opt/voicevox_engine\n\
# パスをしっかり通して python3 で起動するまる\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine\n\
python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- waiting for 60 seconds ---"\n\
sleep 60\n\
\n\
cd /app\n\
echo "--- Discord Bot STARTING ---"\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]