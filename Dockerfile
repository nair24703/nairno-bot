# 1. 素材として公式イメージを読み込む
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest AS source

# 2. ベースは Python 3.11
FROM python:3.11-slim

USER root

# 3. 最小限必要なOSの部品だけ入れる
RUN apt-get update && apt-get install -y ffmpeg libsndfile1 && apt-get clean

# 4. 【ここが修正ポイントだまる！】
# エラーが出た site-packages のコピーはやめて、確実にあるフォルダだけを持ってくるまる。
COPY --from=source /opt/voicevox_engine /opt/voicevox_engine

WORKDIR /app

# 5. あなたの Bot 用のライブラリだけを入れる
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# 足りないライブラリ（エンジン実行用）をここで補完するまる。
# pyopenjtalk は入れずに、コピーした中身を使い回すまる！
RUN pip install --no-cache-dir \
    "uvicorn[standard]" fastapi "pydantic>=2.0" pydantic-settings soxr

COPY . .

# 6. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
\n\
# PYTHONPATH に、コピーしてきたフォルダと、その中のサブフォルダを全部指定するまる！\n\
# これで pyopenjtalk がどこに隠れていても見つけ出せるだもん！\n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine:/opt/voicevox_engine/voicevox_engine \n\
\n\
python3 run.py --host 0.0.0.0 --accept_all_terms & \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
