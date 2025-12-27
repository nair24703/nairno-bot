# 1. ベースイメージ
FROM voicevox/voicevox_engine:cpu-ubuntu22.04-latest

USER root

# 2. 【ダイエット作戦】
# 命令を「&&」で繋いで1つの層にすることで、無駄なデータが残らないようにするまる！
# さらに、インストール後にすぐ不要なキャッシュ（apt lists）を消すのがコツだもん。
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    ffmpeg \
    && pip3 install --no-cache-dir -U pip \
    && pip3 install --no-cache-dir uvicorn fastapi "pydantic>=2.0" pydantic-settings typing-extensions \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. Bot用ライブラリも、キャッシュを残さず入れるまる
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. エンジンの中にある「使わない書類やテスト」を消して、さらに軽量化するまる！
# これで数十MBは稼げるはずだもん！
RUN rm -rf /opt/voicevox_engine/docs /opt/voicevox_engine/test

COPY . .

# 5. 起動スクリプト
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
cd /opt/voicevox_engine \n\
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
