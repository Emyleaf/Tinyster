# 📖 DIARIO DI SVILUPPO - TINYSTER

## ##### 29 aprile 2026

Inizio del diario di viaggio di questo sviluppo del gioco. Qua scriverò tutto ciò che ho fatto/farò in modo tale che chiunque possa capire il mio percorso, anche la AI per darmi una mano. 

La cartella principale del gioco contiene queste cartelle

1. assets (dove verranno collocati i vari assets come immagini)
2. scenes
3. scripts

Il gioco inizia con la scena game, che al suo interno ha, momentaneamente, la scena Player, un nodo Sprite2D per il suolo chiamato "Background" e uno Sprite2D a caso. 

La scena Player contiene uno Sprite2D del personaggio, una CollisionShape, un Camera2D e un AnimationPlayer. La scena inoltre ha attaccato con sé uno script, player.gd, con il seguente codice:

```gdscript
extends CharacterBody2D

@export var movement_speed : float = 500
var character_direction : Vector2

func _physics_process(delta):
    character_direction.x = Input.get_axis("move_left", "move_right")
    character_direction.y = Input.get_axis("move_up", "move_down")
    character_direction = character_direction.normalized()
    
    # Movimento
    if character_direction:
        velocity = character_direction * movement_speed
    else:
        velocity = velocity.move_toward(Vector2.ZERO, movement_speed)

    # ORIENTAMENTO SPRITE
    if character_direction.x > 0:
        $Sprite2D.flip_h = true      # guarda a destra
    elif character_direction.x < 0:
        $Sprite2D.flip_h = false     # guarda a sinistra

    move_and_slide()
```

Vorrei che il gioco fosse in GDScript, con un po' di hybrid di C# ove è necessario, ma la base vorrei fosse in GDScript.

Questo codice flippa lo sprite del personaggio, ma vorrei che per ogni direzione (8), avesse un determinato sprite. Se fermo (idle), un altro sprite, per un totale di 9 sprite escluse animazioni.

Cose fatte oggi: ho provato a fare il progetto in C# ma ho avuto un sacco di problemi, quindi sono passato al GDScript, modificando il codice di prima in

```gdscript
extends CharacterBody2D

# Variabili di movimento
@export var speed: float = 300.0

# Riferimento ai nodi figli
# Assicurati che il nome nel pannello Scena sia esattamente "AnimationPlayer"
@onready var _anim: AnimationPlayer = $AnimationPlayer

func _physics_process(_delta: float) -> void:
    # Otteniamo l'input dalle azioni che abbiamo creato nell'Input Map
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    
    if input_dir != Vector2.ZERO:
        # velocity è una proprietà nativa di CharacterBody2D
        velocity = input_dir * speed
        _update_animation(input_dir)
    else:
        velocity = Vector2.ZERO
        _anim.play("idle")
        
    # Funzione nativa per muovere il corpo fisico
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
```

in modo tale da tenere traccia delle animazioni di quando il personaggio cammina nelle varie direzioni. Ho il file sheet ma devo sistemarlo + metterlo in animationtree. 

## ##### 14 maggio 2026

Ho seguito un tutorial per l'animationplayer.

Ho scoperto come creare le varie animazioni, mettendo i frame, la durata, i keyframe.

Ho modificato lo script player perché 4 direzioni sono sufficienti. 

```gdscript
class_name Player extends CharacterBody2D

@export var move_speed : float = 500.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D

func _process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    
    if input_dir != Vector2.ZERO:
        velocity = input_dir * move_speed
        _update_animation(input_dir)
    else:
        velocity = Vector2.ZERO
        sprite.flip_h = 0
        animation_player.play("idle_down")

func _physics_process(_delta: float) -> void:
    move_and_slide()

func _update_animation(dir: Vector2) -> void:
    var anim_name := ""

    if abs(dir.x) >= abs(dir.y):
        anim_name = "walk_side"
        sprite.flip_h = dir.x < 0
    else:
        if dir.y > 0:
            anim_name = "walk_down"
        else:
            anim_name = "walk_up"

    if animation_player.current_animation != anim_name:
        animation_player.play(anim_name)
```

Sto creando gli State per il player, in modo tale da avere un'architettura che mi permetta di essere in un solo stato mentre attacco, idle o movement. 

Per i tileset ho letto:

- meglio 512x512, se puoi rimani sul piccolo
- meglio numeri divisibili per 4

## ##### 29 maggio 2026

Claude mi ha suggerito questa roadmap per il mio progetto

1. Player combat core: state machine, atk base, hitbox, danno, morte nemico
2. Singola stanza funzionante: spawn nemici, hp player/nemici, win/lose condition, HUD base
3. Struttura dungeon a nodi: mappa nodi, transizione stanze, porte chiuse dietro, tipi stanza
4. Progressione run: powerup, sistema equip, schermata fine run
5. Team system e sinergie: swap, 4 personaggi, applica status, combo trigger
6. hub e loop completo: città, mappa overview, sistema del tempo, save/load, run→hub→run

Per il primo passo fare:

1. State machine : Idle → Move → Attack → Hurt → Dead
2. Hitbox e Hurtbox : Area2D separata, segnale on_hit
3. Nemico base : Chase, attacca, muore; NavigationAgent2D
4. HUD base : hp, feedback danno, gameover
5. Segnali globali : autoload eventbus, player_died, enemy_hit

## ##### 20 giugno 2026

