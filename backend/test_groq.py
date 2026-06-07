import json
from groq import Groq

client = Groq(api_key='[ENCRYPTION_KEY]')

items = ['Eggs benedict - $5', 'Waffle fresh berries - $6', 'Porridge with cherries - $5', 'Poached egg sandwiches - $5', 'Banana and blackberry toast - $11']

item_lines = '\n'.join([f'{j+1}. {it}' for j, it in enumerate(items)])

prompt = f"""You are a strict food classification system. Below are {len(items)} menu items extracted from a restaurant menu.
Restaurant: Unknown,

Items (item name — price — category status):
{item_lines}

For EACH item return a JSON array with exactly {len(items)} objects in the same order:
[
  {{
    "item_name": "cleaned item name",
    "price": <number>,
    "section_name": "Must be exactly the provided Section if given. If UNKNOWN, choose ONLY from the Permitted Categories list below.",
    "is_veg": true or false,
    "calories": <integer>,
    "health_score": <integer 1-10>,
    "description": "one short line description"
  }}
]

Permitted Categories:
[Chinese, North Indian, South Indian, Fast Food, Street Food, Biryani, Rice, Indian Breads, Curries & Gravies, Snacks & Starters, Desserts, Beverages, Salads & Healthy, Thali & Combos, Tandoor & Grills, Seafood, Egg Dishes]

Rules:
1. Fix obvious OCR noise in item names
2. If a Section is already provided in the input, you MUST use exactly that Section.
3. You MUST choose ONLY from the Permitted Categories.
4. is_veg: true only if definitely vegetarian, false if meat/egg/fish
5. calories MUST be an integer. Keep typical Indian food in mind.
6. health_score MUST be an integer 1-10. Salads/steamed items are 8-10. Fried/Desserts are 1-4.
7. Return ONLY the JSON array, no extra text.
"""

response = client.chat.completions.create(
    model='llama-3.1-8b-instant',
    messages=[
        {'role': 'system', 'content': 'You are a menu digitization expert. Return only valid JSON arrays.'},
        {'role': 'user', 'content': prompt}
    ],
    temperature=0.2,
    max_tokens=3500,
)
res = response.choices[0].message.content.strip()
print(res)
print(f"\nLength: {len(json.loads(res))}")
