#!/bin/sh
# Builds the headless simulator from the iOS engine: the shipped AI is rewritten to play whichever side's turn it is.
set -e
cd "$(dirname "$0")"
R=../ios/Ruinaccord
mkdir -p .build
perl -pe 's/\(\.e([,)])/(me$1/g; s/\b(?<![\$\.])e\./E./g; s/\b(?<![\$\.])p\./P./g; s/big\(p\) > big\(e\)/big(P) > big(E)/g' $R/Game/AI.swift > .build/AISide.swift
cp $R/Resources/GameData.json .build/
swiftc -O -wmo $R/Model/*.swift $R/Game/Engine.swift .build/AISide.swift Sim/*.swift -o .build/sim
