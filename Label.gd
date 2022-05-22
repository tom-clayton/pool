extends Label

func _ready():
    var white = get_tree().get_root().find_node("WhiteBall",true,false).get_node("WhiteBall")
    white.connect("state_changed", self, "on_state_changed")

func on_state_changed(state):
    text = state
