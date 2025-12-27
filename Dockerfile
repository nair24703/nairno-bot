# 1. VOICEVOX公式イメージをそのまま使う
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 最小限のツール(pip)とFFmpegだけ入れる
RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

# 3. あなたの Bot 用のライブラリだけを入れる
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. 全ファイルをコピー
COPY . .

# 5. 起動スクリプト（実行ファイルの場所を徹底的に指定したまる！）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX ENGINE STARTING ---" \n\
# 公式イメージの実行ファイルがある場所に移動するまる\n\
cd /opt/voicevox_engine \n\
\n\
# 実行ファイル名は ./run か ./voicevox_engine のどちらかだまる\n\
# 両方試して、ある方を起動するようにガードを固めたまる！\n\
if [ -f "./run" ]; then\n\
    ./run --host 0.0.0.0 --accept_all_terms &\n\
elif [ -f "./voicevox_engine" ]; then\n\
    ./voicevox_engine --host 0.0.0.0 --accept_all_terms &\n\
else\n\
    echo "Error: 実行ファイルが見つからないまる！パスを確認するだもん。"\n\
    ls -F /opt/voicevox_engine/\n\
fi\n\
\n\
echo "--- waiting for 60 seconds ---" \n\
sleep 60 \n\
\n\
cd /app \n\
echo "--- Discord Bot STARTING ---" \n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
