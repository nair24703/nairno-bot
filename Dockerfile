# 1. VOICEVOX公式イメージ
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. PythonとFFmpegのインストール
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    ffmpeg \
    && apt-get clean

WORKDIR /app

# 3. ライブラリのインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. プログラムのコピー
COPY . .

# 5. 実行ファイルを確認して、権限を与えてから起動するまる！
RUN echo '#!/bin/bash\n\
echo "--- フォルダの中身を確認するまる！ ---"\n\
ls -F /opt/voicevox_engine/\n\
\n\
# 実行権限を念のため付与するまる\n\
chmod +x /opt/voicevox_engine/run 2>/dev/null || true\n\
chmod +x /opt/voicevox_engine/voicevox_engine 2>/dev/null || true\n\
\n\
echo "--- VOICEVOXを起動するだもん！ ---"\n\
# run があれば run を、なければ voicevox_engine を実行するまる\n\
if [ -f "/opt/voicevox_engine/run" ]; then\n\
    /opt/voicevox_engine/run --host 0.0.0.0 &\n\
else\n\
    /opt/voicevox_engine/voicevox_engine --host 0.0.0.0 &\n\
fi\n\
\n\
sleep 60\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]