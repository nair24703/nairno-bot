# 1. 土台はいつもの公式イメージ
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 最小限のツールと Bot 用の Python 環境
RUN apt-get update && apt-get install -y ffmpeg python3-pip && apt-get clean

# 3. Bot が動くためのライブラリだけ入れるまる
RUN pip3 install --no-cache-dir \
    uvicorn fastapi requests numpy pydantic==1.10.11

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY . .

# 4. 起動スクリプト（Pythonを通さず、バイナリを直接実行するまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX バイナリを直接起動するだもん！ ---"\n\
\n\
cd /opt/voicevox_engine\n\
\n\
# ここが運命の分かれ道だまる！\n\
# Pythonを介さず、コンパイル済みの ./run を直接実行すれば、TypeAdapterエラーは起きないまる！\n\
chmod +x ./run\n\
./run --host 0.0.0.0 --accept_all_terms --disable_update &\n\
\n\
echo "--- 60秒待機（今度こそ心臓が動くはずだもん） ---"\n\
sleep 60\n\
\n\
# VOICEVOXが本当に動いているか、ログで確認するまる\n\
curl -s http://localhost:50021/speakers > /dev/null && echo "--- VOICEVOX 起動確認成功だまる！ ---" || echo "--- まだ寝てるみたいだもん... ---"\n\
\n\
cd /app\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]