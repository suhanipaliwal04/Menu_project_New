from PIL import Image, ImageEnhance

logo = Image.open('assets/images/eatbot_logo.png').convert('RGBA')
bg = Image.open('assets/images/eatbot_bg.png').convert('RGBA')

min_dim = min(bg.width, bg.height)
left = (bg.width - min_dim)/2
top = (bg.height - min_dim)/2
right = (bg.width + min_dim)/2
bottom = (bg.height + min_dim)/2
bg = bg.crop((left, top, right, bottom))

white_bg = Image.new('RGBA', bg.size, (255, 255, 255, 255))
bg = Image.blend(bg, white_bg, 0.4)

bbox = logo.getbbox()
if bbox:
    logo = logo.crop(bbox)

# Max safe zone for Android adaptive icons is ~66dp out of 108dp (61%)
# So we use 60% to be perfectly safe and maximum size
target_logo_width = int(bg.width * 0.6)
ratio = target_logo_width / logo.width
target_logo_height = int(logo.height * ratio)

logo = logo.resize((target_logo_width, target_logo_height), Image.Resampling.LANCZOS)

paste_x = (bg.width - logo.width) // 2
paste_y = (bg.height - logo.height) // 2

bg.paste(logo, (paste_x, paste_y), logo)

bg.save('C:/Users/Suhani/.gemini/antigravity-ide/brain/ddcf6538-9859-40ae-be10-48d087b7ebc2/preview_icon.png')
bg.save('assets/images/app_icon.png')
print('Created preview_icon.png')
