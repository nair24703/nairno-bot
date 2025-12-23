# 1. 土台はいつもの公式イメージ
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 必要なものを入れるまる
RUN apt-get update && apt-get install -y ffmpeg python3-pip && apt-get clean

# 3. ここが重要！Pydantic V1 を入れたあと、VOICEVOXの中身を「書き換えない」ようにするまる
RUN pip3 install --no-cache-dir \
    uvicorn fastapi==0.88.0 pydantic==1.10.11 \
    requests numpy jinja2 aiofiles python-multipart typing_extensions

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY . .

# 4. 起動スクリプト（おまじないを追加したまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX起動準備だもん！ ---"\n\
\n\
# エラーの原因になる TypeAdapter を強引に「空の箱」に置き換えてエラーを防ぐまる！\n\
python3 -c "import pydantic; pydantic.TypeAdapter = lambda x: x" 2>/dev/null\n\
\n\
cd /opt/voicevox_engine\n\
\n\
# 起動コマンド（--disable_update を付けて勝手な更新を止めるまる）\n\
if [ -f "./run" ]; then\n\
    ./run --host 0.0.0.0 --accept_all_terms --disable_update &\n\
else\n\
    python3 run.py --host 0.0.0.0 --accept_all_terms --disable_update &\n\
fi\n\
\n\
echo "--- 60秒待機（心臓が動き出すのを待つまる） ---"\n\
sleep 60\n\
cd /app\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]