Ho sviluppato un po' di cose, tra cui un player funzionante, uno slime funzionante, interagiscono tra di loro, lo slime idle → wander e il player può sconfiggerlo. Poi ho costruito una mappa che mostra un dungeon generato. Poi ho costruito una stanza che spawna dei mostri e una stanza shop solo template. Darò in pasto ora tutto alla AI per farmi dire nel dettaglio cosa ho sviluppato e come funzionano tutti i pezzi di codice che ho creato.

---

## ##### 20 giugno 2026 - ANALISI COMPLETA DEL SISTEMA

Ora descrivo nel dettaglio tutto ciò che ho creato e come funziona ogni pezzo.

### **PARTE 1: SISTEMA DEL PLAYER**

#### **Il player.gd - Script Principale del Personaggio**

Il player è una `CharacterBody2D` che ha i seguenti compiti:
- Gestire la salute (HP)
- Ricevere input dal giocatore
- Emettere segnali importanti per il resto del gioco
- Interfacciare con lo state machine per delegare il comportamento

```gdscript
extends CharacterBody2D
class_name Player

@export var hp : int = 6
@export var max_hp : int = 6

var direction: Vector2 = Vector2.ZERO
var cardinal_direction: Vector2 = Vector2.DOWN

signal direction_changed(new_direction: Vector2)
signal player_damaged(hurt_box: HurtBox)
```

**Proprietà Principali:**
- `hp` e `max_hp`: rappresentano la salute. 1 cuore = 2 HP, quindi 6 HP = 3 cuori
- `direction`: il vettore input grezzo (con decimali)
- `cardinal_direction`: la versione "pura" di direction (UP, DOWN, LEFT, RIGHT solamente)

**Funzione `set_direction(new_dir: Vector2)`:**
```gdscript
func set_direction(new_dir: Vector2) -> bool:
    direction = new_dir
    var new_cardinal_direction = direction.round()
    
    if new_cardinal_direction != cardinal_direction:
        cardinal_direction = new_cardinal_direction
        direction_changed.emit(cardinal_direction)
        return true
    return false
```
Questa funzione standardizza la direzione di input a 4 direzioni cardinali (UP, DOWN, LEFT, RIGHT). Se la direzione cambia, emette un segnale. Ritorna `true` se la direzione è effettivamente cambiata, `false` altrimenti.

**Funzione `update_animation(state: String)`:**
```gdscript
func update_animation(state: String) -> void:
    _anim.play(state + "_" + anim_direction())
```
Concatena lo stato (es: "walk", "attack", "idle") con la direzione visuale (up, down, side). Quindi se stai camminando verso l'alto, riproduce "walk_up".

**Funzione `anim_direction()`:**
```gdscript
func anim_direction() -> String:
    if cardinal_direction == Vector2.UP:
        return "up"
    elif cardinal_direction == Vector2.DOWN:
        return "down"
    else:  # LEFT o RIGHT
        return "side"
```
Ritorna la direzione dell'animazione. Per LEFT e RIGHT usiamo lo stesso sprite ("side") e flippiamo lo sprite orizzontalmente.

**Funzione `update_hp(delta: int)`:**
```gdscript
func update_hp(delta: int) -> void:
    hp = clamp(hp + delta, 0, max_hp)
    PlayerHud.update_hp(hp, max_hp)
    if hp == 0:
        player_damaged.emit(null)
        state_machine.change_state(state_machine.state_dead)
```
Modifica la salute del player, aggiorna il visuale dell'HUD, e se la salute raggiunge 0, cambia lo stato a "dead".

**Funzione `make_invulnerable(duration: float)`:**
```gdscript
func make_invulnerable(duration: float) -> void:
    hit_box.monitoring = false
    await get_tree().create_timer(duration).timeout
    hit_box.monitoring = true
```
Rende il player invulnerabile per `duration` secondi disabilitando il hit_box (la zona di danno).

---

#### **Il player_state_machine.gd - Gestore degli Stati**

Questo script gestisce le transizioni tra i vari stati del player (Idle, Walk, Attack, Stun, Dead). È il "cervello" del gioco - decide quale stato il player dovrebbe essere in base agli input e agli eventi.

**Struttura:**
```gdscript
extends Node
class_name PlayerStateMachine

@onready var state_idle = $Idle
@onready var state_walk = $Walk
@onready var state_attack = $Attack
@onready var state_stun = $Stun
@onready var state_dead = $Dead

var current_state: State
var player: Player
```

**Funzione `initialize(new_player: Player)`:**
```gdscript
func initialize(new_player: Player) -> void:
    player = new_player
    
    for child in get_children():
        child.player = player
        child.state_machine = self
    
    change_state(state_idle)
```
Quando il gioco parte, questa funzione:
1. Salva il riferimento al player
2. Itera tutti gli stati figli e assegna loro il player e lo state machine
3. Cambia allo stato di Idle (inizio del gioco)

**Funzione `change_state(new_state: State)`:**
```gdscript
func change_state(new_state: State) -> void:
    if current_state:
        current_state.exit()
    
    current_state = new_state
    new_state.enter()
```
Quando è il momento di cambiare stato:
1. Chiama `exit()` sullo stato precedente (per pulire cose)
2. Cambia a nuovo stato
3. Chiama `enter()` sul nuovo stato (per inizializzare cose)

**Loop Principale (in `_process` e `_physics_process`):**
```gdscript
func _process(delta: float) -> void:
    current_state.process(delta)
    
func _physics_process(delta: float) -> void:
    current_state.physics(delta)
    
    var new_state = current_state.get_next_state()
    if new_state != current_state:
        change_state(new_state)
```
Ogni frame:
1. Chiama `process()` dello stato attuale (logica non-fisica)
2. Chiama `physics()` dello stato attuale (movimento, collisioni)
3. Chiama `get_next_state()` per vedere se è il momento di cambiare stato
4. Se ritorna uno stato diverso, cambia

