extends Node

## Fonte unica dei numeri trasversali. Le stat base di personaggi e nemici
## restano nei .tres: qui stanno solo le costanti che non appartengono a
## nessuna risorsa in particolare (energia ultimate, pool dei buff,
## bande equipaggiamento, drop table, economia).
##
## REGOLA: nessun numero di bilanciamento va scritto altrove.
##
## TIER, NON DUNGEON. I dungeon sono molti; i livelli di difficolta' sono 5,
## uno per rarita' di equipaggiamento. Piu' dungeon condividono lo stesso tier
## e si distinguono per tema, nemici e affinita' elementale, non per numeri.
## Il tier di un dungeon vive in DungeonData.tier (1-5).

# --- Energia ultimate (sistema Genshin) ---------------------------------------

## Energia guadagnata per ogni colpo dell'attacco base
const ENERGY_PER_BASIC_ATTACK : float = 2.0
## Energia guadagnata per ogni nemico ucciso
const ENERGY_PER_KILL : float = 4.0
## Quota che ricevono i membri FUORI campo. Indice = membri del party - 1.
## Stessi valori di Genshin: chi e' in campo prende sempre il 100%.
const ENERGY_OFFFIELD_MULT : Array[float] = [1.0, 0.8, 0.7, 0.6]

# --- Buff di fine stanza ------------------------------------------------------

## Quante carte vengono proposte quando si tocca la scala
const BUFF_CARDS : int = 3

## Tetto sulle percentuali accumulate in una run. Senza questo, ripescare
## piu' volte la stessa carta percentuale fa esplodere il danno.
const PCT_ATK_CAP : float = 1.0
const PCT_HP_CAP : float = 1.0

## Pool dei buff. I campi bonus_* hanno gli stessi nomi di EquipmentData,
## cosi' PartyMember._bonus() li somma senza sapere da dove arrivano.
## L'id serve solo al salvataggio.
## TODO: portare il pool a 25-30 voci. Con 8 voci e 3 carte per stanza,
## alla quarta stanza il giocatore ha gia' visto tutto.
const BUFF_POOL : Array[Dictionary] = [
	{ "id": "hp_flat", "buff_name": "Cuore di Pietra",
		"description": "+25 HP massimi", "bonus_max_hp": 25 },
	{ "id": "hp_pct", "buff_name": "Vigore Antico",
		"description": "+15% HP massimi", "pct_max_hp": 0.15 },
	{ "id": "atk_flat", "buff_name": "Lama Affilata",
		"description": "+4 ATK", "bonus_atk": 4 },
	{ "id": "atk_pct", "buff_name": "Furia Crescente",
		"description": "+12% ATK", "pct_atk": 0.12 },
	{ "id": "crit_rate", "buff_name": "Occhio del Falco",
		"description": "+8% probabilita' di critico", "bonus_crit_rate": 0.08 },
	{ "id": "crit_dmg", "buff_name": "Colpo Spietato",
		"description": "+30% danno critico", "bonus_crit_dmg": 0.30 },
	{ "id": "speed", "buff_name": "Passo Leggero",
		"description": "+15 velocita' di movimento", "bonus_speed": 15.0 },
	{ "id": "recharge", "buff_name": "Eco Elementale",
		"description": "+25% ricarica energia ultimate", "energy_recharge": 0.25 },
]

## Estrae n buff distinti dal pool
func roll_buffs(n : int) -> Array[RunBuff]:
	var pool : Array = BUFF_POOL.duplicate()
	pool.shuffle()
	var out : Array[RunBuff] = []
	for d : Dictionary in pool:
		if out.size() >= n:
			break
		out.append(RunBuff.new(d))
	return out

## Ricostruisce un buff dal suo id. Usato dal caricamento del salvataggio.
func get_buff(id : String) -> RunBuff:
	for d : Dictionary in BUFF_POOL:
		if d["id"] == id:
			return RunBuff.new(d)
	return null

# --- Tier ---------------------------------------------------------------------

const TIER_MIN : int = 1
const TIER_MAX : int = 5

## Da tier (1-5) a indice di array (0-4). Usala sempre: nessun altro file
## deve sapere che gli array partono da zero.
func ti(tier : int) -> int:
	return clampi(tier, TIER_MIN, TIER_MAX) - 1

# --- Nemici -------------------------------------------------------------------

## Indicizzati per tier. Tarati perche' un nemico normale muoia in
## "combo + 1 colpo" (3 hit) e il player incassi ~7 colpi prima di morire.
const ENEMY_HP  : Array[float] = [160.0, 200.0, 245.0, 295.0, 355.0]
const ENEMY_DMG : Array[float] = [ 18.0,  22.0,  26.0,  31.0,  37.0]

const ELITE_HP_MULT  : float = 4.0
const ELITE_DMG_MULT : float = 1.4
const BOSS_HP_MULT   : float = 16.0
const BOSS_DMG_MULT  : float = 2.0

func enemy_hp(tier : int, enemy_class : int = 0) -> float:
	var hp : float = ENEMY_HP[ti(tier)]
	match enemy_class:
		CLASS_ELITE: hp *= ELITE_HP_MULT
		CLASS_BOSS:  hp *= BOSS_HP_MULT
	return hp

func enemy_dmg(tier : int, enemy_class : int = 0) -> float:
	var dmg : float = ENEMY_DMG[ti(tier)]
	match enemy_class:
		CLASS_ELITE: dmg *= ELITE_DMG_MULT
		CLASS_BOSS:  dmg *= BOSS_DMG_MULT
	return dmg

# --- Equipaggiamento: bande per rarita' ---------------------------------------

## Livello massimo raggiungibile per rarita'. Indice = EquipmentData.Rarity.
const RARITY_CAP : Array[int] = [10, 20, 30, 40, 60]

