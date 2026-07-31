from pathlib import Path
t = Path(r"c:\Users\WIN10\Desktop\godot\scripts\content\ui_text.gd").read_text(encoding="utf-8")
print("has_gold", "\u91d1\u5e01" in t)
print("has_title", "\u8ff7\u4f60\u5854\u9632" in t)
print("font", Path(r"c:\Users\WIN10\Desktop\godot\assets\fonts\msyh.ttc").exists())
# show title line bytes
for line in t.splitlines():
    if '"title"' in line:
        print(line.encode("unicode_escape").decode("ascii"))
        break
