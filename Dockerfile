# 1. Ubuntu 22.04版の公式イメージを使うまる！（これで Python 3.10 になるだもん）
FROM voicevox/voicevox_engine:cpu-ubuntu22.04-latest

USER root

# 2. 必要なツールをインストール
RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

# 3. Bot用とエンジン用のライブラリをインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# TypeAlias問題と、前回のuvicorn問題をまとめて解決するまる！
RUN pip3 install --no-cache-dir \
    uvicorn \
    fastapi \
    "pydantic>=2.0" \
    pydantic-settings \
    typing-extensions

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# パスをしっかり通して、pyopenjtalkなどを見つけやすくするまる \n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine \n\
\n\
# Python 3.10 でエンジンを起動するまる！ \n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
