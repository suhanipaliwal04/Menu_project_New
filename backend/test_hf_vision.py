import os
import requests
import base64
from dotenv import load_dotenv

load_dotenv("d:/Users/Pranil/Github_Repos/Menu_project_New/backend/.env")
key = os.getenv("HUGGINGFACE_API_KEY")

img_path = "d:/Users/Pranil/Github_Repos/Menu_project_New/backend/data/raw/4d44b8a1-02ee-4697-b844-bb9a45468c5a.jpeg"
with open(img_path, "rb") as f:
    img_data = base64.b64encode(f.read()).decode("utf-8")

def test_model(model_id):
    url = f"https://api-inference.huggingface.co/models/{model_id}"
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    
    # Message format depends on the model, but HF Inference API standardizes chat templates
    payload = {
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Extract items from this menu. Respond with just JSON array of {item_name, price}."},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{img_data}"}}
                ]
            }
        ],
        "max_tokens": 1000
    }
    
    # Try chat completion endpoint first
    chat_url = f"https://api-inference.huggingface.co/models/{model_id}/v1/chat/completions"
    print(f"\nTesting {model_id} (v1/chat/completions)...")
    try:
        r = requests.post(chat_url, headers=headers, json=payload, timeout=30)
        print(r.status_code)
        if r.status_code == 200:
            print(r.json())
            return True
        else:
            print(r.text)
    except Exception as e:
        print(e)
    return False

# Models to test
models = [
    "meta-llama/Llama-3.2-11B-Vision-Instruct",
    "Qwen/Qwen2-VL-7B-Instruct"
]

for m in models:
    test_model(m)
