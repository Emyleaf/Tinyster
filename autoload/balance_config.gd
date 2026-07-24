extends Node

## Fonte unica dei numeri trasversali. Le stat base di personaggi e nemici
## restano nei .tres: qui stanno solo le costanti che non appartengono a
## nessuna risorsa in particolare (energia ultimate, pool dei buff).

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

## Pool dei buff. I campi bonus_* hanno gli stessi nomi di EquipmentData,
## cosi' PartyMember._bonus() li somma senza sapere da dove arrivano.
## L'id serve solo al salvataggio.
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
