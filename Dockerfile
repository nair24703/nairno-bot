FROM python:3.9-slim-bullseye

ENV VOICEVOX_VERSION=0.25.0
ENV VOICEVOX_ENGINE_DIR=/opt/voicevox_engine

WORKDIR /app

# Install dependencies for VOICEVOX and bot
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
        curl \
        wget \
        file \
        ca-certificates \
        p7zip-full \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download and extract VOICEVOX Engine (with retries and checks)
RUN set -eux \
    && echo "Downloading VOICEVOX engine: ${VOICEVOX_VERSION}" \
    && wget -q --show-progress -O voicevox_engine.7z.001 "https://github.com/VOICEVOX/voicevox_engine/releases/download/${VOICEVOX_VERSION}/voicevox_engine-linux-cpu-x64-${VOICEVOX_VERSION}.7z.001" || (echo "wget failed" && exit 1) \
    && echo "Downloaded file info:" && ls -lh voicevox_engine.7z.001 \
    && echo "File command output:" && file voicevox_engine.7z.001 || true \
    && echo "Trying to list archive contents (7z l)" && 7z l voicevox_engine.7z.001 || (echo "7z list failed" && ls -la . && exit 1) \
    && echo "Extracting archive to /tmp" && 7z x voicevox_engine.7z.001 -o/tmp || (echo "7z extraction failed" && ls -la /tmp && exit 1) \
    && EXTRACTED_DIR=$(find /tmp -maxdepth 1 -type d -name "voicevox_engine-linux-cpu-x64-*" -print -quit) \
    && if [ -z "$EXTRACTED_DIR" ]; then echo "Extraction succeeded but extracted dir not found" && ls -la /tmp && exit 1; fi \
    && echo "Moving extracted dir: $EXTRACTED_DIR -> ${VOICEVOX_ENGINE_DIR}" \
    && mkdir -p ${VOICEVOX_ENGINE_DIR} \
    && mv "$EXTRACTED_DIR" "${VOICEVOX_ENGINE_DIR}" \
    && rm -rf /tmp/*voicevox* \
    && rm -f voicevox_engine.7z.001

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create start.sh
RUN echo '#!/bin/bash\n\n# Start VOICEVOX Engine in the background\n${VOICEVOX_ENGINE_DIR}/run --host 0.0.0.0 --port 50021 --accept_all_terms & \n\necho "--- Waiting for VOICEVOX Engine to start (max 60 seconds) ---"\nTIMEOUT=60\nuntil curl -s http://127.0.0.1:50021/version > /dev/null || [ $TIMEOUT -eq 0 ]; do\n  echo "Waiting for VOICEVOX Engine..."\n  sleep 5\n  TIMEOUT=$((TIMEOUT-5))\ndone\n\nif [ $TIMEOUT -eq 0 ]; then\n  echo "VOICEVOX Engine did not start in time. Exiting."\n  exit 1\nfi\n\necho "--- Discord Bot STARTING ---"\npython bot.py\n' > start.sh \
    && chmod +x start.sh

CMD ["./start.sh"]
