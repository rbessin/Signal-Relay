# Signal Relay

A digital logic circuit simulator built in Godot for exploring computer architecture fundamentals through interactive circuit design.

**Current Status:** Phase 2 Complete - Starting Phase 3 (Wire Connections)

---

## Overview

Signal Relay is an educational logic simulator that lets you build digital circuits from basic logic gates. The goal is to create increasingly complex systems through hierarchical abstraction - starting with simple gates and eventually building up to custom components and complex circuits.

---

## Features

### Current (Working)
- **6 Logic Gates**: AND, OR, NOT, NAND, NOR, XOR
- **Interactive Canvas**: Place, select, and move gates on an infinite canvas
- **Visual Feedback**: Selection highlighting with borders and mode indicators
- **Delete Gates**: Remove unwanted gates with Backspace/Delete keys
- **Drag & Drop**: Click and drag to reposition gates
- **Mode System**: Switch between Interact and Place modes

### Planned
- Wire connections between gate pins
- Real-time signal propagation and simulation
- Save and load circuit designs
- Custom chip creation from existing circuits
- Hierarchical design (use custom chips within other circuits)
- Undo/redo functionality

---

## Next Steps
- **Zooming**: Implement zoom in and out
- **Panning**: Implement camera movement
- **Improved UI**: Modify the UI to be more pleasing

---

## Tech Stack

- **Godot 4.x** - Game engine for 2D rendering and scene management
- **GDScript** - Scripting language with type safety and fast iteration
- **JSON** - Human-readable circuit save format (planned)

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
- Godot 4.x or later
- Basic understanding of digital logic gates

---

## Project Structure

```
Signal-Relay/
├── scenes/
│   ├── main.tscn           # Main circuit canvas
│   ├── ui/                 # UI components and toolbar
│   └── gates/              # Gate scene templates
├── scripts/
│   ├── main.gd             # Main scene controller
│   ├── core/
│   │   └── gate.gd         # Base gate class
│   └── gates/              # Individual gate implementations
│       ├── and_gate.gd
│       ├── or_gate.gd
│       ├── not_gate.gd
│       └── ...
└── project.godot           # Godot project config
```

---

## JSON File Structure

```
{
    "circuit_name": "HALF ADDER",
    "gates": [
        {"uid": 1, "type": "INPUT", "x": 100, "y": 200},
        {"uid": 2, "type": "AND", "x": 300, "y": 150},
        {"uid": 3, "type": "OUTPUT", "x": 230, "y": 160},
    ],
    "wires": [
        {"from_gate": 1, "from_pin": 0, "to_gate": 2, "to_pin": 1}
    ]
}
```

---

## Development Roadmap

### ✅ Phase 1: Basic Gates (Complete)
- [x] Gate base class with polymorphic evaluate() method
- [x] All 6 basic logic gates (AND, OR, NOT, NAND, NOR, XOR)
- [x] Input toggle and output display components
- [x] Type-safe GDScript with comprehensive type hints
- [x] Dynamic visual generation (ColorRect + Label)
- [x] Collision detection system (Area2D)

### ✅ Phase 2: Interactive Canvas (Complete)
- [x] Gate placement system with toolbar buttons
- [x] Visual selection feedback with colored borders
- [x] Drag and drop gate positioning
- [x] Delete functionality (Backspace/Delete keys)
- [x] Two-mode system (INTERACT/PLACE modes)
- [x] Mode indicator in UI
- [x] Select tool button for mode switching
- [x] Signal-based communication between gates and main scene

### 🔄 Phase 3: Wire Connection System (In Progress)
- [X] Pin class for gate input/output connection points
- [X] Wire class for connections between pins
- [X] Visual pin indicators on gates
- [X] Click-and-drag wire creation interface
- [X] Wire rendering with curves or lines
- [X] Connection validation (prevent invalid connections)
- [X] Wire deletion functionality
- [X] Signal propagation through wire network
- [ ] Topological sorting for correct evaluation order
- [X] Visual feedback for signal states (high/low)

### Phase 4: Circuit Persistence
- [ ] Circuit serialization to JSON format
- [ ] Save current circuit to file
- [ ] Load circuit from file
- [ ] File picker UI integration
- [ ] Circuit validation on load
- [ ] Handle missing or invalid gate types
- [ ] Auto-save functionality (optional)

### Phase 5: Custom Chip Abstraction
- [ ] Define custom chip interface (which pins are exposed)
- [ ] Convert existing circuits into reusable chip definitions
- [ ] Save custom chips as separate files
- [ ] Custom chip library/catalog UI
- [ ] Instantiate custom chips as gates on canvas
- [ ] Nested simulation engine (chips within chips)
- [ ] Custom chip editing (modify existing chips)
- [ ] Visual distinction between basic gates and custom chips

### Phase 6: Polish & Advanced Features
- [ ] Undo/redo system with command pattern
- [ ] Pan and zoom canvas navigation
- [ ] Grid snapping for neat circuit layouts
- [ ] Wire routing improvements (avoid overlaps)
- [ ] Performance optimization for large circuits
- [ ] Advanced components (7-segment displays, memory, clock signals)
- [ ] Circuit testing tools (truth tables, timing diagrams)
- [ ] Dark/light theme toggle
- [ ] Keyboard shortcuts reference

---

## Acknowledgments

Inspired by Sebastian Lague's *Digital Logic Sim* and his "Exploring How Computers Work" video series.

---
