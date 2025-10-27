# Signal Relay

A digital logic circuit simulator built in Godot for exploring computer architecture fundamentals through interactive circuit design and hierarchical abstraction.

**Current Status:** Early Development - Phase 3

---

## Overview

Signal Relay is an educational logic simulator that enables users to build digital circuits from fundamental logic gates and progressively abstract them into custom components. Starting with basic gates, users can construct increasingly complex systems—from simple logic to arithmetic circuits, and potentially even simple processors.

The project emphasizes incremental learning through hands-on experimentation, allowing users to understand how computers work from first principles by building up layers of abstraction.

---

## Key Features (Planned)

### Core Functionality
- **Interactive Circuit Design**: Place and connect logic gates on an infinite canvas
- **Signal Simulation**: Real-time propagation of binary signals through circuit networks  
- **Custom Chip Abstraction**: Convert any circuit into a reusable custom component
- **Hierarchical Design**: Nest custom chips within other chips for complex systems
- **Circuit Persistence**: Save and load circuit designs

### User Experience
- **Intuitive Gate Library**: Visual catalog of available gates and custom chips
- **Wire Routing**: Click-and-drag wire creation with automatic connection detection
- **Visual Feedback**: Color-coded signal states for debugging
- **Clean Interface**: Minimalist design focused on circuit clarity

---

## Tech Stack

| Technology | Purpose | Rationale |
|------------|---------|-----------|
| **Godot 4.x** | Game engine | Scene system, 2D rendering, cross-platform support |
| **GDScript** | Scripting language | Native Godot integration, type safety, fast iteration |
| **JSON** | Data serialization | Human-readable circuit format, easy debugging |

---

## Technical Highlights

### Architecture

**Object-Oriented Design**
- Base `Gate` class defines common interface (inputs, outputs, evaluation)
- Concrete gate classes (`AndGate`, `OrGate`, etc.) extend base with specific logic
- Clean separation between gate logic and visual representation

**Component-Based Structure**
- Modular scene files (`.tscn`) paired with logic scripts (`.gd`)
- Reusable UI components (input toggles, output displays)
- Scalable architecture supporting future custom chip system

### Current Implementation (Phase 1) ✅

- `Gate` base class with polymorphic `evaluate()` method
- `AndGate` implementation with correct truth table logic
- `InputToggle` component for manual gate control
- `OutputDisplay` component for visual signal feedback
- Type-safe development with comprehensive type hints

---

## Installation & Usage

### Prerequisites
- Godot 4.x or later
- Basic understanding of digital logic (AND, OR, NOT gates)

### Running the Project
```bash
# Clone the repository
git clone https://github.com/rbessin/Signal-Relay.git

# Open in Godot: File → Import → Select project.godot
# Run main scene: Press F5
```

---

## Project Structure

```
Signal-Relay/
├── scenes/                    # Godot scene files
│   ├── main.tscn             # Main circuit canvas
│   ├── ui/                   # UI components
│   └── gates/                # Gate visual templates
├── scripts/                   # GDScript files
│   ├── core/                 # Base classes (Gate, Pin, Wire, Circuit)
│   ├── gates/                # Gate implementations (and_gate.gd, or_gate.gd, etc.)
│   ├── simulation/           # Simulation engine
│   ├── persistence/          # Save/load functionality
│   └── ui/                   # UI interaction handlers
├── assets/                    # Visual assets (icons, sprites, fonts)
├── data/                      # User circuits and custom chips
└── project.godot             # Godot project configuration
```

---

## Development Roadmap

### ✅ Phase 1: Basic Gate Implementation (Current)
- [x] `Gate` base class architecture
- [x] `AndGate` with correct logic evaluation
- [x] `InputToggle` and `OutputDisplay` components
- [X] Complete gate library (NOT, OR, NAND, NOR, XOR, XNOR)

### Phase 2: Interactive Canvas
- [X] Gate placement and deletion tools
- [ ] Pan and zoom navigation
- [X] Multiple gate instances on canvas

### Phase 3: Wire Connection System
- [ ] Click-and-drag wire creation
- [ ] Signal propagation through wire network
- [ ] Topological sorting for evaluation order

### Phase 4: Circuit Persistence
- [ ] Save/load circuits to JSON
- [ ] File management UI

### Phase 5: Custom Chip Abstraction
- [ ] Define external interface (exposed pins)
- [ ] Save circuits as custom chip definitions
- [ ] Instantiate custom chips as gates
- [ ] Nested simulation (chips within chips)

### Phase 6: Polish & Advanced Features
- [ ] Undo/redo system
- [ ] Performance optimization
- [ ] Advanced components (displays, memory, clocks)

---

## Development Philosophy

**Incremental Development**: Each phase must be fully functional before progressing to the next.

**Separation of Concerns**: Logic scripts independent of visual scenes. Data structures separate from UI.

**Clean Architecture**: Base classes provide structure. Child classes implement specific behavior.

---

## Acknowledgments

Inspired by Sebastian Lague's *Digital Logic Sim* and "Exploring How Computers Work" video series.

---

**Current Focus**: Completing the basic gate library (NOT, OR, NAND, NOR, XOR, XNOR) before implementing canvas interaction and wire connections.
