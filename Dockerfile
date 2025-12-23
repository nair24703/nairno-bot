# 1. すべてが入っている公式イメージを土台にするまる
FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

# 2. 最小限のアップデートだけするまる（Python追加はしない！）
RUN apt-get update && apt-get install -y ffmpeg python3-pip && apt-get clean

# 3. 【ここが外科手術！】
# Python 3.8 でも TypeAlias エラーが出ないように、
# 必要なライブラリ(typing_extensions)を入れて、無理やり認識させるまる
RUN pip3 install --no-cache-dir typing_extensions uvicorn fastapi requests numpy pydantic==1.10.11

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY . .

# 4. 起動スクリプト
# 起動の直前に、Python 3.8 の typing モジュールに TypeAlias を無理やり植え付けるまる！
RUN echo '#!/bin/bash\n\
echo "--- 禁断の TypeAlias 手術を開始するまる！ ---"\n\
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.8/dist-packages\n\
\n\
# Python3.8 に TypeAlias を教え込む魔法の1行だもん\n\
python3 -c "import typing; from typing_extensions import TypeAlias; typing.TypeAlias = TypeAlias" \n\
\n\
cd /opt/voicevox_engine\n\
python3 run.py --host 0.0.0.0 --accept_all_terms &\n\
\n\
echo "--- 60秒待機（花丸の心臓が動き出すまる） ---"\n\
sleep 60\n\
cd /app\n\
python3 bot.py' > start.sh && chmod +x start.sh

CMD ["./start.sh"]