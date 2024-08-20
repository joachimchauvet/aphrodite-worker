<div align="center">

# Aphrodite Engine | RunPod Worker

🚀 | A RunPod worker for the Aphrodite Engine, enabling efficient text generation and processing.

</div>

## 📖 | Getting Started

This worker runs the [Aphrodite Engine](https://github.com/PygmalionAI/aphrodite-engine) on [RunPod Serverless](https://www.runpod.io/serverless-gpu?ref=7ejcv617), allowing for efficient text generation and processing. To set up the worker on RunPod, follow these steps:

1. Go to the RunPod dashboard and create a new [serverless template](https://www.runpod.io/console/user/templates?ref=7ejcv617).
2. Input your container image or use the `joachimchauvet/worker-aphrodite-engine:latest` [pre-built image from DockerHub](https://hub.docker.com/r/joachimchauvet/worker-aphrodite-engine).
3. Select your desired GPU and other hardware specifications.
4. Set the environment variables as needed (see below).
5. Deploy a serverless endpoint using the template.

## 🔧 | Environment Variables

The following environment variables can be set to configure the Aphrodite Engine:

- `DOWNLOAD_DIR`: Directory to download the model (recommended: "/runpod-volume", see below)
- `MODEL` or `MODEL_NAME` (required): Name or path of the Hugging Face model to use
- `REVISION`: Specific model version to use (branch, tag, or commit ID)
- `DATATYPE`: Data type to use (auto, float16, bfloat16, float32)
- `KVCACHE`: KV cache data type
- `MAX_MODEL_LEN` or `CONTEXT_LENGTH`: Model context size
- `NUM_GPUS`: Number of GPUs for tensor parallelism
- `GPU_MEMORY_UTILIZATION`: GPU memory utilization factor
- `QUANTIZATION`: Quantization method
- `ENFORCE_EAGER`: If set, disables CUDA graphs
- `KOBOLD_API`: If set, launches the Kobold API
- `CMD_ADDITIONAL_ARGUMENTS`: Any additional command-line arguments

## 💾 | Using a Network Volume

It's recommended to use a network volume for model storage. To do this:

1. Create a network volume in your RunPod account.
2. When deploying the pod, attach the network volume.
3. Set the `DOWNLOAD_DIR` environment variable to "/runpod-volume".

This ensures that your models are persistently stored and can be reused across deployments.

## Example Inputs

### Regular Completions

```json
{
  "input": {
    "prompt": "Once upon a time",
    "sampling_params": {
      "max_tokens": 400,
      "temperature": 0.7
    }
  }
}
```

### Chat Completions

```json
{
  "input": {
    "messages": [{ "role": "user", "content": "Hello" }],
    "sampling_params": {
      "max_tokens": 100,
      "temperature": 0.7
    }
  }
}
```

## 🔗 | Links

📚 [Aphrodite Engine](https://github.com/PygmalionAI/aphrodite-engine)
🚀 [RunPod (affiliate link)](https://runpod.io?ref=7ejcv617)
