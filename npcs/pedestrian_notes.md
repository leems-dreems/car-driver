# Pedestrian system

- Each PedestrianArea is a NavigationRegion3D with a NavigationMesh
- The mesh's `geometry_parsed_geometry_type` is set to **Static Colliders**
- The mesh's `geometry_source_geometry_mode` is set to **Group With Children**
- The PedestrianArea generates a unique group name on ready, and assigns itself to it
- Vehicles, physics props, and other moving objects that affect navmeshes are added to & removed from this unique group when they enter/exit the PedestrianArea's collider
- A spherical Area3D, attached to the camera, toggles the `enabled` bool on PedestrianAreas it enters/exits
