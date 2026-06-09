from PIL import Image

logo = Image.open('assets/images/eatbot_logo.png').convert('RGBA')
bg = Image.open('assets/images/eatbot_bg.png').convert('RGBA')

bbox = logo.getbbox()
if bbox:
    logo = logo.crop(bbox)

print('Cropped logo size:', logo.size)

target_logo_width = int(bg.width * 0.6)
ratio = target_logo_width / logo.width
target_logo_height = int(logo.height * ratio)

logo = logo.resize((target_logo_width, target_logo_height), Image.Resampling.LANCZOS)

paste_x = (bg.width - logo.width) // 2
paste_y = (bg.height - logo.height) // 2

bg.paste(logo, (paste_x, paste_y), logo)

# Crop bg to square if it's not
min_dim = min(bg.width, bg.height)
left = (bg.width - min_dim)/2
top = (bg.height - min_dim)/2
right = (bg.width + min_dim)/2
bottom = (bg.height + min_dim)/2
bg = bg.crop((left, top, right, bottom))

bg.save('assets/images/app_icon.png')
print('Created app_icon.png')