---

#### **Gli Stati del Player**

Tutti gli stati estendono da una classe base `State` e si trovano in `player/scripts/states/`.

**STATE.GD - Classe Base di tutti gli stati:**

```gdscript
extends Node
class_name State

var player: Player
var state_machine: PlayerStateMachine

func init() -> void:
    pass

func enter() -> void:
    pass

func exit() -> void:
    pass

func process(delta: float) -> void:
    pass

func physics(delta: float) -> void:
    pass

func get_next_state() -> State:
    return self
```

Tutti gli stati hanno questi metodi. Uno stato che non cambia il comportamento di default rimane in sé stesso.

---

**STATE_IDLE.GD - Lo Stato Fermo:**

```gdscript
extends State
class_name StateIdle

func enter() -> void:
    player.update_animation("idle")

func process(delta: float) -> void:
    player.velocity = Vector2.ZERO
    player.set_direction(Input.get_vector("move_left", "move_right", "move_up", "move_down"))

func get_next_state() -> State:
    if player.direction != Vector2.ZERO:
        return state_machine.state_walk
    
    if Input.is_action_just_pressed("attack"):
        return state_machine.state_attack
    
    return self
```

Quando il player è fermo:
1. **`enter()`**: riproduce l'animazione "idle"
2. **`process()`**: legge l'input ma non fa muovere il player
3. **`get_next_state()`**: 
   - Se c'è movimento → passa a WALK
   - Se premi attacco → passa ad ATTACK
   - Altrimenti rimane in IDLE

---

**STATE_WALK.GD - Lo Stato di Movimento:**

```gdscript
extends State
class_name StateWalk

@export var move_speed: float = 400.0

func enter() -> void:
    player.update_animation("walk")

func process(delta: float) -> void:
    player.set_direction(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
    player.velocity = player.direction * move_speed
    
    if player.set_direction(player.direction):
        player.update_animation("walk")

func physics(delta: float) -> void:
    player.move_and_slide()

func get_next_state() -> State:
    if player.direction == Vector2.ZERO:
        return state_machine.state_idle
    
    if Input.is_action_just_pressed("attack"):
        return state_machine.state_attack
    
    return self
```

Quando il player si muove:
1. **`enter()`**: riproduce animazione "walk"
2. **`process()`**: legge input, imposta velocità
3. **`physics()`**: muove effettivamente il player (move_and_slide)
4. **`get_next_state()`**:
   - Se niente input → torna a IDLE
   - Se premi attacco → passa ad ATTACK
   - Altrimenti rimane in WALK

---

**STATE_ATTACK.GD - Lo Stato di Attacco:**

```gdscript
extends State
class_name StateAttack

@export var decelerate_speed: float = 5.0

func enter() -> void:
    player.update_animation("attack")

func process(delta: float) -> void:
    player.velocity -= player.velocity * decelerate_speed * delta

func physics(delta: float) -> void:
    player.move_and_slide()

func get_next_state() -> State:
    if not player._anim.is_playing():
        if player.direction != Vector2.ZERO:
            return state_machine.state_walk
        else:
            return state_machine.state_idle
    
    return self
```

Quando il player attacca:
1. **`enter()`**: riproduce l'animazione "attack"
2. **`process()`**: rallenta il player durante l'attacco (decelerate)
3. **`physics()`**: continua a muovere il player lentamente
4. **`get_next_state()`**: quando l'animazione finisce, torna a WALK o IDLE a seconda dell'input

**Cosa fa l'hitbox dell'attacco:**
- L'area di danno viene abilitata 0.075 secondi dopo l'inizio dell'animazione
- Durante questo frame, tutti gli Area2D che colpisce ricevono danno
- L'audio dell'attacco viene riprodotto con pitch random (0.9-1.1)

---

**STATE_STUN.GD - Lo Stato di Stordimento (quando il player è colpito):**

```gdscript
extends State
class_name StateStun

@export var knockback_speed: float = 200.0
@export var invulnerable_duration: float = 1.0

func enter() -> void:
    player.update_animation("idle")
    player.velocity = player.cardinal_direction * -knockback_speed
    player.make_invulnerable(invulnerable_duration)

func process(delta: float) -> void:
    player.velocity -= player.velocity * 10.0 * delta

func physics(delta: float) -> void:
    player.move_and_slide()

func get_next_state() -> State:
    if not player._anim.is_playing():
        if player.direction != Vector2.ZERO:
            return state_machine.state_walk
        else:
            return state_machine.state_idle
    
    return self
```

Quando il player viene colpito:
1. **`enter()`**: 
   - Riproduce animazione "idle" 
   - Applica un knockback (viene spinto indietro dalla direzione del colpo)
   - Viene reso invulnerabile per 1 secondo
2. **`process()`**: decelera il knockback
3. **`physics()`**: applica il movimento
4. **`get_next_state()`**: torna a WALK o IDLE quando finisce

---

#### **Sistemi di Supporto del Player**

**player_camera.gd:**
```gdscript
extends Camera2D

func _ready() -> void:
    LevelManager.tilemap_bounds_changed.connect(_on_tilemap_bounds_changed)

func _on_tilemap_bounds_changed(bounds: Rect2i) -> void:
    limit_left = int(bounds.position.x)
    limit_top = int(bounds.position.y)
    limit_right = int(bounds.position.x + bounds.size.x)
    limit_bottom = int(bounds.position.y + bounds.size.y)
```
La camera del player rimane dentro i limiti della mappa. Quando la tilemap cambia, aggiorna i limiti.

