# 1. Python 3.10 と VOICEVOX が最初から入っている有志の軽量イメージを借りるまる！
# これならビルド時のダウンロードや解凍の負荷が最小限で済むだもん
FROM yushulx/voicevox:latest

USER root

# 2. FFmpeg と 最小限のツールだけ入れるまる
RUN apt-get update && apt-get install -y ffmpeg python3-pip && apt-get clean

WORKDIR /app

# 3. Bot側のライブラリをインストール
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 4. プログラムをコピー
COPY . .

# 5. 起動スクリプト（このイメージは /nfs/voicevox_engine にエンジンがあるまる）
RUN echo '#!/bin/bash\n\
echo "--- VOICEVOX 起動開始だもん！ ---"\n\
cd /nfs/voicevox_engine\n\
# 規約に同意してバックグラウンドで起動するまる\n\
python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機 ---"\n\
sleep 60\n\
\n\
cd /app\n\
echo "--- Bot 起動だまる！ ---"\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]