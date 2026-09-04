import re

with open(r'D:\Yodha\Lomba\Alif peler\gemdev\Sprites\mes_boss.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

anims = re.findall(r'name": &"([^"]+)"', content)
print("Animations found:", set(anims))
