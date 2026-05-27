# Project: Hawaa — Navi Mumbai Auto-Rickshaw RL Game
# Engine: Godot 4.x | Language: GDScript | Renderer: Forward+

## Build & Run
- Open project in Godot 4 editor and press F5 to run
- Scene entry point: res://scenes/main_3d.tscn
- No external build step required

## Project Structure
res://
├── scenes/          # .tscn files — one per major system
│   ├── main_3d.tscn       # 3D main scene (entry point)
│   ├── auto_3d.tscn       # 3D auto-rickshaw vehicle
│   ├── npc_3d.tscn        # 3D NPC character
│   └── passenger_card.tscn # HUD card (2D overlay)
├── scripts/         # .gd files — one per scene or component
│   ├── globals.gd         # Autoload constants (2D + 3D)
│   ├── main_3d.gd         # Main orchestrator
│   ├── world_3d.gd        # Procedural 3D world generator
│   ├── auto_3d.gd         # 3D vehicle controller
│   ├── npc_3d.gd          # 3D NPC logic
│   ├── minimap.gd         # Minimap (2D overlay, reads 3D pos)
│   └── passenger_card.gd  # Passenger card UI
├── 2d_backup/       # Original 2D files (archived)
├── assets/
│   ├── sprites/     # PNG spritesheets (legacy)
│   ├── tilemaps/    # TileSet resources (legacy)
│   └── audio/       # .ogg files only
├── rl/              # Python RL training scripts (standalone)
└── CLAUDE.md

## Coding Rules
- GDScript only, no C# or GDNative
- One script per scene node — no monolithic scripts
- Signal-based communication between nodes, no direct node refs across scenes
- All constants in a single autoload: res://scripts/globals.gd
- Never hardcode pixel positions — use Constants or exported vars

## Art Style
- 3D third-person, atmospheric night scene
- Procedural geometry using MeshInstance3D and CSG nodes
- No external 3D models — everything built in code
- Color palette: warm street lamps, dark roads, red/orange foliage
- Auto-rickshaw: yellow body, black canopy, glowing lights

## Key Systems (implement in this order)
1. Auto movement + chase camera (3D)
2. Procedural 3D world (roads, buildings, trees, lamps)
3. NPC spawning + proximity detection (3D)
4. Passenger card UI (bottom-left, 2D overlay)
5. Route highlight + destination pin
6. RL agent (pathfinding → Q-learning)
7. Rating/fare system
8. Polish (audio, day-night, title screen)

## RL Specifics
- Agent controls: UP/DOWN/LEFT/RIGHT on road graph nodes
- Reward: +10 reach destination, -1 per second taken, -5 collision
- State: current node, destination node, distance
- Algorithm: Q-learning first, upgrade to DQN if needed
- Training runs headless in rl/ folder via Python + numpy only

## DO NOT
- Use NavigationAgent3D for the RL agent (defeats the purpose)
- Add features outside the 8 systems above without asking
- Use placeholder art beyond week 2
- Import external .glb/.obj models — keep everything procedural