**player_interactions_host.gd:**
```gdscript
extends Node2D

func _ready() -> void:
    player.direction_changed.connect(_on_direction_changed)

func _on_direction_changed(new_direction: Vector2) -> void:
    rotation = new_direction.angle()
```
Questo nodo ruota per mostrare la direzione in cui il player sta guardando. Utile per le interazioni.

---

### **PARTE 2: SISTEMA DEI NEMICI**

#### **enemy.gd - Script Principale del Nemico**

I nemici sono simili al player ma più semplici:

```gdscript
extends CharacterBody2D
class_name Enemy

@export var hp: int = 3

var direction: Vector2 = Vector2.ZERO
var cardinal_direction: Vector2 = Vector2.DOWN

signal direction_changed(new_direction: Vector2)
signal enemy_damaged(hurt_box: HurtBox)
signal enemy_destroyed(hurt_box: HurtBox)
```

**Differenze dal Player:**
- Non hanno input (deciso dallo state machine)
- Hanno un'animazione di spawn all'inizio
- Possono emettere `enemy_destroyed` quando muoiono

**Funzione `play_start_animation()`:**
```gdscript
func play_start_animation() -> void:
    _anim.play("spawn")
    await _anim.animation_finished
    state_machine.initialize(self)
```
Quando un nemico viene spawnato:
1. Riproduce l'animazione "spawn"
2. Aspetta che finisca
3. Poi inizializza lo state machine (attiva gli stati)

Questo crea un effetto cool dove il nemico "appare" prima di iniziare a muoversi.

**Funzione `_take_damage(hurt_box: HurtBox)`:**
```gdscript
func _take_damage(hurt_box: HurtBox) -> void:
    hp -= hurt_box.damage
    if hp > 0:
        enemy_damaged.emit(hurt_box)
    else:
        enemy_destroyed.emit(hurt_box)
```
Quando il nemico riceve danno:
- Se HP > 0 → emette `enemy_damaged` (stato STUN)
- Se HP ≤ 0 → emette `enemy_destroyed` (stato DESTROY)

---

#### **enemy_state_machine.gd**

Identica al player state machine. Gestisce Idle, Wander, Stun, Destroy.

---

#### **Gli Stati dei Nemici**

**ENEMY_STATE_IDLE.GD:**

```gdscript
extends State
class_name EnemyStateIdle

@export var state_duration_min: float = 0.5
@export var state_duration_max: float = 1.5

var timer: float = 0.0

func enter() -> void:
    player.update_animation("idle")
    timer = randf_range(state_duration_min, state_duration_max)

func process(delta: float) -> void:
    timer -= delta
    player.velocity = Vector2.ZERO
    
    if timer <= 0:
        return get_next_state()

func get_next_state() -> State:
    if timer <= 0:
        return after_idle_state  # esportabile
    return self
```

Il nemico sta fermo per un tempo random tra 0.5-1.5 secondi, poi passa allo stato "after_idle_state" (configurabile).

---

**ENEMY_STATE_WANDER.GD:**

```gdscript
extends State
class_name EnemyStateWander

@export var wander_speed: float = 80.0

var direction_index: int = 0

func enter() -> void:
    direction_index = randi() % 4
    var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
    enemy.cardinal_direction = directions[direction_index]
    enemy.update_animation("walk")

func process(delta: float) -> void:
    enemy.velocity = enemy.cardinal_direction * wander_speed

func physics(delta: float) -> void:
    enemy.move_and_slide()

func get_next_state() -> State:
    if not enemy._anim.is_playing():
        return next_state  # esportabile
    return self
```

Il nemico sceglie una direzione casuale e cammina in quella direzione finché l'animazione finisce, poi passa a `next_state`.

---

**ENEMY_STATE_STUN.GD:**

```gdscript
extends State
class_name EnemyStateStun

@export var knockback_speed: float = 200.0

func enter() -> void:
    var direction = hurt_box.get_parent().global_position - enemy.global_position
    enemy.velocity = direction.normalized() * -knockback_speed
    enemy.update_animation("stun")

func process(delta: float) -> void:
    enemy.velocity -= enemy.velocity * 10.0 * delta

func physics(delta: float) -> void:
    enemy.move_and_slide()

func get_next_state() -> State:
    if not enemy._anim.is_playing():
        return next_state  # esportabile
    return self
```

Quando il nemico è colpito:
- Riceve un knockback
- Riproduce animazione "stun"
- Poi torna a `next_state` (di solito IDLE o WANDER)

---

**ENEMY_STATE_DESTROY.GD:**

```gdscript
extends State
class_name EnemyStateDestroy

func enter() -> void:
    enemy.hurt_box.monitoring = false
    var direction = hurt_box.get_parent().global_position - enemy.global_position
    enemy.velocity = direction.normalized() * -200.0
    enemy.update_animation("destroy")

func process(delta: float) -> void:
    enemy.velocity -= enemy.velocity * 10.0 * delta

func physics(delta: float) -> void:
    enemy.move_and_slide()

func get_next_state() -> State:
    if not enemy._anim.is_playing():
        await get_tree().create_timer(0.2).timeout
        enemy.queue_free()
        return self
    return self
```

Quando HP ≤ 0:
- Disabilita il hurt_box (non può più ricevere danno)
- Riceve un knockback finale
- Riproduce animazione "destroy"
- Aspetta 0.2 secondi
- Il nemico scompare dalla scena

