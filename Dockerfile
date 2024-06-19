FROM nvidia/cuda:11.4.3-cudnn8-runtime-ubuntu20.04
ENV PYTHON_VERSION=3.9
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update \
    && apt-get -qq install --no-install-recommends \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    python3-pip \
    python${PYTHON_VERSION}-dev build-essential \
    locales \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/* && \
    ln -s -f /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \
    ln -s -f /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    ln -s -f /usr/bin/pip3 /usr/bin/pip
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV ORIG_PATH=$PATH
# shas
ENV VIRTUAL_ENV=/opt/env/shas
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$ORIG_PATH"
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir transformers==4.37.2 torch==2.0.1 torchaudio==2.0.2 pandas tqdm numpy sacrebleu sacremoses webrtcvad pydub wandb SoundFile PyYAML scikit_learn tweepy
# faster-whisper
ENV VIRTUAL_ENV=/opt/env/fw
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$ORIG_PATH"
RUN pip install --no-cache-dir faster_whisper_cli==1.0.1 faster-whisper==0.10.0 ctranslate2==3.24.0
# helsinki
ENV VIRTUAL_ENV=/opt/env/helsinki
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$ORIG_PATH"
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir torch torchvision torchaudio transformers sentencepiece --index-url https://download.pytorch.org/whl/cu118
# Create app directory
WORKDIR /workspace
# Copy pipeline files
COPY srv_pipeline_cascade.sh srv_pipeline_direct.sh /FBK/
RUN mkdir -p /workspace/scripts
COPY scripts/. /workspace/scripts
# Copy and set SHAS files & env
RUN mkdir -p /workspace/SHAS
COPY SHAS/. /workspace/SHAS
ENV SHAS_ROOT=/workspace/SHAS
# Copy http server files
RUN mkdir -p /workspace/server/data
COPY CMD.httpserver_start.sh httpserver.py /workspace/server/
COPY data/. /workspace/server/data
# run the command
ENTRYPOINT ["entrypoint.sh"]