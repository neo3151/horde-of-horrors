import re

with open('project.godot', 'r') as f:
    content = f.read()

# Replace the entire [autoload] section up to the [input] section
content = re.sub(
    r'\[autoload\](.*?)\[input\]', 
    '[autoload]\n\nGameManager="*res://scripts/GameManager.gd"\nPoolManager="*res://scripts/PoolManager.gd"\nUIManager="*res://scenes/UIManager.tscn"\n\n\n\n[input]', 
    content, 
    flags=re.DOTALL
)

# And fix the icon
content = content.replace('config/icon="res://icon.svg"', 'config/icon="res://assets/sprites/ui/icon_192.png"')

with open('project.godot', 'w') as f:
    f.write(content)
print("Fixed project.godot autoloads properly")
