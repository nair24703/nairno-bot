# 1. VOICEVOX公式イメージをベースにする
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 必要なツールをインストール
RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

# 3. あなたの Bot 用のライブラリと、エンジン実行に必要な部品を「追加」するまる
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
# run.py が欲しがっている部品を直接インストールするだもん！
RUN pip3 install --no-cache-dir uvicorn fastapi pydantic>=2.0 pydantic-settings

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# 公式のフォルダをパスに含めて、pyopenjtalk などを見つけやすくするまる\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine \n\
\n\
# python3 run.py でエンジンを起動！\n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
