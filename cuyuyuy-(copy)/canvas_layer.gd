
extends CanvasLayer

@onready var cuy = $"../Cuy"
@onready var barra_vida = $HBoxContainer

func _ready() -> void:
	cuy.vida_cambiada.connect(barra_vida.actualizar_vida)
	barra_vida.actualizar_vida(cuy.vida_actual)
