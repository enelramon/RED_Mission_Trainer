extends Node

func _ready() -> void:
    print("Testing nave animacion textures...")
    for i in range(1, 9):
        var path = "res://fondo de inicio, animacion de nave/nave animacion%d.png" % i
        var tex = load(path)
        if tex != null:
            print("  OK frame %d loaded: %dx%d" % [i, tex.get_width(), tex.get_height()])
        else:
            print("  FAIL frame %d failed to load!" % i)
    get_tree().quit(0)
