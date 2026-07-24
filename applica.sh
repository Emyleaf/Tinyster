#!/usr/bin/env bash
# Applica il sistema equip/bilanciamento al repo Tinyster.
# Uso: dalla ROOT del repo,  bash percorso/a/tinyster_equip/applica.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "project.godot" ]; then
	echo "ERRORE: eseguilo dalla root del repo (non trovo project.godot)." >&2
	exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".backup-equip-$STAMP"
mkdir -p "$BACKUP"

salva() {
	if [ -f "$1" ]; then
		mkdir -p "$BACKUP/$(dirname "$1")"
		cp "$1" "$BACKUP/$1"
	fi
}

echo "== Backup in $BACKUP"
for f in \
	autoload/balance_config.gd \
	autoload/party_manager.gd \
	core/resources/equipment_data.gd \
	actors/player/party_member.gd
do
	salva "$f"
done

echo "== Copia dei file (sostituiti e nuovi)"
mkdir -p autoload core/resources data/equipment
cp "$SRC/autoload/balance_config.gd"             autoload/balance_config.gd
cp "$SRC/autoload/economy.gd"                    autoload/economy.gd
cp "$SRC/core/resources/equipment_data.gd"       core/resources/equipment_data.gd
cp "$SRC/core/resources/equipment_generator.gd"  core/resources/equipment_generator.gd
cp "$SRC/core/resources/dungeon_data.gd"         core/resources/dungeon_data.gd

echo "== Patch chirurgica su party_member.gd e party_manager.gd"
# --fuzz=5 ignora i numeri di riga e aggancia sul contesto
if patch -p1 --fuzz=5 --no-backup-if-mismatch < "$SRC/chirurgica.patch"; then
	echo "   ok"
else
	echo "   FALLITA. Nulla e' andato perso: i file originali sono in $BACKUP" >&2
	echo "   Applica a mano le due funzioni descritte in BILANCIAMENTO.md sez. 10." >&2
	exit 1
fi

echo
echo "== Fatto. Restano due passi manuali:"
echo "   1) Project Settings > Autoload: aggiungi  Economy = res://autoload/economy.gd"
echo "   2) Cancella i salvataggi esistenti: il formato dell'equip e' cambiato"
echo "      (da stringa a dizionario; i vecchi equip vengono ignorati, non crashano)"
echo
echo "   Backup completo in $BACKUP"
