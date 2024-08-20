#!/bin/bash -e

echo 'Starting Aphrodite Engine API server...'

# Set umask to ensure group read/write at runtime
umask 002

# Enable command tracing
set -x

# Prepare optional arguments
OPTIONAL_ARGS=""

# Check and add optional arguments if they are set and not empty
if [ -n "$DOWNLOAD_DIR" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --download-dir ${DOWNLOAD_DIR:-${HF_HOME:?}/hub}"
fi

if [ -n "$MODEL" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --model $MODEL"
elif [ -n "$MODEL_NAME" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --model $MODEL_NAME"
fi

if [ -n "$REVISION" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --revision $REVISION"
fi

if [ -n "$DATATYPE" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --dtype $DATATYPE"
fi

if [ -n "$KVCACHE" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --kv-cache-dtype $KVCACHE"
fi

if [ -n "$MAX_MODEL_LEN" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --max-model-len $MAX_MODEL_LEN"
elif [ -n "$CONTEXT_LENGTH" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --max-model-len $CONTEXT_LENGTH"
fi

if [ -n "$NUM_GPUS" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --tensor-parallel-size $NUM_GPUS"
fi

if [ -n "$GPU_MEMORY_UTILIZATION" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --gpu-memory-utilization $GPU_MEMORY_UTILIZATION"
fi

if [ -n "$QUANTIZATION" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --quantization $QUANTIZATION"
fi

if [ -n "$ENFORCE_EAGER" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --enforce-eager"
fi

if [ -n "$KOBOLD_API" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --launch-kobold-api"
fi

if [ -n "$CMD_ADDITIONAL_ARGUMENTS" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS $CMD_ADDITIONAL_ARGUMENTS"
fi

# Start the Aphrodite Engine API server
if [ "$1" = "local" ]; then
    python3 -m aphrodite.endpoints.openai.api_server \
        --host 0.0.0.0 \
        --port 4444 \
        $OPTIONAL_ARGS &
else
    python3 -m aphrodite.endpoints.openai.api_server \
        --host 127.0.0.1 \
        --port 4444 \
        $OPTIONAL_ARGS &
fi

# Wait for the server to start
sleep 1

# Start the RunPod handler
if [ "$1" = "local" ]; then
    exec python -u /handler.py --rp_serve_api --rp_api_host='0.0.0.0' --rp_api_port 8000
else
    exec python -u /handler.py
fi
