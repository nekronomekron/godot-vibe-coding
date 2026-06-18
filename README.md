# Backpack Builder

Ein Godot-4-Prototyp im Stil von **Backpack Battles** mit **Sci-Fi-Setting**: Du baust ein **Raumschiff** per Drag & Drop auf.
- **Raumschiff** = das Gitter (früher Rucksack).
- **Module** = andockbare Schiffsräume (früher Stauraum).
- **Systeme** = Laserkanone, Railgun, Raketenwerfer, Deflektor, Reaktor, Sensor, Triebwerk (früher Items).

## Öffnen & Starten
1. Godot 4.3+ öffnen → **Importieren** → `project.godot` in diesem Ordner wählen.
2. Mit **F5** starten (Hauptszene ist `scenes/Main.tscn`).

## Aufbau des Bildschirms
- **Links – Rucksack:** ein Gitter (12×10). Start: ein fest verankerter **2×2-Stauraum** (gelb umrandet, nicht entfernbar).
- **Rechts – Händler:** zufällige Items + Button **„Neue Items (würfeln)“** für ein neues Angebot.
- **Unten – Kiste:** alle Items, die aktuell nicht im Rucksack platziert sind.

## Item-Arten
- **Stauraum** – erweitert den Rucksack. Kann nur platziert werden, wenn mindestens eine Zelle an bestehenden Stauraum angrenzt.
- **Items** – müssen vollständig auf Stauraum liegen. Jedes Item zeigt sein **Zellraster** (feine Trennlinien über dem Sprite), sodass immer erkennbar ist, wie viele Zellen es belegt.

## Bedienung
- **Linke Maustaste gedrückt halten** auf einem Item (Händler, Kiste oder im Rucksack) und ziehen.
- **Rechte Maustaste** während des Ziehens: Form um **90° nach rechts drehen** (mit weicher Dreh-Animation der Vorschau).
- Über dem Rucksack zeigt die Vorschau **grün = platzierbar / rot = nicht platzierbar**.
- Wird ein Item auf ein **bereits platziertes Item** gezogen (auf Stauraum), gilt das als gültig: Das darunterliegende Item wird verdrängt und gleitet in die Kiste.
- Loslassen über dem Rucksack platziert (wenn grün). Jedes nicht gültig platzierte Item **gleitet animiert in die Kiste** – auch wenn es „neben dem Stauraum" bzw. auf einem ungültigen Feld losgelassen wird oder bewusst auf die Kiste gezogen wird.
- **Abbruch:** Ein Item vom Händler, das wieder über dem Händler-Bereich losgelassen wird, bleibt im Angebot. Wird es woanders losgelassen, wird es erworben und fliegt in die Kiste. Items, die bereits in der Kiste liegen, bleiben dort.

### Rucksack-Ansicht (Pan & Zoom)
- Es wird **nicht das ganze Gitter** gezeichnet, sondern nur der Stauraum plus ~1,5–2 angedeutete freie Zellen ringsum, die transparent auslaufen.
- **Verschieben:** leere Fläche im Rucksack mit links ziehen, oder mittlere Maustaste ziehen.
- **Zoomen:** Mausrad über dem Rucksack (zoomt auf den Mauszeiger).
- Der Stauraum kann nicht vollständig aus dem Sichtbereich geschoben werden (sein Mittelpunkt bleibt im Fenster).

