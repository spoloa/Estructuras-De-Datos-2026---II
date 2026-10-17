class_name OptionsMenu
extends MenuScreen
## Menú de opciones (se apila encima de la pausa): control de volumen y botón Volver.


func _ready() -> void:
	var box := build_layout("OPCIONES")

	var label := Label.new()
	label.text = "Volumen"
	box.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	slider.value_changed.connect(_on_volume_changed)
	box.add_child(slider)

	add_button(box, "Volver", ScreenManager.pop_screen).grab_focus()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_mute(0, value == 0.0)
	if value > 0.0:
		AudioServer.set_bus_volume_db(0, linear_to_db(value))
