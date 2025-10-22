Signal Relay
A digital logic circuit simulator built in Godot, designed to explore computer architecture fundamentals through interactive circuit design and hierarchical abstraction.
Current Status: Early Development - Phase 1 (Basic Gate Implementation)

Overview
Signal Relay is an educational logic simulator that enables users to build digital circuits from fundamental logic gates and progressively abstract them into custom components. Starting with basic NAND gates, users can construct increasingly complex systems—from simple logic gates to arithmetic circuits, and potentially even simple processors.
The project emphasizes incremental learning through hands-on experimentation, allowing users to understand how computers work from first principles by building up layers of abstraction, similar to Sebastian Lague's Digital Logic Sim.

Key Features
Core Functionality (Planned)

Interactive Circuit Design: Place and connect logic gates on an infinite canvas
Signal Simulation: Real-time propagation of binary signals through circuit networks
Custom Chip Abstraction: Convert any circuit into a reusable custom component
Hierarchical Design: Nest custom chips within other chips for complex systems
Circuit Persistence: Save and load circuit designs with full state preservation

User Experience (Planned)

Intuitive Gate Library: Visual catalog of available gates and custom chips
Wire Routing: Click-and-drag wire creation with automatic connection detection
Component Editing: Rename, configure, and organize custom chip libraries
Visual Feedback: Color-coded signal states (active/inactive) for debugging
Clean Interface: Minimalist design focused on circuit clarity

Educational Value

First Principles Learning: Build complex systems from fundamental components
Visual Understanding: See signal flow and logic evaluation in real-time
Incremental Complexity: Progress from basic gates to sophisticated circuits
Experimentation Sandbox: No specific goals—explore and create freely


Tech Stack
TechnologyPurposeRationaleGodot 4.xGame engineScene system for modular components, built-in 2D rendering, cross-platform supportGDScriptScripting languageNative Godot integration, type safety, fast iterationJSONData serializationHuman-readable circuit save format, easy debugging and version controlGit/GitHubVersion controlTrack development progress, maintain project history

Technical Highlights
Architecture
Object-Oriented Design

Base Gate class defines common interface (inputs, outputs, evaluation)
Concrete gate classes (AndGate, OrGate, etc.) extend base with specific logic
Clean separation between gate logic and visual representation

Component-Based Structure

Modular scene files (.tscn) paired with logic scripts (.gd)
Reusable UI components (input toggles, output displays)
Scalable architecture supporting future custom chip system

Simulation Engine (Planned)

Topological sorting for evaluation order (avoid circular dependencies)
Event-driven signal propagation for performance
Nested simulation for custom chips within chips

Current Implementation
Phase 1: Proof of Concept ✅

Gate base class with polymorphic evaluate() method
AndGate implementation with correct truth table logic
InputToggle component for manual gate control
OutputDisplay component for visual signal feedback
Signal flow: Input → Gate → Evaluation → Output

Type-Safe Development

Comprehensive type hints on methods and properties
@export decorators for inspector-editable properties
Strong typing prevents runtime errors during development


Installation & Usage
Prerequisites

Godot 4.x or later
Basic understanding of digital logic (AND, OR, NOT gates)

Running the Project
bash# Clone the repository
git clone https://github.com/YOUR_USERNAME/Signal-Relay.git

# Open in Godot
# File → Import → Select project.godot