---

### **PARTE 3: GENERATORE DI DUNGEON**

#### **map_generator.gd - L'Algoritmo**

Questo è il pezzo più complesso. Genera una mappa proceduralmente di un dungeon.

**Parametri di Configurazione:**

```gdscript
const FLOORS: int = 15           # Profondità del dungeon (15 piani)
const MAP_WIDTH: int = 7         # Larghezza (7 corsie verticali)
const X_DIST: float = 30.0       # Distanza orizzontale tra stanze
const Y_DIST: float = 25.0       # Distanza verticale tra stanze
const PATHS: int = 6             # Numero massimo di percorsi paralleli

const MONSTER_ROOM_WEIGHT: float = 10.0
const CAMPFIRE_ROOM_WEIGHT: float = 4.0
const SHOP_ROOM_WEIGHT: float = 2.5
```

La mappa è una griglia di 15×7. Ogni cella contiene una stanza. Il generatore collega le stanze creando "percorsi" che il giocatore può seguire.

**Algoritmo Principale:**

```gdscript
func generate() -> Array[Array]:
    _generate_initial_grid()                    # Step 1: crea griglia
    
    var starting_points = _get_random_starting_points()  # Step 2: sceglie dove iniziare
    var paths_to_explore: Array[Vector2i] = []
    
    for starting_point in starting_points:
        paths_to_explore.append(starting_point)
    
    # Step 3: per ogni percorso, connetti ogni piano al prossimo
    for current_floor in range(FLOORS - 1):
        for current_path_index in range(paths_to_explore.size()):
            var current_lane = int(paths_to_explore[current_path_index].y)
            _setup_connection(current_floor, current_lane)
    
    # Step 4: connetti tutte le stanze del piano 13 al boss
    _setup_boss_room()
    
    # Step 5: assegna i tipi di stanza
    _setup_room_types()
    
    return map_data
```

---

**Step 1: `_generate_initial_grid()`**

```gdscript
func _generate_initial_grid() -> void:
    for floor in range(FLOORS):
        var floor_rooms: Array[Room] = []
        
        for lane in range(MAP_WIDTH):
            var x = floor * X_DIST + randf_range(-5, 5)
            var y = lane * Y_DIST + randf_range(-5, 5)
            
            var room = Room.new()
            room.position = Vector2(x, y)
            room.row = lane
            room.column = floor
            room.type = Room.Type.NOT_ASSIGNED
            
            floor_rooms.append(room)
        
        map_data.append(floor_rooms)
```

Crea una griglia 15×7 dove ogni cella è una stanza con posizione random (+/- 5 pixel di offset).

---

**Step 2: `_get_random_starting_points()`**

```gdscript
func _get_random_starting_points() -> Array[Vector2i]:
    var starting_points: Array[Vector2i] = []
    var lanes_used: Array[int] = []
    
    var path_count = randi_range(2, PATHS)
    
    for i in range(path_count):
        var lane = randi_range(0, MAP_WIDTH - 1)
        
        if lane not in lanes_used:
            lanes_used.append(lane)
            starting_points.append(Vector2i(0, lane))  # Floor 0, random lane
    
    return starting_points
```

Sceglie 2-6 corsie casuali per iniziare i percorsi. Ad esempio: [corsia 1, corsia 3, corsia 5].

---

**Step 3: `_setup_connection(floor, lane)`**

Questo è il cuore dell'algoritmo. Per ogni floor-lane:

```gdscript
func _setup_connection(current_floor: int, current_lane: int) -> void:
    var next_floor = current_floor + 1
    
    # Scegli una corsia vicina nel prossimo piano
    var next_lane = clamp(
        current_lane + randi_range(-1, 1),  # ±1 corsia
        0, 
        MAP_WIDTH - 1
    )
    
    var current_room = map_data[current_floor][current_lane]
    var next_room = map_data[next_floor][next_lane]
    
    # Verifica che non incroci percorsi esistenti
    if not _would_cross_existing_path(current_room, next_room):
        current_room.next_rooms.append(next_room)
```

Per ogni stanza del piano N, la connette a una stanza casuale del piano N+1 (massimo ±1 corsia di distanza). Verifica che i percorsi non si incrocino.

---

**Step 4: `_setup_boss_room()`**

```gdscript
func _setup_boss_room() -> void:
    var boss_lane = MAP_WIDTH / 2  # Centro della mappa
    
    for room in map_data[FLOORS - 2]:  # Penultimo piano
        room.next_rooms.clear()
        room.next_rooms.append(map_data[FLOORS - 1][boss_lane])
```

Tutte le stanze del piano 13 vengono forzate a collegarsi alla stanza boss al centro del piano 14.

---

**Step 5: `_setup_room_types()`**

```gdscript
func _setup_room_types() -> void:
    for floor in range(FLOORS):
        for room in map_data[floor]:
            if room.next_rooms.size() == 0:
                continue  # Non assegnare tipo a stanze non collegate
            
            if floor == 0:
                room.type = Room.Type.MONSTER
            elif floor == 8:
                room.type = Room.Type.TREASURE
            elif floor == 13:
                room.type = Room.Type.CAMPFIRE
            else:
                _set_room_randomly(room)

func _set_room_randomly(room: Room) -> void:
    var total_weight = MONSTER_ROOM_WEIGHT + CAMPFIRE_ROOM_WEIGHT + SHOP_ROOM_WEIGHT
    var random_value = randf() * total_weight
    
    if random_value < MONSTER_ROOM_WEIGHT:
        room.type = Room.Type.MONSTER
    elif random_value < MONSTER_ROOM_WEIGHT + CAMPFIRE_ROOM_WEIGHT:
        room.type = Room.Type.CAMPFIRE
    else:
        room.type = Room.Type.SHOP
```

