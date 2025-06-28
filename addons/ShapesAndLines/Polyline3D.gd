@tool

class_name Polyline3D
extends MeshInstance3D

@export_range(0.0, 100.0) var width: float = 3.0:
	set(value):
		width = value
		regenerateMesh();

@export var color: Color:
	set(value):
		color = value
		regenerateMesh()

@export var points: PackedVector3Array = [Vector3(0, 0, 0), Vector3(20, 20, 20)]:
	set(value):
		points = value
		regenerateMesh()

@export var debug: bool = false:
	set(value):
		debug = value
		regenerateMesh()

func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	mesh = ArrayMesh.new()
	regenerateMesh()

func regenerateMesh() -> void:
	#if not Engine.is_editor_hint():
		#return

	var numPoints := points.size()
	if numPoints <= 1:
		return

	# First, populate the vertices
	var vertices: PackedVector3Array = []
	vertices.resize((numPoints-1) * 4)
	for i in numPoints-1:
		vertices[i*4] = points[i]
		vertices[i*4 + 1] = points[i] + Vector3(0.001,0.001,0.001)
		vertices[i*4 + 2] = points[i+1]
		vertices[i*4 + 3] = points[i+1] + Vector3(0.001,0.001,0.001)

	# Populate the colors
	var colors: PackedColorArray = []
	colors.resize((numPoints-1) * 4);
	for i in numPoints-1:
		colors[i*4] = color
		colors[i*4 + 1] = color
		colors[i*4 + 2] = color
		colors[i*4 + 3] = color

	# Populate the normals
	var normals: PackedVector3Array = []
	normals.resize((numPoints-1) * 4)
	for i in numPoints-1:
		normals[i*4] = points[i+1] - points[i]
		normals[i*4 + 1] = points[i+1] - points[i]
		normals[i*4 + 2] = normals[i*4]
		normals[i*4 + 3] = normals[i*4 + 1]

	# Populate the UVs
	var uvs: PackedVector2Array = []
	uvs.resize((numPoints-1) * 4)
	for i in numPoints-1:
		uvs[i*4] = Vector2(0, 1)
		uvs[i*4 + 1] = Vector2(1, 1)
		uvs[i*4 + 2] = Vector2(0, 0)
		uvs[i*4 + 3] = Vector2(1, 0)

	# Populate the indices
	var indices: PackedInt32Array = []
	indices.resize((numPoints-1) * 6 + (numPoints-2)*6)
	for i in (numPoints - 1) + (numPoints - 2):
		var startIndex := i * 6

		indices[startIndex] = i*2
		indices[startIndex + 1] = i*2 + 1
		indices[startIndex + 2] = i*2 + 2

		indices[startIndex + 3] = i*2 + 2
		indices[startIndex + 4] = i*2 + 1
		indices[startIndex + 5] = i*2 + 3

	# Allow for mesh to be updated without fully regenerating each time
	if not is_instance_valid(mesh):
		mesh = ArrayMesh.new()

	# Generate the new surface
	var newSurfaceArray: Array = []
	newSurfaceArray.resize(Mesh.ARRAY_MAX)
	newSurfaceArray[Mesh.ARRAY_VERTEX] = vertices
	newSurfaceArray[Mesh.ARRAY_NORMAL] = normals
	newSurfaceArray[Mesh.ARRAY_TEX_UV] = uvs
	newSurfaceArray[Mesh.ARRAY_INDEX] = indices
	newSurfaceArray[Mesh.ARRAY_COLOR] = colors

	var material: Material = preload("res://addons/ShapesAndLines/Polyline3DMaterial.tres").duplicate(true)
	material.set_shader_parameter("width", width)
	material.set_shader_parameter("debug", debug)
	var arrayMesh := mesh as ArrayMesh
	arrayMesh.clear_surfaces()
	arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, newSurfaceArray)
	self.material_override = material;