# Run main scene
# Press F5 or click Run button
Development
bash# Project follows Godot conventions
# - Scripts use snake_case naming
# - Classes use PascalCase (class_name Gate)
# - Scenes paired with scripts of same name
```

---

## Project Structure
```
Signal-Relay/
├── .godot/                          # Godot engine cache (not tracked)
├── assets/                          # Visual and audio assets
│   ├── icons/                       # Gate library and tool icons
│   ├── sprites/                     # Visual assets for gates
│   └── fonts/                       # Custom typography
│
├── data/                            # User-created content
│   ├── circuits/                    # Saved circuit files (.json)
│   └── chip_library/                # Custom chip definitions (.json)
│
├── scenes/                          # Godot scene files
│   ├── main.tscn                    # Main circuit canvas
│   ├── ui/                          # User interface components
│   │   ├── toolbar.tscn
│   │   ├── gate_library.tscn
│   │   ├── properties_panel.tscn
│   │   ├── input_toggle.tscn
│   │   └── output_display.tscn
│   ├── gates/                       # Gate visual templates
│   │   ├── base_gate.tscn
│   │   ├── and_gate.tscn
│   │   ├── or_gate.tscn
│   │   └── not_gate.tscn
│   └── components/                  # Reusable scene components
│       ├── pin.tscn
│       └── wire.tscn
│
├── scripts/                         # GDScript files
│   ├── main.gd                      # Main scene controller
│   ├── core/                        # Core data structures
│   │   ├── gate.gd                  # Base Gate class
│   │   ├── pin.gd                   # Pin data/logic
│   │   ├── wire.gd                  # Wire connection logic
│   │   └── circuit.gd               # Circuit manager
│   ├── gates/                       # Concrete gate implementations
│   │   ├── and_gate.gd
│   │   ├── or_gate.gd
│   │   ├── not_gate.gd
│   │   ├── nand_gate.gd
│   │   ├── nor_gate.gd
│   │   └── xor_gate.gd
│   ├── simulation/                  # Simulation engine
│   │   ├── simulator.gd
│   │   └── signal_propagator.gd
│   ├── persistence/                 # File I/O
│   │   ├── circuit_saver.gd
│   │   └── chip_library.gd
│   └── ui/                          # UI interaction handlers
│       ├── canvas_controller.gd
│       ├── gate_placer.gd
│       ├── wire_drawer.gd
│       ├── input_toggle.gd
│       └── output_display.gd
│
├── .gitattributes                   # Git attributes
├── .gitignore                       # Git ignore rules
├── icon.svg                         # Project icon
├── project.godot                    # Godot project configuration
└── README.md                        # This file

Development Roadmap
✅ Phase 1: Basic Gate Implementation (Current)

 Gate base class architecture
 AndGate with correct logic evaluation
 InputToggle component for manual control
 OutputDisplay component for visual feedback
 Complete gate library (NOT, OR, NAND, NOR, XOR, XNOR)

Phase 2: Interactive Canvas

 Gate placement system (click to place from library)
 Selection and deletion tools
 Pan and zoom navigation
 Multiple gate instances on canvas

Phase 3: Wire Connection System

 Wire class for gate interconnection
 Click-and-drag wire creation
 Pin class for connection points
 Signal propagation through wire network
 Topological sorting for evaluation order

Phase 4: Circuit Persistence

 Save circuit to JSON format
 Load circuit from file
 File management UI
 Export/import functionality

Phase 5: Custom Chip Abstraction

 Define external interface (exposed pins)
 Save circuit as custom chip definition
 Custom chip library management
 Instantiate custom chips as gates
 Nested simulation (chips within chips)

Phase 6: Polish & Advanced Features

 Undo/redo system
 Circuit validation and error detection
 Performance optimization for large circuits
 Advanced components (displays, memory, clocks)
 Tutorial system for new users


Development Process
This project is being developed as a learning exercise to explore:

Computer architecture fundamentals (logic gates, circuit design, abstraction layers)
Object-oriented design patterns (inheritance, polymorphism, composition)
Game engine architecture (scene systems, node hierarchies, signals)
Simulation algorithms (topological sorting, signal propagation, state management)
Incremental development practices (working milestones, iterative refinement)

Design Philosophy
Incremental Development: Each phase must be fully functional before progressing to the next. Avoid building abstraction before establishing core functionality.
Separation of Concerns: Logic scripts remain independent of visual scenes. Data structures separate from UI. Simulation engine decoupled from rendering.
Clean Architecture: Base classes provide structure and common interfaces. Child classes implement specific behavior. Reusable components promote maintainability.

Acknowledgments
Inspired by Sebastian Lague's Digital Logic Sim and his "Exploring How Computers Work" video series, which demonstrates building computational systems from fundamental components.

Current Focus: Completing the basic gate library (NOT, OR, NAND, NOR, XOR) to establish a comprehensive set of building blocks before implementing canvas interaction and wire connections.RetryClaude can make mistakes. Please double-check responses.
