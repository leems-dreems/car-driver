- Creating RoadLane nodes inside RoadParent nodes will automatically create the correct curve, but the RoadLane nodes seem to disappear after selecting "Refresh roads" from the dropdown
- Automatically generated AI lanes work pretty well, but don't have an easy way to connect to lanes on intersections

# Notes on a NavigationServer3D based approach to Road Generator agent navigation

- Each RoadContainer is its own NavigationRegion, including intersections
- Generate low-resolution NavigationMesh for each region
- Connect entrance and exit of each RoadLane with a NavigationLink (?)
- Add configurable navigation layers for each RoadContainer, so that navigation queries can avoid certain types of road