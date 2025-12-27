# 1. 公式イメージをベースにする
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 必要なツールを入れる
RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

# 3. Bot用のライブラリを入れる
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト（ここを少しだけ書き換えたまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# フォルダ名と衝突しないように python3 run.py で確実に動かすまる！ \n\
# 公式環境のパスを全部通して ModuleNotFoundError を防ぐだもん \n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine \n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
