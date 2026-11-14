extends CharacterBody2D

# =====================================
# VIDA DEL CUY
# =====================================

signal vida_cambiada(vida_actual: int)

@export var vida_maxima: int = 3
@export var tiempo_invulnerabilidad: float = 1.0

var vida_actual: int = 3
var invulnerable: bool = false
var muerto: bool = false
var recibiendo_danio: bool = false


# =====================================
# MOVIMIENTO
# =====================================

const SPEED = 150.0
const JUMP_VELOCITY = -300.0

@onready var animacion: AnimatedSprite2D = $AnimatedSprite2D


# =====================================
# SISTEMA DE CAIDAS
# =====================================

@export var limite_caida: float = 550.0

var posicion_segura: Vector2
var tiempo_seguro: float = 0.0
var recuperandose: bool = false


func _ready() -> void:
	vida_actual = vida_maxima
	posicion_segura = global_position
	vida_cambiada.emit(vida_actual)


func _physics_process(delta: float) -> void:
	if muerto:
		return

	# GRAVEDAD
	if not is_on_floor():
		velocity += get_gravity() * delta

	# SALTO
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# MOVIMIENTO
	var direccion := Input.get_axis("izquierda", "derecha")
	velocity.x = direccion * SPEED

	# DIRECCION DEL CUY
	if direccion != 0:
		animacion.flip_h = direccion < 0

	# ANIMACIONES NORMALES
	if not recibiendo_danio:
		if direccion != 0:
			animacion.play("caminar_cuy")
		else:
			animacion.play("esperando_cuy")

	move_and_slide()

	# GUARDAR POSICION SEGURA
	if is_on_floor():
		tiempo_seguro += delta

		if tiempo_seguro >= 0.5:
			posicion_segura = global_position
			tiempo_seguro = 0.0
	else:
		tiempo_seguro = 0.0

	# DETECTAR CAIDA
	if global_position.y > limite_caida:
		caer()


# =====================================
# CAIDAS
# =====================================

func caer() -> void:
	if recuperandose or muerto:
		return

	recuperandose = true

	# Volver al ultimo punto seguro
	global_position = posicion_segura + Vector2(0, -8)
	velocity = Vector2.ZERO

	# Descontar un corazon
	recibir_danio(true)

	recuperandose = false


# =====================================
# RECIBIR DAÑO
# =====================================

func recibir_danio(es_caida: bool = false) -> void:
	if muerto:
		return

	# Evitar daño repetido por balas
	if invulnerable and not es_caida:
		return

	# Restar vida
	vida_actual = max(vida_actual - 1, 0)

	# Avisar a los corazones
	vida_cambiada.emit(vida_actual)

	# Si pierde los tres corazones
	if vida_actual <= 0:
		morir()
		return

	# Proteger contra otros disparos
	if not invulnerable:
		invulnerable = true
		terminar_invulnerabilidad()

	# Animacion al recibir bala
	if not es_caida:
		animar_danio()


# =====================================
# ANIMACION DE DAÑO
# =====================================

func animar_danio() -> void:
	if recibiendo_danio:
		return

	if not animacion.sprite_frames.has_animation("daño_cuy"):
		return

	recibiendo_danio = true
	animacion.play("daño_cuy")

	await animacion.animation_finished

	if not is_inside_tree() or muerto:
		return

	recibiendo_danio = false


# =====================================
# INVULNERABILIDAD TEMPORAL
# =====================================

func terminar_invulnerabilidad() -> void:
	await get_tree().create_timer(
		tiempo_invulnerabilidad
	).timeout

	if not is_inside_tree() or muerto:
		return

	invulnerable = false


# =====================================
# MUERTE Y REINICIO DEL NIVEL
# =====================================

func morir() -> void:
	if muerto:
		return

	muerto = true
	recibiendo_danio = false
	velocity = Vector2.ZERO

	# Animacion de muerte
	if animacion.sprite_frames.has_animation("muerto_cuy"):
		animacion.play("muerto_cuy")
		await animacion.animation_finished

	if not is_inside_tree():
		return

	# Reiniciar solo la escena actual
	get_tree().call_deferred("reload_current_scene")


# =====================================
# RECUPERAR VIDA CON COMIDA
# =====================================

func recuperar_vida() -> void:
	if muerto:
		return

	if vida_actual >= vida_maxima:
		return

	vida_actual += 1
	vida_cambiada.emit(vida_actual)
