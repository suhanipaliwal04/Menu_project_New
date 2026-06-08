import os
from huggingface_hub import InferenceClient
from dotenv import load_dotenv

load_dotenv("d:/Users/Pranil/Github_Repos/Menu_project_New/backend/.env")
key = os.getenv("HUGGINGFACE_API_KEY")

client = InferenceClient(token=key)

img_path = "d:/Users/Pranil/Github_Repos/Menu_project_New/backend/data/raw/4d44b8a1-02ee-4697-b844-bb9a45468c5a.jpeg"

# test vision model
try:
    print("Testing Qwen2-VL-7B-Instruct...")
    res = client.chat_completion(
        model="Qwen/Qwen2-VL-7B-Instruct",
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "What is the first item on this menu? Just name it."},
                    {"type": "image_url", "image_url": {"url": img_path}}
                ]
            }
        ],
        max_tokens=100
    )
    print(res.choices[0].message.content)
except Exception as e:
    print("Qwen2-VL Error:", e)

try:
    print("\nTesting Llama-3.2-11B-Vision-Instruct...")
    res = client.chat_completion(
        model="meta-llama/Llama-3.2-11B-Vision-Instruct",
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "What is the first item on this menu? Just name it."},
                    {"type": "image_url", "image_url": {"url": img_path}}
                ]
            }
        ],
        max_tokens=100
    )
    print(res.choices[0].message.content)
except Exception as e:
    print("Llama-3.2 Error:", e)
