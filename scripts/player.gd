extends CharacterBody2D

# Variabili di movimento
@export var speed: float = 300.0

# Riferimento ai nodi figli
# Assicurati che il nome nel pannello Scena sia esattamente "AnimationPlayer"
@onready var _anim: AnimationPlayer = $AnimationPlayer

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir != Vector2.ZERO:
		velocity = input_dir * speed
		# _update_animation(input_dir)
	else:
		velocity = Vector2.ZERO
		# _anim.play("idle")
		
	# Funzione per muovere il corpo fisico
	move_and_slide()

func _update_animation(dir: Vector2) -> void:
	var angle := rad_to_deg(dir.angle())
	var anim_name := ""
	
	# Logica per le 8 direzioni (N, NE, E, SE, S, SW, W, NW)
	if angle > -22.5 and angle <= 22.5:
		anim_name = "walk_e"
	elif angle > 22.5 and angle <= 67.5:
		anim_name = "walk_se"
	elif angle > 67.5 and angle <= 112.5:
		anim_name = "walk_s"
	elif angle > 112.5 and angle <= 157.5:
		anim_name = "walk_sw"
	elif angle > 157.5 or angle <= -157.5:
		anim_name = "walk_w"
	elif angle > -157.5 and angle <= -112.5:
		anim_name = "walk_nw"
	elif angle > -112.5 and angle <= -67.5:
		anim_name = "walk_n"
	elif angle > -67.5 and angle <= -22.5:
		anim_name = "walk_ne"
		
	if anim_name != "" and _anim.current_animation != anim_name:
		_anim.play(anim_name)