Assegna i tipi alle stanze con questi vincoli:
- Piano 0: MONSTER (obbligatorio)
- Piano 8: TREASURE (obbligatorio)
- Piano 13: CAMPFIRE (obbligatorio)
- Altro: RANDOM ma con pesi (mostri > campfire > shop)
- Vincoli aggiuntivi: niente CAMPFIRE prima del piano 4, niente CAMPFIRE/SHOP consecutive

---

#### **room.gd - Data Class**

```gdscript
extends Node
class_name Room

enum Type { NOT_ASSIGNED, MONSTER, CAMPFIRE, SHOP, TREASURE, BOSS }
enum Direction { NORTH, FORWARD, SOUTH }

var type: Type = Type.NOT_ASSIGNED
var row: int = 0           # Corsia verticale (0-6)
var column: int = 0        # Piano (0-14)
var position: Vector2      # Posizione visuale
var next_rooms: Array[Room] = []
var selected: bool = false

func get_direction_to(next_room: Room) -> Direction:
    if next_room.row < row:
        return Direction.NORTH
    elif next_room.row > row:
        return Direction.SOUTH
    else:
        return Direction.FORWARD
```

Una stanza è semplicemente un contenitore di dati. Contiene:
- Il tipo (MONSTER, CAMPFIRE, etc.)
- La posizione nella griglia
- Le stanze collegate (`next_rooms`)
- Un metodo per calcolare la direzione verso la prossima stanza

---

### **PARTE 4: VISUALIZZAZIONE DELLA MAPPA**

#### **map_room.gd - Singola Stanza nella Visualizzazione**

Una MapRoom è una `Area2D` che rappresenta una stanza sulla mappa del dungeon. È cliccabile e animata.

```gdscript
extends Area2D
class_name MapRoom

var room: Room
var available: bool = false

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

signal selected(room: Room)
```

**Funzione `set_room(new_room: Room)`:**

```gdscript
func set_room(new_room: Room) -> void:
    room = new_room
    global_position = new_room.position
    
    # Assegna l'icona giusta in base al tipo
    var texture_path = ""
    match room.type:
        Room.Type.MONSTER:
            texture_path = "res://dungeon/art/monster_room_icon.png"
            sprite.scale = Vector2(0.8, 0.8)
        Room.Type.CAMPFIRE:
            texture_path = "res://dungeon/art/campfire_room_icon.png"
            sprite.scale = Vector2(0.8, 0.8)
        Room.Type.SHOP:
            texture_path = "res://dungeon/art/shop_room_icon.png"
            sprite.scale = Vector2(0.8, 0.8)
        Room.Type.TREASURE:
            texture_path = "res://dungeon/art/treasure_room_icon.png"
            sprite.scale = Vector2(0.8, 0.8)
        Room.Type.BOSS:
            texture_path = "res://dungeon/art/boss_room_icon.png"
            sprite.scale = Vector2(1.0, 1.0)
    
    sprite.texture = load(texture_path)
```

Quando viene assegnata una stanza:
- Posiziona il sprite alla posizione della stanza
- Assegna l'icona corretta in base al tipo
- Scala l'icona (boss più grande)

**Funzione `_on_input_event(event: InputEvent)`:**

```gdscript
func _on_input_event(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if available:
            show_selected()
            selected.emit(room)

func show_selected() -> void:
    animation_player.play("select")
```

Quando il giocatore clicca:
- Se la stanza è disponibile, riproduce animazione "select" e emette il segnale `selected`

---

#### **map.gd - Gestore della Mappa Intera**

Questo script gestisce tutta la visualizzazione del dungeon e l'interazione del giocatore.

```gdscript
extends Node2D
class_name Map

@onready var rooms_container = $Rooms
@onready var lines_container = $Lines

var map_rooms: Array[MapRoom] = []
var camera_scroll_speed: float = 15.0

signal room_selected_to_enter(room: Room)
```

**Funzione `create_map(map_data: Array[Array])`:**

```gdscript
func create_map(map_data: Array[Array]) -> void:
    for floor_index in range(map_data.size()):
        var floor = map_data[floor_index]
        
        for room_in_floor in floor:
            if room_in_floor.next_rooms.size() == 0:
                continue  # Non visualizzare stanze non collegate
            
            _spawn_room(room_in_floor)
    
    # Aggiungi stanza boss
    var boss_room = map_data[14][3]
    _spawn_room(boss_room)
    
    # Centra la visualizzazione
    var center = Vector2(rooms_container.get_child(0).global_position)
    rooms_container.global_position = -center + get_viewport().get_visible_rect().size / 2
```

Percorre la mappa generata e spaw na tutte le MapRoom visuali.

**Funzione `_spawn_room(room: Room)`:**

```gdscript
func _spawn_room(room: Room) -> void:
    var map_room_scene = preload("res://dungeon/scenes/map_room.tscn")
    var map_room = map_room_scene.instantiate()
    
    map_room.set_room(room)
    map_room.selected.connect(_on_map_room_selected)
    
    rooms_container.add_child(map_room)
    map_rooms.append(map_room)
    
    _connect_lines(room)

func _connect_lines(room: Room) -> void:
    for next_room in room.next_rooms:
        var line = Line2D.new()
        line.add_point(room.position)
        line.add_point(next_room.position)
        line.width = 2.0
        line.modulate = Color.WHITE
        
        lines_container.add_child(line)
```