## Ogni banda e' [valore a lv1, valore a lv max]. Il valore cresce linearmente
## dentro la banda. Le bande si SOVRAPPONGONO di proposito: un epico maxato
## batte ancora un leggendario appena droppato (fino a lv 24).
##
## Una sola fonte per stat: ATK solo dall'arma, HP solo dall'armatura.
## Se aggiungi ATK a un altro slot, la curva dei nemici va rifatta.
const BAND_ATK      : Array[Vector2i] = [
	Vector2i(3, 12), Vector2i(10, 25), Vector2i(20, 40),
	Vector2i(33, 55), Vector2i(45, 71),
]
const BAND_HP       : Array[Vector2i] = [
	Vector2i(5, 22), Vector2i(18, 46), Vector2i(37, 73),
	Vector2i(60, 101), Vector2i(82, 130),
]
const BAND_CRIT     : Array[Vector2] = [
	Vector2(0.008, 0.034), Vector2(0.028, 0.070), Vector2(0.056, 0.113),
	Vector2(0.093, 0.155), Vector2(0.127, 0.200),
]
const BAND_RECHARGE : Array[Vector2] = [
	Vector2(0.03, 0.10), Vector2(0.08, 0.20), Vector2(0.16, 0.32),
	Vector2(0.26, 0.44), Vector2(0.36, 0.55),
]

const RARITY_NAMES : Array[String] = [
	"Base", "Non comune", "Raro", "Epico", "Leggendario",
]

# --- Drop ---------------------------------------------------------------------

const CLASS_NORMAL : int = 0
const CLASS_ELITE  : int = 1
const CLASS_BOSS   : int = 2

## Probabilita' che il nemico droppi UN equip. Indice = CLASS_*.
const DROP_CHANCE : Array[float] = [0.04, 0.35, 1.0]

## Pesi della rarita' droppata: [tier][classe nemico][rarita'].
## Il boss garantisce sempre la rarita' di riferimento del suo tier:
## senza questo pavimento la progressione dipende dall'RNG e un giocatore
## sfortunato resta bloccato fuori dal tier successivo.
const DROP_WEIGHTS : Array = [
	# T1
	[ [90.0, 10.0,  0.0,  0.0,  0.0],
	  [60.0, 40.0,  0.0,  0.0,  0.0],
	  [ 0.0,100.0,  0.0,  0.0,  0.0] ],
	# T2
	[ [60.0, 35.0,  5.0,  0.0,  0.0],
	  [ 0.0, 70.0, 30.0,  0.0,  0.0],
	  [ 0.0,  0.0,100.0,  0.0,  0.0] ],
	# T3
	[ [ 0.0, 60.0, 35.0,  5.0,  0.0],
	  [ 0.0,  0.0, 70.0, 30.0,  0.0],
	  [ 0.0,  0.0,  0.0,100.0,  0.0] ],
	# T4
	[ [ 0.0,  0.0, 55.0, 40.0,  5.0],
	  [ 0.0,  0.0,  0.0, 70.0, 30.0],
	  [ 0.0,  0.0,  0.0,  0.0,100.0] ],
	# T5 — l'unico tier in cui i nemici normali droppano leggendari
	[ [ 0.0,  0.0, 20.0, 50.0, 30.0],
	  [ 0.0,  0.0,  0.0, 50.0, 50.0],
	  [ 0.0,  0.0,  0.0,  0.0,100.0] ],
]

# --- Economia -----------------------------------------------------------------

## Gold: si spende SOLO dentro il dungeon (reroll carte, cure). Perso alla morte.
const GOLD_PER_ROOM : int = 60

## Shard: si spendono SOLO a Serendipity per potenziare. Sopravvivono alla morte.
const SHARD_PER_ROOM : int = 5
const SHARD_PER_BOSS : int = 50
const SHARD_TIER_MULT : Array[float] = [1.0, 1.4, 2.0, 2.8, 3.9]

## Bonus al primo clear di un dungeon mai completato. E' la leva che rende
## conveniente esplorare i dungeon laterali invece di rifarne sempre uno solo.
const SHARD_FIRST_CLEAR_MULT : float = 3.0

## Modificatore di difficolta' opzionale (stile Heat di Hades), sbloccato
## sui dungeon di tier 5.
const HEAT_MAX : int = 6
const HEAT_SHARD_BONUS : float = 0.25

## Rimborso allo smantellamento. Elimina il sunk cost quando droppa una
## rarita' superiore: recuperi quasi tutto l'investito.
const DISMANTLE_REFUND : float = 0.75

## Costo in shard per salire da `level` a `level + 1`
func upgrade_cost(level : int) -> int:
	return 2 * level + 3

## Costo totale da lv 1 a `to_level`. Forma chiusa di upgrade_cost().
func total_cost(to_level : int) -> int:
	return maxi(0, (to_level - 1) * (to_level + 3))

## Shard restituiti smantellando un pezzo di livello `level`
func dismantle_value(level : int) -> int:
	return floori(total_cost(level) * DISMANTLE_REFUND)

## Shard guadagnati a fine dungeon. `heat` va da 0 a HEAT_MAX.
func run_shard_reward(tier : int, rooms_cleared : int, boss_killed : bool,
		heat : int = 0, first_clear : bool = false) -> int:
	var base : int = rooms_cleared * SHARD_PER_ROOM
	if boss_killed:
		base += SHARD_PER_BOSS
	var mult : float = SHARD_TIER_MULT[ti(tier)]
	mult *= 1.0 + HEAT_SHARD_BONUS * clampi(heat, 0, HEAT_MAX)
	if first_clear:
		mult *= SHARD_FIRST_CLEAR_MULT
	return roundi(base * mult)
