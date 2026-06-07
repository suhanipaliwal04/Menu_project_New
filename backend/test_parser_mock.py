import sys
from typing import List, Dict

# Mock tokens based on debug_tokens.txt
mock_tokens = [
    {'text': 'BREAKFAST', 'conf': 0.99, 'centre_y': 26, 'left_x': 24, 'right_x': 129},
    {'text': 'Eggs benedict', 'conf': 0.98, 'centre_y': 53, 'left_x': 24, 'right_x': 77},
    {'text': '$5', 'conf': 0.99, 'centre_y': 57, 'left_x': 167, 'right_x': 181},
    {'text': 'Waffie fresh berries', 'conf': 0.97, 'centre_y': 74, 'left_x': 25, 'right_x': 94},
    {'text': '$6', 'conf': 0.95, 'centre_y': 80, 'left_x': 167, 'right_x': 181},
    {'text': 'Porridge with cherries', 'conf': 0.99, 'centre_y': 98, 'left_x': 25, 'right_x': 105},
    {'text': 'Poached egg sandwiches', 'conf': 0.99, 'centre_y': 120, 'left_x': 23, 'right_x': 117},
    {'text': '$5', 'conf': 0.98, 'centre_y': 126, 'left_x': 167, 'right_x': 181},
    {'text': 'Banans and blackberry toast', 'conf': 0.96, 'centre_y': 144, 'left_x': 25, 'right_x': 128},
    {'text': 'Avocado cream cheese tosst', 'conf': 0.99, 'centre_y': 167, 'left_x': 25, 'right_x': 129},
    {'text': '$11', 'conf': 0.85, 'centre_y': 171, 'left_x': 167, 'right_x': 183},
    {'text': 'Porridge with cherries', 'conf': 0.98, 'centre_y': 188, 'left_x': 24, 'right_x': 103},
    {'text': '$7', 'conf': 0.99, 'centre_y': 193, 'left_x': 168, 'right_x': 179},
    {'text': 'JUICE', 'conf': 0.99, 'centre_y': 194, 'left_x': 420, 'right_x': 480},
    {'text': 'Banana and blackberry toast', 'conf': 0.99, 'centre_y': 210, 'left_x': 21, 'right_x': 125},
    {'text': '$9', 'conf': 0.94, 'centre_y': 214, 'left_x': 164, 'right_x': 177},
    {'text': 'Orange juice', 'conf': 0.99, 'centre_y': 228, 'left_x': 416, 'right_x': 476},
    {'text': 'SMOOTHIES', 'conf': 1.00, 'centre_y': 252, 'left_x': 27, 'right_x': 142},
    {'text': 'MAIN', 'conf': 1.00, 'centre_y': 254, 'left_x': 205, 'right_x': 252},
    {'text': 'Tomato juice', 'conf': 0.99, 'centre_y': 254, 'left_x': 417, 'right_x': 477},
    {'text': '$5', 'conf': 1.00, 'centre_y': 260, 'left_x': 539, 'right_x': 555},
    {'text': 'Green smoothie', 'conf': 0.99, 'centre_y': 275, 'left_x': 24, 'right_x': 101},
    {'text': 'Lasagna', 'conf': 1.00, 'centre_y': 275, 'left_x': 204, 'right_x': 237},
    {'text': 'S10', 'conf': 0.89, 'centre_y': 279, 'left_x': 363, 'right_x': 382},
    {'text': 'Pineapple juice', 'conf': 0.99, 'centre_y': 280, 'left_x': 416, 'right_x': 488},
    {'text': '.$6', 'conf': 0.89, 'centre_y': 282, 'left_x': 147, 'right_x': 165},
    {'text': '.$4', 'conf': 0.82, 'centre_y': 287, 'left_x': 537, 'right_x': 556},
    {'text': 'Beef stew', 'conf': 1.00, 'centre_y': 298, 'left_x': 204, 'right_x': 243},
    {'text': '.$9', 'conf': 0.72, 'centre_y': 302, 'left_x': 362, 'right_x': 379},
    {'text': 'Mango smoothie', 'conf': 0.98, 'centre_y': 302, 'left_x': 24, 'right_x': 105},
    {'text': 'Watermelon juice', 'conf': 0.97, 'centre_y': 308, 'left_x': 415, 'right_x': 496},
    {'text': '.$7', 'conf': 0.95, 'centre_y': 308, 'left_x': 147, 'right_x': 164},
    {'text': '$3', 'conf': 1.00, 'centre_y': 315, 'left_x': 538, 'right_x': 556},
    {'text': 'Salmon steal', 'conf': 0.96, 'centre_y': 320, 'left_x': 203, 'right_x': 253},
]

import app.services.ocr.menu_layout_parser as mlp

# Recreate the parse logic using tokens directly since we don't have the raw bbox output exactly
menu_items = []
all_orphan_items = []
all_orphan_prices = []

for row in mlp._group_rows(mock_tokens):
    for column in mlp._split_into_columns(row):
        pairs, orphan_items, orphan_prices = mlp._parse_row(column)
        for name, price in pairs:
            menu_items.append({"item": name, "price": price})
        all_orphan_items.extend(orphan_items)
        all_orphan_prices.extend(orphan_prices)

claimed_prices = set()
for orphan_item in all_orphan_items:
    best_price = None
    best_dist = float('inf')
    best_idx = -1

    for idx, orphan_price in enumerate(all_orphan_prices):
        if idx in claimed_prices:
            continue
        y_dist = abs(orphan_item['centre_y'] - orphan_price['centre_y'])
        if y_dist <= mlp.ORPHAN_Y_TOLERANCE:
            x_ok = orphan_price['left_x'] > orphan_item['right_x'] - 50
            if x_ok and y_dist < best_dist:
                best_dist = y_dist
                best_price = orphan_price['price']
                best_idx = idx

    if best_price is not None:
        menu_items.append({"item": orphan_item['name'], "price": best_price})
        claimed_prices.add(best_idx)

print(f"Extracted {len(menu_items)} items:")
for mi in menu_items:
    print(mi)