Spawna una MapRoom per ogni stanza connessa e disegna linee tra le stanze collegate.

**Funzione `unlock_floor(floor_number: int)`:**

```gdscript
func unlock_floor(floor_number: int) -> void:
    for map_room in map_rooms:
        if map_room.room.column == floor_number:
            map_room.available = true
            map_room.animation_player.play("highlight")
```

Quando il giocatore ha completato un piano, tutte le stanze del prossimo piano diventano cliccabili (animation "highlight" le illumina).

**Funzione `unlock_next_rooms()`:**

```gdscript
func unlock_next_rooms() -> void:
    var last_room = DungeonManager.last_room
    
    for map_room in map_rooms:
        if map_room.room in last_room.next_rooms:
            map_room.available = true
            map_room.animation_player.play("highlight")
```

Quando il giocatore entra in una stanza, le stanze collegate diventano disponibili.

**Funzione `_on_map_room_selected(room: Room)`:**

```gdscript
func _on_map_room_selected(room: Room) -> void:
    # Disabilita tutte le stanze dello stesso piano
    for map_room in map_rooms:
        if map_room.room.column == room.column:
            map_room.available = false
    
    # Aggiorna i dati globali
    DungeonManager.last_room = room
    DungeonManager.floors_climbed += 1
    
    # Scatta evento
    room_selected_to_enter.emit(room)
```

Quando il giocatore clicca una stanza:
1. Disabilita le altre stanze dello stesso piano
2. Salva quale stanza è stata scelta
3. Emette un segnale che fa caricare la scena della stanza

---

#### **room_monster.gd - Stanza con Mostri**

```gdscript
extends Node2D
class_name RoomMonster

@export var enemy_count: int = 6
@export var player_mask_radius: float = 200.0

@onready var tilemap = $TileMap
@onready var door = $Door

var spawned_enemies: int = 0

func _ready() -> void:
    await get_tree().create_timer(1.0).timeout
    spawn_enemies()

func spawn_enemies() -> void:
    var valid_cells: Array[Vector2i] = []
    
    # Raccogli tutte le celle valide della tilemap
    var used_cells = tilemap.get_used_cells(0)
    for cell in used_cells:
        var cell_position = tilemap.map_to_local(cell)
        
        # Scarta celle ai bordi e vicino al player
        if cell_position.distance_to(GlobalPlayerManager.player.global_position) > player_mask_radius:
            valid_cells.append(cell)
    
    # Spaw na i nemici
    enemy_count = randi_range(3, 6)
    
    for i in range(enemy_count):
        if valid_cells.is_empty():
            break
        
        var random_cell = valid_cells[randi() % valid_cells.size()]
        var spawn_position = tilemap.map_to_local(random_cell)
        
        var slime_scene = preload("res://enemies/slime/slime.tscn")
        var slime = slime_scene.instantiate()
        
        slime.global_position = spawn_position
        slime.enemy_destroyed.connect(_on_slime_enemy_destroyed)
        
        add_child(slime)
        slime.play_start_animation()

func _on_slime_enemy_destroyed(hurt_box: HurtBox) -> void:
    enemy_count -= 1
    
    if enemy_count <= 0:
        door.open_door()
```

Quando la stanza si carica:
1. Aspetta 1 secondo
2. Raccoglie tutte le celle della tilemap valide per lo spawn (non ai bordi, lontano dal player)
3. Spawna 3-6 slime casuali
4. Quando un nemico viene distrutto, decrementa il contatore
5. Quando tutti gli slime sono morti, apre la porta

---

#### **door.gd - La Porta**

```gdscript
extends Area2D
class_name Door

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func open_door() -> void:
    animation_player.play("destroy")
    await animation_player.animation_finished
    queue_free()

func _on_body_entered(body):
    if body is Player:
        # Ritorna alla mappa
        get_tree().reload_current_scene()
```

Quando la porta è aperta:
- Riproduce animazione "destroy"
- Quando il giocatore tocca la porta, ritorna alla mappa

---

### **PARTE 5: SISTEMA DI HUD**

#### **player_hud.gd - Gestore della Salute**

```gdscript
extends CanvasLayer
class_name PlayerHud

@export var heart_scene: PackedScene = preload("res://GUI/player_hud/heart_gui.tscn")

var hearts: Array[HeartGui] = []
var heart_container: HBoxContainer

func _ready() -> void:
    heart_container = HBoxContainer.new()
    add_child(heart_container)

func update_hp(hp: int, max_hp: int) -> void:
    update_max_hp(max_hp)
    
    for i in range(hearts.size()):
        var heart_value = clamp(hp - i * 2, 0, 2)
        update_heart(i, heart_value)

func update_max_hp(max_hp: int) -> void:
    var heart_count = roundi(max_hp * 0.5)
    
    while hearts.size() < heart_count:
        var new_heart = heart_scene.instantiate()
        hearts.append(new_heart)
        heart_container.add_child(new_heart)
    
    while hearts.size() > heart_count:
        var removed_heart = hearts.pop_back()
        removed_heart.queue_free()

func update_heart(index: int, hp: int) -> void:
    hearts[index].value = hp
```

Il sistema di cuori è semplice:
- 1 cuore = 2 HP
- Ogni cuore ha 3 stati: 0 (vuoto), 1 (mezzo), 2 (pieno)
- Esempio: 6 HP = 3 cuori pieni
- Esempio: 5 HP = 2 cuori pieni + 1 cuore mezzo + 1 cuore vuoto

