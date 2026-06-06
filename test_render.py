import urllib.request
import json
req = urllib.request.Request('https://eatbot-lifa.onrender.com/api/v1/orders/customer', data=b'{"order_ids":["123"]}', headers={'Content-Type': 'application/json'})
try:
    response = urllib.request.urlopen(req)
    print(response.read().decode())
except Exception as e:
    print(e)
