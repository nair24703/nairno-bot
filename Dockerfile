# 1. ベースイメージ
FROM voicevox/voicevox_engine:cpu-ubuntu22.04-latest

USER root

# 2. 必要なツールをインストール（軽量化維持）
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    ffmpeg \
    && pip3 install --no-cache-dir uvicorn fastapi "pydantic>=2.0" pydantic-settings typing-extensions \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. Bot用ライブラリ
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

# 4. 起動スクリプト（エントリーポイントを解析して起動するまる！）
RUN echo '#!/bin/bash\n\
echo "--- ANALYZING OFFICIAL ENTRYPOINT ---" \n\
# 公式の起動スイッチがどうなってるかログに出して確認するまる！ \n\
cat /entrypoint.sh \n\
\n\
echo "--- STARTING VOICEVOX ENGINE ---" \n\
# 多くの場合、公式イメージは /opt/voicevox_engine/voicevox_engine という実行ファイルを持ってるまる \n\
# パスを通しつつ、直接実行を試みるだもん！ \n\
export PYTHONPATH=$PYTHONPATH:/opt/voicevox_engine \n\
\n\
# もし実行ファイル形式ならこっちで動くはずだまる \n\
/opt/voicevox_engine/voicevox_engine --host 0.0.0.0 --accept_all_terms & \n\
\n\
# もし上のコマンドがダメでも、entrypoint.sh をバックグラウンドで動かせば起動するはずだまる！ \n\
if [ $? -ne 0 ]; then \n\
    /entrypoint.sh --host 0.0.0.0 --accept_all_terms & \n\
fi \n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
