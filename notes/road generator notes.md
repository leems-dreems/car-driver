- Creating RoadLane nodes inside RoadParent nodes will automatically create the correct curve, but the RoadLane nodes seem to disappear after selecting "Refresh roads" from the dropdown
- Automatically generated AI lanes work pretty well, but don't have an easy way to connect to lanes on intersections

# AStar3D pathfinding (Godot 4.4, Road Gen 0.7.0)

Notes on using AStar3D with Road Generator to plot a road route between two points, which may or may not be on-road. This route can be used for high-level navigation, and possibly for displaying on a map if then converted to 2D.

- On RoadManager ready, create an instance of the AStar3D class. Also create a Dictionary[int, RoadLane] where the keys are indices of AStar3D points, and the values are references to the RoadLanes that those points belong to. Call this dictionary endpoints_dict
- Loop over RoadLanes, and call AStar3D.add_point() at least 3 times for each lane - start position, end position and at least 1 point in-between
	- When adding a start or end point of a lane, add the RoadLane to our endpoints_dict, keyed to the index of our newly added point
	- For curved roads, add astar points along the RoadLane's curve, at intervals
	- For straight roads, can probably get away with having just 1 midpoint and calling get_closest_position_in_segment() to get target destination
	- The weight_scale of these midpoints can be adjusted to account for road type, speed limit etc
- When all astar points have been added, loop over our endpoints_dict. For each point:
	- Filter our endpoints_dict to only include other points within a small radius
	- If this is the start point of this lane, filter the points to only include points whose positions match the end of their lane's curve, and make a one-way connection from those points to this one
	- If this is the end point of this lane, filter the points to only include points whose positions match the start of their lane's curve, and make a one-way connection to those points from this one