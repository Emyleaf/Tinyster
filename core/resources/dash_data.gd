class_name DashData extends Resource

## Come dasha un singolo personaggio. Assegnato in CharacterData.dash.
## Se e' null il personaggio non puo' dashare.

@export var speed : float = 500.0
@export var duration : float = 0.25
@export var cooldown : float = 1.0

## Inizio della finestra di invulnerabilita', in secondi dall'avvio del dash.
## Prima di questo istante il dash e' vulnerabile (startup).
@export var iframe_start : float = 0.06
## Durata della finestra. Fuori da [iframe_start, iframe_start + iframe_duration]
## si prende danno normalmente: e' il recupero.
@export var iframe_duration : float = 0.10

## Moltiplicatore dell'animazione riusata (walk_side) durante il dash.
@export var anim_speed : float = 2.0

## Effetto speciale a fine dash: bonus ATK piatto. 0 = nessun buff.
@export var buff_atk : int = 0
@export var buff_duration : float = 0.0
