# Questions

- How best to look for points on adjacent lanes, e.g. to link astar points and allow pathfinding to consider lane-switching?
- Possibly merge lanes on multi-lane roads for astar purposes - e.g. an 8-lane highway would be treated as a 2-lane road for pathfinding
- How to consider all lanes on a road when choosing start & end points of astar path? Currently just searching for points in a 10m radius of closest point
- How best to link next & prior lanes, including at intersections?


# AStar3D pathfinding (Godot 4.4, Road Gen 0.7.0)

Notes on using AStar3D with Road Generator to plot a road route between two points, which may or may not be on-road. This route can be used for high-level navigation, and possibly for displaying on a map if then converted to 2D.

- On RoadManager ready, create an instance of the AStar3D class. Also create a Dictionary[int, RoadLane] where the keys are indices of AStar3D points, and the values are references to the RoadLanes that those points belong to.
- Loop over RoadLanes, and call AStar3D.add_point() at least 3 times for each lane - start position, end position and at least 1 point in-between
	- For curved roads, add astar points along the RoadLane's curve, at intervals
	- For straight roads, can probably get away with having just 1 midpoint and calling get_closest_position_in_segment() to get target destination
	- The weight_scale of these midpoints can be adjusted to account for road type, speed limit etc
	- When adding the start or end point of a lane, add the RoadLane to our endpoints dictionary, keyed to the index of the newly added point
- When all astar points have been added, loop over the endpoints dictionary to make **connections**. For each endpoint:
	- Filter endpoints to only include other endpoints within a small radius
	- If this is the start point of this lane, filter endpoints to only include points whose positions match the end of their lane's curve, and make a one-way connection from those points to this one

When Road Generator supports RoadLanes with multiple entries/exits, the connection part of this will be a lot simpler.


# NavMesh pathfinding

- Add an "off-road" NavigationRegion3D, with collision mask set to the terrain layer. Use Terrain3D's "paint navigable areas" feature to ensure that the navmesh doesn't overlap any roads. This layer is only used by vehicles that are currently off-road, or by on-road vehicles that are nearing their off-road destination
- Add an "on-road" NavigationRegion3D on a second nav layer, with a navmesh that covers roads and nothing else.
- Add a "waypoints" NavigationRegion3D on a third nav layer. The navmesh's collision mask should match a "road_waypoint" layer. Place small waypoint "islands" along each RoadLane, in a similar way to how astar points are placed. Set these islands to use the "road_waypoint" collision layer, and connect these islands using NavLinks that have a very low travel_cost.

## Ideas for the future

- Find a way to integrate an AStar3D instance into the Godot Navigation system. Look through astar-related PRs first
- Work out how to align the edges of terrain & road navmeshes, to remove the need for edge connections


# AStar + NavMesh Solution

Build an AStar3D graph from RoadLanes in the scene, as described above. Bake a navmesh over the terrain.

When a vehicle's target position is set, get the nearest astar points to both the vehicle and the target position. Calculate a path between these points.
Next, get all astar points within X metres of the start point. Calculate paths from each of these potential alternate start points to our initial end point. Keep the path with the lowest cost.
Go through this process again to find alternate end points. It may even be worth taking another look for alternate start points after this.

Using the vehicle's nav agent, get a navmesh path to our chosen astar start point. Start navigating towards it.
Possible improvement: periodically sample other potential start points while navigating, and use some heuristic that looks at the combined on & off-road path costs to decide whether to use that start point instead.
When the nav agent is within a certain range of its chosen astar start point, switch to lane-following behaviour.
When the nav agent is nearing its chosen end point, start sampling points on the lane(s) ahead and calculate the path from each to the vehicle's target position.
After storing a number of possible paths, get the one with the lowest cost and store its first path position as our exit point.
When the vehicle's position on the lane's curve is as close to our exit point as it'll get, turn off lane-following and navigate over the navmesh to the target position.
