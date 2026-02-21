# Road Generator & AStar3D - AI traffic notes

Notes on how to get physics-driven NPC cars to follow astar paths through a Road Generator network.

## Structure & logic
- The scene decides when & where to spawn vehicles, which paths to assign them,
and when and how far forward each should move.
- The scene can spawn AStarRoadAgents directly, or spawn (to-be-named) physical vehicles which spawn
their own agents to use as lookahead boxes
- Vehicles can use a SteeringRaycaster node to do context-based-steering while navigating towards
a destination, or while following a lookahead box


## AStarTrafficManager
Has exported vars `road_manager` and `traffic_container`.
Has an onready var of a new AStar3D instance.
On ready, build an astar graph using RoadLanes in the scene.

## AStarRoadAgent
Follows RoadLanes along a given AStar3D path. Must be a direct child of an AStarTrafficManager.
Add a mesh as a child of this node for simple, non-physics lane-following.
Alternatively, use it as a lookahead box for a physics-driven car to follow.

The AStarRoadAgent holds a reference to its parent AStarTrafficManager node.
When given a new astar path to follow, the agent will find the RoadLane attached to the first point
on the astar path, then position itself on the lane's curve at that point.
When starting off-road, the agent should wait until the vehicle navigates to the first point, before
starting to move along the path.
When the agent hits the end of a path, it should indicate that in some way, possibly by emitting a
signal. This is so that the vehicle can switch to its off-road navigation behaviour.
The agent should also indicate when it has hit other obstacles such as red lights, and stop moving
until the obstacle is removed or disabled.

## Example scene tree
- Scene Root
	- RoadManager
	- Nav regions, Terrain3D etc
	- TrafficContainer (plain Node3D)
		- NPC Vehicles
			- AStarRoadAgent: queries AStarTrafficManager to get astar paths
			- SteeringRaycaster: Used by vehicle for steering & avoidance
	- AStarTrafficManager: holds references to RoadManager and TrafficContainer nodes
