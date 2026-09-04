import os

tscn_path = 'D:/Yodha/Lomba/Alif peler/gemdev/Sprites/player_archer.tscn'
with open(tscn_path, 'r', encoding='utf-8') as f:
    content = f.read()

# find the [node name="Archer" type="CharacterBody2D"...] and append groups=["player"]
content = content.replace(
    '[node name="Archer" type="CharacterBody2D" unique_id=692584052]',
    '[node name="Archer" type="CharacterBody2D" unique_id=692584052 groups=["player"]]'
)

with open(tscn_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Added player group to player_archer.tscn')