**Flusso di Danno:**
```
Player colpito da nemico
→ hurt_box.damaged signal
→ Player._take_damage()
→ Player.update_hp(-damage)
→ PlayerHud.update_hp(hp, max_hp)
→ Update grafico dei cuori
```

---

#### **heart_gui.gd - Singolo Cuore**

```gdscript
extends Control
class_name HeartGui

@onready var sprite = $TextureRect

var value: int = 2:  # 0=empty, 1=half, 2=full
    set(new_value):
        value = new_value
        update_sprite()

func update_sprite() -> void:
    match value:
        0:
            sprite.frame = 0  # Empty
        1:
            sprite.frame = 1  # Half
        2:
            sprite.frame = 2  # Full
```

Ogni cuore è un'immagine che cambia frame in base al valore.

---

### **PARTE 6: MANAGER GLOBALI (Autoload)**

#### **dungeon_manager.gd**

```gdscript
extends Node

var map_data: Array[Array] = []
var floors_climbed: int = 0
var last_room: Room = null

func generate_new_map() -> void:
    var generator = MapGenerator.new()
    map_data = generator.generate()
    floors_climbed = 0
    last_room = null
```

Globale che contiene i dati della mappa attuale.

#### **global_player_manager.gd**

```gdscript
extends Node

var player: Player
var player_spawned: bool = false
```

Globale che contiene il riferimento al player (utile per averlo disponibile da qualsiasi script).

#### **game_manager.gd**

```gdscript
extends Node

var current_run: Run = null
```

Globale che contiene i dati della run attuale (ancora da implementare).

---

### **FLUSSO COMPLETO DI GIOCO**

```
1. AVVIO
   └─ DungeonManager.generate_new_map()
      └─ MapGenerator genera griglia 15×7
         └─ Map.create_map() visualizza tutto

2. GIOCATORE ESAMINA MAPPA
   └─ Usa Input "map" per aprire/chiudere
   └─ Scroll con "scroll_up"/"scroll_down"

3. GIOCATORE CLICCA STANZA
   └─ map_room._on_input_event() → seleziona stanza
   └─ Map._on_map_room_selected() → emette signal

4. CARICA STANZA (es: room_monster)
   └─ room_monster spawn_enemies() 
      └─ 3-6 slime spawnano in posizioni random
         └─ Ogni slime: play_start_animation() → state_machine.initialize()

5. COMBATTIMENTO
   ├─ Slime stato: Idle → Wander (loop)
   ├─ Player attacca:
   │  ├─ Input "attack" → state_attack
   │  ├─ After 0.075s → hit_box abilitato
   │  └─ Colpisce nemico
   ├─ Slime riceve danno:
   │  ├─ enemy_destroyed signal (se HP ≤ 0)
   │  └─ Stato: destroy → scompare
   └─ Ultimo slime muore → door.open_door()

6. COMPLETA STANZA
   └─ player.body_entered(door)
      └─ get_tree().reload_current_scene()
      └─ Ritorna in mappa (Map.create_map() ricaricata)
      └─ unlock_next_rooms() → stanze collegate diventano disponibili

7. RITORNA AL PASSO 3 (nuovo ciclo)
```

---

## **RIEPILOGO DELLO STATO ATTUALE (20 giugno 2026)**

✅ **COMPLETATO:**
- [x] Sistema di movimento del player (4 direzioni)
- [x] Sistema di attacco del player (hitbox, danno)
- [x] Sistema di salute (HUD con cuori)
- [x] State machine del player (Idle, Walk, Attack, Stun)
- [x] Sistema di nemici (Slime)
- [x] State machine dei nemici (Idle, Wander, Stun, Destroy)
- [x] Generatore di dungeon procedurali (15×7 griglia)
- [x] Visualizzazione della mappa del dungeon
- [x] Sistema di stanze (Monster, Shop, Campfire, Treasure, Boss)
- [x] Spawn nemici nelle stanze
- [x] Sistema di porte (aperte quando completata stanza)
- [x] Interazione player-nemici
- [x] Knockback e invulnerabilità post-danno

❌ **DA FARE (secondo la roadmap):**
- [ ] Boss room
- [ ] Segnali globali (EventBus)
- [ ] Sistema di powerup
- [ ] Sistema di equip
- [ ] Schermata di fine run
- [ ] Team system (4 personaggi)
- [ ] Sinergie tra personaggi
- [ ] Hub locale
- [ ] Save/Load
- [ ] Sistema del tempo

---

## **NOTE TECNICHE**

### **Animazioni Pattern**
Ogni animazione è nominata con pattern: `[azione]_[direzione]`
- Azioni: idle, walk, attack, stun, destroy
- Direzioni: up, down, side
- Esempi: "walk_up", "attack_side", "idle_down"

### **Segnali Importanti**
- `player.direction_changed(Vector2)` → Emesso quando cambia direzione
- `player.player_damaged(HurtBox)` → Quando player colpito
- `enemy.enemy_damaged(HurtBox)` → Quando nemico colpito
- `enemy.enemy_destroyed(HurtBox)` → Quando nemico muore
- `map.room_selected_to_enter(Room)` → Quando seleziona stanza

### **Performance Notes**
- Tilemap: 512×512 (come suggerito)
- Numeri divisibili per 4 (per il grid snapping)
- Massimo 6 slime per stanza (per non sovraccaricare)
- Knockback consiste in rimbalzi e decelerazione smooth

---

**Fine del diario del 20 giugno 2026**
