import urllib.request
import json

data = json.dumps({"query": "pizza", "area_name": ""}).encode('utf-8')
req = urllib.request.Request("https://eatbot-lifa.onrender.com/api/v1/chat", data=data, headers={"Content-Type": "application/json"})
with urllib.request.urlopen(req) as response:
    print(json.dumps(json.loads(response.read()), indent=2))
