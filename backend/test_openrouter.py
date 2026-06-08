import requests
import json
import base64

img_path = "d:/Users/Pranil/Github_Repos/Menu_project_New/backend/data/raw/4d44b8a1-02ee-4697-b844-bb9a45468c5a.jpeg"
with open(img_path, "rb") as f:
    img_data = base64.b64encode(f.read()).decode("utf-8")

# Let's test if the openrouter API is accessible.
# The user doesn't have an OpenRouter key yet, so I will just verify the code structure.
print("OpenRouter test code is ready. Needs API key.")
