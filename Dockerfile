FROM python:3.9-slim-bullseye

ENV VOICEVOX_VERSION=0.14.1
ENV VOICEVOX_ENGINE_DIR=/opt/voicevox_engine

WORKDIR /app

# Install dependencies for VOICEVOX and bot
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
        curl \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download and extract VOICEVOX Engine
RUN curl -L -o voicevox_engine.tar.gz "https://github.com/VOICEVOX/voicevox_engine/releases/download/${VOICEVOX_VERSION}/voicevox_engine-linux-x64-${VOICEVOX_VERSION}.tar.gz" \
    && tar -xzf voicevox_engine.tar.gz -C /opt \
    && mv /opt/voicevox_engine-linux-x64-${VOICEVOX_VERSION} ${VOICEVOX_ENGINE_DIR} \
    && rm voicevox_engine.tar.gz

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create start.sh
RUN echo '#!/bin/bash\n\n# Start VOICEVOX Engine in the background\n${VOICEVOX_ENGINE_DIR}/run --host 0.0.0.0 --port 50021 --accept_all_terms & \n\necho "--- Waiting for VOICEVOX Engine to start (max 60 seconds) ---"\nTIMEOUT=60\nuntil curl -s http://127.0.0.1:50021/version > /dev/null || [ $TIMEOUT -eq 0 ]; do\n  echo "Waiting for VOICEVOX Engine..."\n  sleep 5\n  TIMEOUT=$((TIMEOUT-5))\ndone\n\nif [ $TIMEOUT -eq 0 ]; then\n  echo "VOICEVOX Engine did not start in time. Exiting."\n  exit 1\nfi\n\necho "--- Discord Bot STARTING ---"\npython bot.py\n' > start.sh \
    && chmod +x start.sh

CMD ["./start.sh"]