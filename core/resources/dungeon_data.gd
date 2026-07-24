class_name DungeonData extends Resource

## Un dungeon della mappa del mondo. I NUMERI non stanno qui: stanno in
## BalanceConfig, indicizzati per `tier`. Qui c'e' solo l'identita' del
## dungeon e la sua posizione nel grafo di sblocco.
##
## Piu' dungeon possono condividere lo stesso tier: hanno numeri identici e
## si distinguono per nemici, tema ed elemento. E' cosi' che il gioco ha
## molti dungeon senza avere molte curve di difficolta' da bilanciare.

enum Element { NONE, FUOCO, ACQUA, TERRA, ARIA, LUCE, OMBRA }

@export var id : String = ""
@export var display_name : String = ""

## 1-5. Determina HP e danno dei nemici, drop table e moltiplicatore shard.
@export_range(1, 5) var tier : int = 1

## Quante stanze prima del boss. Incide sulla ricompensa in shard.
@export_range(3, 30) var rooms : int = 10

## Affinita' del dungeon: guida i nemici che spawna e i Sigilli che droppa.
@export var element : Element = Element.NONE

## Id dei dungeon che questo sblocca al primo clear. Vuoto = foglia.
## Un solo id = tratto lineare. Piu' id = biforcazione.
@export var unlocks : Array[String] = []

## Se true, il modificatore di difficolta' (heat) e' selezionabile.
@export var allow_heat : bool = false