### Stauraum aufnehmen / verschieben
- Nicht-verankerter Stauraum kann aufgenommen und neu platziert werden – auch wenn bereits **Items darauf liegen**. Diese Items wandern dabei automatisch in die Kiste.
- Wird durch das Aufnehmen ein Teil des Gitters vom verankerten 2×2-Stauraum **abgetrennt** („bricht auseinander"), wandert der lose Stauraum samt aller darauf liegenden Items ebenfalls in die Kiste.
- Automatisch verdrängte Items/Stauraum **gleiten animiert** aus dem Rucksack in die Kiste, bevor sie dort als Eintrag erscheinen.

## Szenen (.tscn)
- `scenes/Main.tscn` – Werft/Editor (Raumschiff bauen). Hauptszene. Button „▶ Kampf starten" wechselt ins Gefecht.
- `scenes/Battle.tscn` – **Kampfbildschirm im FTL/Down-with-the-Ship-Stil**: oben Hülle (segmentierter Balken), Schild-Schichten und Ressourcen-Chips (Munition/Raketen/Mannschaft/Energie/Ausweichen) beider Schiffe; mittig beide Schiffe + Gefechts-Panel; unten die Reaktor-Energieverteilung (vertikale Pips je Subsystem) und die Waffenleiste mit Echtzeit-Ladebalken. Waffen laden in Echtzeit auf, der Gegner feuert automatisch, „FEUERN" gibt geladene Waffen frei. Beim Schuss zeigt eine Effekt-Ebene (`FxLayer`) **Laserstrahlen, fliegende Raketen und Treffer-Einschläge** zwischen den Schiffen.
- `scenes/ItemWidget.tscn` – wird zur Laufzeit für jedes System in Werft/Frachtraum instanziiert.
- `scenes/FlyingPiece.tscn` – Overlay für die Flug-Animation in die Kiste.
- `scenes/ShipView.tscn` – ein Schiff als Sprite-Aufbau (in Battle.tscn instanziiert + zur Laufzeit für Anflug/Hero).
- `scenes/StatBar.tscn`, `ResourceChip.tscn`, `PowerColumn.tscn`, `WeaponSlot.tscn`, `ShieldRow.tscn` – wiederverwendbare HUD-Widgets (Control + Skript), in Battle.tscn instanziiert bzw. zur Laufzeit befüllt.

## Spielfluss
Werft (Schiff bauen) → „Kampf starten" → **Anflug-Animation** → Gefecht → „Zurück zur Werft" (Schiff bleibt erhalten). Die Konfiguration wird im Autoload `GameState` gehalten; der Gegner wird per `ShipGen` aus denselben Modulen/Systemen erzeugt, Gefechtswerte per `ShipStats`.

### Anflug-Animation
Beim „Kampf starten": Werft-UI fliegt nach oben raus und blendet aus, das Schiff beschleunigt nach rechts aus dem Bild (Main.gd). In der Battle-Szene (`GameState.intro`): das HUD bleibt zunächst verborgen, das Spielerschiff fliegt von links abbremsend herein, kurz darauf der Gegner von rechts. Beide landen exakt auf der Position/Größe ihres HUD-Schiff-Panels (`%PlayerShip`/`%EnemyShip`), dann blendet das HUD per Crossfade an gleicher Stelle ein – nahtlos, ohne Sprung – und die Runde startet (`Battle._play_intro`).

## Grafik-Assets & Theme
Echte Vektorgrafiken (SVG, von Godot gerastert) unter `assets/`:
- `assets/storage_cell.svg` – Tile für eine Modul-Zelle (Schiffsboden mit Eck-Markierungen).
- `assets/items/*.svg` – Sprites: Laserkanone, Reaktor, Deflektor, Raketenwerfer, Sensor, Railgun, Triebwerk.
- `assets/items/*_a1..a3.svg` + `*_frames.tres` – animierte Frames + `SpriteFrames` für die Waffen (Laserkanone, Railgun, Raketenwerfer).
- `assets/ui_theme.tres` – Sci-Fi-Dark-Theme (HUD-Karten mit Cyan-Rändern/Glow, neon Buttons, **Pixel-Font VT323** als Default). Auf `Main`/`Battle` gesetzt, vererbt sich auf alle Panels/Buttons.
- `assets/fonts/VT323-Regular.ttf` – Pixel-/CRT-Font (SIL Open Font License, siehe `assets/fonts/OFL.txt`). Custom-gezeichnete HUD-Texte nutzen sie via `get_theme_default_font()`.
- `assets/hud/*.svg` – texturierte HUD-Grafiken im „Down with the Ship"-Stil (Nine-Patch): `panel.svg` (Metallrahmen mit Eckwinkeln/Nieten), `button.svg`/`_hover`/`_pressed` (beveled Buttons), `slot.svg` (vertiefter Balken-Track), `chip.svg` (Ressourcen-Plattenrahmen). Eingebunden via StyleBoxTexture im Theme bzw. `HudArt.gd` für die Custom-Widgets.

## Code
- `scripts/Main.gd` – zentrale Drag-&-Drop-Logik (referenziert die Knoten aus `Main.tscn`)
- `scripts/Backpack.gd` – Gitter-Modell, Platzierungsregeln, Sprite-Rendering (Pan/Zoom via Node2D-Transform)
- `scripts/ItemDB.gd` – Vorlagen für Stauraum/Items inkl. Texturen/SpriteFrames, Zufallsangebot
- `scripts/ShapeUtil.gd` – Tetris-Formen rotieren/normalisieren
- `scripts/DrawProxy.gd` – Zeichen-Helfer-Node2D (Halo-/Overlay-Ebenen des Editors)
- `scripts/ItemWidget.gd` – Item-Vorschau in Händler/Kiste (Sprite-Node)
- `scripts/FlyingPiece.gd` – einzelnes Flug-Overlay (Sprite-Node)
- `scripts/DragLayer.gd` – Ghost-Vorschau, die dem Mauszeiger folgt
