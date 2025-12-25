FROM voicevox/voicevox_engine:cpu-ubuntu20.04-latest

USER root

RUN apt-get update && apt-get install -y python3-pip ffmpeg && apt-get clean

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

# start.sh を作成
RUN echo '#!/bin/bash\npython3 -m voicevox_engine --host 0.0.0.0 --port 50021 --accept_all_terms &\necho "--- waiting for 60 seconds ---"\nsleep 60\ncd /app\necho "--- Discord Bot STARTING ---"\npython3 bot.py\n' > start.sh && chmod +x start.sh

CMD ["./start.sh"]
