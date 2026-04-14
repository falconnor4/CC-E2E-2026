# Ender Modem Mesh

Status monitoring mesh for CC:Tweaked using ender modems.

## Programs

- `mesh/node.lua`: runs on each node, reports status.
- `mesh/hub.lua`: central monitor that receives and displays node status.

## Setup

1. Place an ender modem on each computer (node and hub).
2. Run `mesh/node.lua` on every node.
3. Run `mesh/hub.lua` on the hub computer (optionally with a monitor).

Edit the `MESH_CHANNEL` and node `NODE_ID` inside the scripts if desired.
