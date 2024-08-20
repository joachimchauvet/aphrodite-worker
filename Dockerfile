FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

ENV HOME=/workspace

WORKDIR $HOME

# Upgrade OS Packages + Prepare Python Environment
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y bzip2 g++ git make python3-pip tzdata \
    && rm -fr /var/lib/apt/lists/*

# Alias python3 to python
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN python3 -m pip install --no-cache-dir --upgrade pip


## Install from source
#RUN git clone https://github.com/PygmalionAI/aphrodite-engine.git /tmp/aphrodite-engine \
#   && mv /tmp/aphrodite-engine/* . \
#   && rm -fr /tmp/aphrodite-engine

# Install from PyPI
RUN pip install -U aphrodite-engine --extra-index-url https://downloads.pygmalion.chat/whl

## Install release candidate
#RUN pip install -U aphrodite-engine@git+https://github.com/PygmalionAI/aphrodite-engine.git@rc_054


# Allow build servers to limit ninja build jobs. For reference
# see https://github.com/PygmalionAI/aphrodite-engine/wiki/1.-Installation#build-from-source
ARG MAX_JOBS=32
ENV MAX_JOBS=${MAX_JOBS}

# Export the CUDA_HOME variable correctly
ENV CUDA_HOME=/usr/local/cuda

#ENV HF_HOME=/tmp
#ENV NUMBA_CACHE_DIR=$HF_HOME/numba_cache
ENV TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0 7.5 8.0 8.6 8.9 9.0+PTX"

## When installing from source
#RUN python3 -m pip install --no-cache-dir -e .

# Workaround to properly install flash-attn. For reference
# see: https://github.com/Dao-AILab/flash-attention/issues/453
RUN python3 -m pip install 'flash-attn>=2.5.8' --no-build-isolation

COPY builder/requirements.txt /requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install --upgrade -r /requirements.txt --no-cache-dir && \
    rm /requirements.txt

RUN apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

ADD src /

RUN mkdir -p /workspace/.cache/outlines \
    && chown -R 1000:0 /workspace/.cache

RUN chmod +x /start.sh

ENV MAX_CONCURRENCY=10
ENV GPU_MEMORY_UTILIZATION=0.99

# Entrypoint exec form doesn't do variable substitution automatically ($HOME)
ENTRYPOINT ["/start.sh"]
CMD ["runpod"]

EXPOSE 7860

# Service UID needs write access to $HOME to create temporary folders, see #458
RUN chown 1000:1000 ${HOME}

USER 1000:0

VOLUME ["/tmp"]
