extends VSlider

func _ready():
    var white = get_tree().get_root().find_node("WhiteBall",true,false).get_node("WhiteBall")
    white.connect("power_changed", self, "on_power_changed")
    set("max_value", white.MAX_POWER)

func on_power_changed(power):
    value = power


