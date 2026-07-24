# The Drawdown Protocol

A playable Godot 4 prototype for a 2D isometric rogue-lite climate-transition simulation.

## Game Concept

### Elevator Pitch

You are an AI simulation tasked by future humanity to find the optimal path through the 21st-century climate crisis. In a vibrant 2D isometric world, you manage a procedurally generated bioregion and guide society toward carbon neutrality and ecological balance before catastrophic tipping points are breached. When a run fails, you use the data gathered to unlock new socio-economic paradigms and technologies for the next simulation.

### Core Gameplay Loop (Rogue-like Structure)

- **The Run (A Century):** One run spans 2030 to 2100 on an isometric grid representing a biome such as a Coastal Metropolis, Arid Agricultural Hub, or Temperate Valley.
- **The Threats ("Enemies"):** Instead of monsters, the player confronts feedback loops (Permafrost Melt, Albedo Loss) and extreme events (mega-droughts, category 5 cyclones, heatwaves).
- **The Defeat State:** A run ends if regional resilience drops to 0 or if warming contribution reaches +2.0 C.
- **The Meta-Progression:** On game over, Insight Points are earned and spent in the Paradigm Hub to permanently improve future runs (Circular Economy, Universal Basic Services, Degrowth frameworks).

### Key Mechanics: Building a "Sober" World

1. **Sufficiency (Sobriety) Mechanic**  
   Early play can rely on green growth, but long-term survival requires demand reduction and sufficiency policies.
   - In-game action: convert high-traffic intersections into walkable 15-minute city tiles to reduce energy demand.
   - Scientific basis: IPCC AR6 emphasizes sufficiency as a core mitigation strategy that reduces demand for energy, materials, land, and water while maintaining wellbeing [1].

2. **Carbon Sinks vs. Emissions**  
   Every development choice impacts a carbon ledger balancing greenhouse gas emissions and sequestration.
   - In-game action: restore degraded tiles into peatlands or kelp forests that passively draw down carbon.
   - Scientific basis: Project Drawdown ranks peatland restoration and ocean ecosystem protection among high-impact climate solutions [2].

3. **Dietary Shifts and Land Use**  
   Agriculture consumes board space and drives emissions in different ways depending on food systems.
   - In-game action: enact a plant-rich diet shift to free large portions of agricultural tiles for rewilding and flood resilience.
   - Scientific basis: EAT-Lancet identifies plant-rich diets as essential for staying within planetary boundaries and reducing land pressure [3].

### Visuals and Aesthetics: The Beautiful Optimization

- **Early run / high-emission phase:** detailed but harsh visuals with grey concrete, gridlocked highways, industrial sprawl, and muted smoggy tones.
- **Optimized sober world:** transformed landscapes with green tram lines, bike paths, rooftop gardens, and brighter natural light.
- The target look is not "primitive"; it is advanced, lush, and harmonious (solarpunk direction).

### Scientific Foundation

| In-Game Mechanic | Real-World Concept | Scientific Source |
|---|---|---|
| Doom meter | Planetary boundaries | Stockholm Resilience Centre (Rockstrom et al.) [4] |
| Tech tree and upgrades | Climate solutions matrix | Project Drawdown [2] |
| Sobriety and demand reduction | Sufficiency and degrowth | IPCC AR6 WGIII, Chapter 5 [1] |
| Energy transition systems | Net zero by 2050 pathways | International Energy Agency (IEA) [5] |

## Gameplay Loop (Current Prototype)

- One run spans 2030 to 2100.
- Each year you pick one policy card, then advance the simulation.
- Extreme events and feedback loops trigger based on warming and resilience.
- You lose if resilience reaches zero or warming contribution reaches +2.0 C.
- On run end, you gain Insight Points for permanent meta upgrades in the Paradigm Hub.

## Controls

- Space: Advance year
- H: Open or close Paradigm Hub
- Mouse: Pick policy cards and unlock paradigms

## Sources

[1] IPCC AR6 WGIII, Chapter 5: demand-side mitigation and sufficiency (avoid-shift-improve).  
[2] Project Drawdown: ranked climate solutions and sequestration impact.  
[3] EAT-Lancet Commission: Food, Planet, Health and plant-rich dietary transition.  
[4] Stockholm Resilience Centre / Rockstrom et al.: planetary boundaries framework.  
[5] International Energy Agency (IEA): net-zero emissions by 2050 roadmaps.

## Run

Use your Godot binary:

/home/dnicolas/Lab/godot/bin/godot.linuxbsd.editor.dev.x86_64 --path /home/dnicolas/Lab/GodotProject --editor
