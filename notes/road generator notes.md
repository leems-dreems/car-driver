# AStar3D pathfinding (Godot 4.4, Road Gen 0.7.0)

Notes on using AStar3D with Road Generator to plot a road route between two points, which may or may not be on-road. This route can be used for high-level navigation, and possibly for displaying on a map if then converted to 2D.

- On RoadManager ready, create an instance of the AStar3D class. Also create a Dictionary[int, RoadLane] where the keys are indices of AStar3D points, and the values are references to the RoadLanes that those points belong to.
- Loop over RoadLanes, and call AStar3D.add_point() at least 3 times for each lane - start position, end position and at least 1 point in-between
	- For curved roads, add astar points along the RoadLane's curve, at intervals
	- For straight roads, can probably get away with having just 1 midpoint and calling get_closest_position_in_segment() to get target destination
	- The weight_scale of these midpoints can be adjusted to account for road type, speed limit etc
	- When adding the start or end point of a lane, add the RoadLane to our endpoints dictionary, keyed to the index of the newly added point
- When all astar points have been added, loop over the endpoints dictionary to make connections. For each endpoint:
	- Filter endpoints to only include other endpoints within a small radius
	- If this is the start point of this lane, filter endpoints to only include points whose positions match the end of their lane's curve, and make a one-way connection from those points to this one

When Road Generator supports RoadLanes with multiple entries/exits, the connection part of this will be a lot simpler.


# Holistic Navigation Solution

- Add an "off-road" NavigationRegion3D, with collision mask set to the terrain layer. Use Terrain3D's "paint navigable areas" feature to ensure that the navmesh doesn't overlap any roads. This layer is only used by vehicles that are currently off-road, or by on-road vehicles that are nearing their off-road destination
- Add an "on-road" NavigationRegion3D on a second nav layer, with a navmesh that covers roads and nothing else.
- Add a "waypoints" NavigationRegion3D on a third nav layer. The navmesh's collision mask should match a "road_waypoint" layer. Place small waypoint "islands" along each RoadLane, in a similar way to how astar points are placed. Set these islands to use the "road_waypoint" collision layer, and connect these islands using NavLinks that have a very low travel_cost.


todo next: remove the max edge length from roads, keep making tweaks to get paths to be more sensible. After that, add lane-following logic.


# Ideas for the future

Find a way to integrate an AStar3D instance into the Godot Navigation system. Look through astar-related PRs first
