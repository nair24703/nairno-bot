# 1. VOICEVOX公式イメージ
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 依存パッケージ
RUN apt-get update && apt-get install -y python3 python3-pip ffmpeg && apt-get clean

# 3. VOICEVOXとPython 3.8の架け橋になるライブラリをインストール
# typing_extensions が TypeAlias の代わりをしてくれるまる！
RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir \
    uvicorn fastapi requests numpy pydantic jinja2 aiofiles python-multipart \
    typing_extensions

WORKDIR /app

# 4. Bot側のライブラリ
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 5. プログラムのコピー
COPY . .

# 6. 環境変数をさらに強化！
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOXエンジンを Python 3.8 モードで起動するまる！ ---"\n\
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.8/dist-packages:/usr/lib/python3/dist-packages\n\
\n\
cd /opt/voicevox_engine\n\
# typing.TypeAlias を typing_extensions.TypeAlias に見せかけるおまじないだもん\n\
/usr/bin/python3 -c "import typing; import typing_extensions; typing.TypeAlias = typing_extensions.TypeAlias" \n\
\n\
/usr/bin/python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機 ---"\n\
sleep 60\n\
cd /app\n\
/usr/bin/python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]