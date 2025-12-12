# Signal Relay

A digital logic circuit simulator built in Godot for exploring computer architecture through circuit and blueprint design.

---

## Overview

Signal Relay is a logic simulator that lets you build digital circuits from basic logic gates. The goal is to create increasingly complex systems; starting with simple gates, you can build up to custom components and complex circuits including mini 8BIT Computers.

---

## Features

### Current

- **7 Logic Gates**: AND, OR, NOT, NAND, NOR, XOR, BUFFER
- **Sequential Gates**: D-FLIPFLOP
- **Input/Output**: INPUT, OUTPUT, CLOCK

- **Interactive Canvas**: Place, select, move, and delete gates on an infinite canvas
- **Component & Circuit Saving**: Save components and circuits to load as required
- **Real-time signal propagation**: Signal propagates in real-time

### Planned

- Undo/redo functionality
- Copy/paste functionality
- Completed 8BIT computer components

---

## Tech Stack

- **Godot 4.5.1** - Game engine for 2D rendering and scene management
- **GDScript** - Scripting language with type safety and fast iteration
- **JSON** - Human-readable circuit save format

---

## Installation

```bash
# Clone the repository
git clone https://github.com/rbessin/Signal-Relay.git

# Open in Godot 4.x
# File → Import → Select project.godot
# Press F5 to run
```

**Requirements:**

- Godot 4.5.1 or later
- Understanding of digital logic gates and circuits

---

## Project Structure

```
Signal-Relay/
├── assets/
│   ├── art/                # Art for UI & Canvas
│   ├── fonts/              # UI fonts
│   └── themes/             # Themes for UI
├── scenes/
│   ├── main.tscn           # Main scene
│   └── components          # Hard-coded components
├── scripts/
│   ├── main.gd             # Main scene controller
│   ├── components/         # Components & Subscripts (Pins, Gates...)
│   ├── managers/           # Event handlers and managers
│   ├── serialization/      # Circuit & component serialization
│   ├── ui/                 # UI helpers
│   └── world/              # Canvas helpers
└── project.godot           # Godot project config
```

---

## Acknowledgments

Inspired by Sebastian Lague's _Digital Logic Sim_ and his "Exploring How Computers Work" video series.

---
