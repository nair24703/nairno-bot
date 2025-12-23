# 1. VOICEVOX公式イメージ
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 依存パッケージ
RUN apt-get update && apt-get install -y python3 python3-pip ffmpeg && apt-get clean

# 3. ライブラリをインストール（--userを付けず、システム全体に入れる）
RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir uvicorn fastapi requests numpy pydantic jinja2 aiofiles python-multipart

WORKDIR /app

# 4. Bot側のライブラリ
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. プログラムのコピー
COPY . .

# 6. 【ここが重要！】PYTHONPATHを設定して、インストール先を無理やり教えるまる！
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOXエンジンをパス指定で起動するまる！ ---"\n\
# インストールされたライブラリの場所をPythonに見つけさせる魔法の環境変数だもん\n\
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.8/dist-packages:/usr/lib/python3/dist-packages\n\
\n\
cd /opt/voicevox_engine\n\
/usr/bin/python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機 ---"\n\
sleep 60\n\
cd /app\n\
/usr/bin/python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]