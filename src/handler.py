import runpod
import aiohttp
import requests
import time
import os


def wait_for_service(url, max_retries=1000, delay=0.5):
    # Retry connecting to the service until it's available or max retries are reached
    retries = 0
    while retries < max_retries:
        try:
            requests.get(url)
            return
        except requests.exceptions.RequestException:
            print("Service not ready yet. Retrying...")
        except Exception as err:
            print("Error: ", err)
        time.sleep(delay)
        retries += 1
    raise Exception("Service not available after max retries.")


async def stream_response(job):
    # Configuration for the API endpoints and timeout
    config = {
        "baseurl": "http://127.0.0.1:4444",
        "api": {
            "completions": ("POST", "/v1/completions"),
            "chat_completions": ("POST", "/v1/chat/completions"),
        },
        "timeout": 300,
    }

    input_data = job["input"]

    # Determine whether to use chat_completions or completions API
    api_name = "chat_completions" if "messages" in input_data else "completions"
    api_verb, api_path = config["api"][api_name]

    url = f'{config["baseurl"]}{api_path}'

    # Prepare parameters based on the API type
    if api_name == "chat_completions":
        params = {
            "messages": input_data["messages"],
        }
    else:
        params = {
            "prompt": input_data["prompt"],
        }

    # Add model parameter, prioritizing input_data, then env variables
    params["model"] = input_data.get("model") or os.getenv("MODEL") or os.getenv("MODEL_NAME")

    # Add any additional sampling parameters
    sampling_params = input_data.get("sampling_params", {})
    params.update(sampling_params)

    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(url, json=params, timeout=config["timeout"]) as response:
                if response.status != 200:
                    yield {"error": await response.text()}
                    return

                content_type = response.headers.get("Content-Type", "")

                # Handle non-streaming or JSON responses
                if not params.get("stream", False) or "application/json" in content_type:
                    yield await response.json()
                    return

                # Process streaming responses
                async for line in response.content:
                    decoded_line = line.decode("utf-8").strip()
                    if decoded_line.startswith("data: "):
                        yield f"{decoded_line}\n\n"
                    elif decoded_line == "data: [DONE]":
                        yield "data: [DONE]\n\n"
                        break

        except aiohttp.ClientError as e:
            yield {"error": str(e)}
            return


async def async_generator_handler(job):
    # Wrapper function to handle the job and stream the response
    async for output in stream_response(job):
        yield output


def concurrency_modifier(currenct_concurrency):
    # Determine the maximum concurrency from environment variable
    max_concurrency = os.getenv("MAX_CONCURRENCY", 10)
    return int(max_concurrency)


if __name__ == "__main__":
    try:
        # Wait for the Aphrodite Engine API service to be ready
        wait_for_service(url="http://127.0.0.1:4444/v1/completions")
    except Exception as e:
        print("Service failed to start:", str(e))
        exit(1)

    print("Aphrodite Engine API Service is ready. Starting RunPod...")

    # Start the RunPod serverless handler
    runpod.serverless.start(
        {
            "handler": async_generator_handler,
            "concurrency_modifier": concurrency_modifier,
            "return_aggregate_stream": True,
        }
    )
