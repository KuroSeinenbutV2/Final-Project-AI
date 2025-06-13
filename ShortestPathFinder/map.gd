extends Node2D

# Aset peta Jawa Timur
var map_texture = preload("res://jawa-timur-indonesia-map-grey-vector-23600012-removebg-preview.png")

# Dimensi dan posisi peta
var map_center_x = 400
var map_center_y = 300
var map_background_scale = 3.5  # Skala khusus untuk background peta yang diperbesar
var map_calculation_scale = 1.0  # Skala untuk perhitungan posisi node kota
var map_original_width = 1000
var map_original_height = 750

# Offset pengaturan untuk presisi posisi node kota (kanan, kiri, atas, bawah)
var node_offset_x = -350 # Geser ke kanan (positif) atau kiri (negatif)
var node_offset_y = 0  # Geser ke bawah (positif) atau atas (negatif)

# Data kota-kota Jawa Timur dengan nama dan posisi
var city_names = {
	1: "Surabaya", 2: "Gresik", 3: "Sidoarjo", 4: "Mojokerto", 5: "Jombang",
	6: "Bojonegoro", 7: "Lamongan", 8: "Tuban", 9: "Madiun", 10: "Ngawi",
	11: "Magetan", 12: "Ponorogo", 13: "Pacitan", 14: "Kediri", 15: "Nganjuk",
	16: "Tulungagung", 17: "Blitar", 18: "Trenggalek", 19: "Malang", 20: "Pasuruan",
	21: "Probolinggo", 22: "Lumajang", 23: "Bondowoso", 24: "Situbondo", 25: "Jember",
	26: "Banyuwangi"
}

# Koordinat geografis asli Jawa Timur (latitude, longitude)
var real_coordinates = {
	1: [-7.2575, 112.7521],   # Surabaya
	2: [-7.1560, 112.6536],   # Gresik  
	3: [-7.4478, 112.7183],   # Sidoarjo
	4: [-7.4664, 112.4338],   # Mojokerto
	5: [-7.5463, 112.2328],   # Jombang
	6: [-7.1502, 111.8817],   # Bojonegoro
	7: [-7.1167, 112.4167],   # Lamongan
	8: [-6.8972, 111.9722],   # Tuban
	9: [-7.6298, 111.5239],   # Madiun
	10: [-7.4040, 111.4462],  # Ngawi
	11: [-7.6472, 111.3500],  # Magetan
	12: [-7.8697, 111.4613],  # Ponorogo
	13: [-8.2067, 111.0889],  # Pacitan
	14: [-7.8167, 112.0167],  # Kediri
	15: [-7.6050, 111.9044],  # Nganjuk
	16: [-8.0667, 111.9000],  # Tulungagung
	17: [-8.0983, 112.1678],  # Blitar
	18: [-8.0500, 111.7167],  # Trenggalek
	19: [-7.9667, 112.6333],  # Malang
	20: [-7.6453, 112.9075],  # Pasuruan
	21: [-7.7542, 113.2167],  # Probolinggo
	22: [-8.1347, 113.2228],  # Lumajang
	23: [-7.9139, 113.8222],  # Bondowoso
	24: [-7.7069, 114.0094],  # Situbondo
	25: [-8.1667, 113.7000],  # Jember
	26: [-8.2192, 114.3691]   # Banyuwangi
}

# Posisi kota di layar (akan dikalkulasi dari koordinat asli)
var cities = {}

# Data koneksi antar kota dengan jarak real (km)
var edges = [
	[1, 2, 18], [1, 3, 23],
	[2, 3, 41], [2, 4, 67], [2, 7, 27],
	[3, 4, 72], [3, 20, 37],
	[4, 5, 30], [4, 7, 57], [4, 19, 89], [4, 20, 61],
	[5, 6, 85], [5, 7, 80], [5, 14, 44], [5, 15, 75], [5, 19, 119],
	[6, 7, 63], [6, 8, 65], [6, 9, 110], [6, 10, 78], [6, 15, 125],
	[7, 8, 58],
	[9, 10, 32], [9, 11, 34], [9, 12, 29], [9, 15, 50],
	[10, 11, 34],
	[11, 12, 53],
	[12, 13, 78], [12, 15, 79], [12, 16, 84], [12, 18, 52],
	[13, 18, 117],
	[14, 15, 28], [14, 16, 31], [14, 17, 44], [14, 19, 100],
	[15, 16, 59],
	[16, 17, 33], [16, 18, 32],
	[17, 19, 78],
	[19, 20, 55], [19, 21, 94], [19, 22, 119],
	[20, 21, 39],
	[21, 22, 46], [21, 23, 92], [21, 24, 95], [21, 25, 96],
	[22, 25, 172],
	[23, 24, 35], [23, 25, 32], [23, 26, 126],
	[24, 26, 94],
	[25, 26, 105]
]

# Variabel untuk status simulasi
var selected_start_city = -1
var selected_end_city = -1
var current_path = []
var multi_goals = []
var passenger_destinations = []

enum SimulationMode { SINGLE_ROUTE, MULTI_DESTINATION }
var simulation_mode = SimulationMode.SINGLE_ROUTE

# Camera/Zoom control variables from game.gd
var camera_position = Vector2.ZERO
var zoom_level = 1.0

# Car rendering variables
var car_texture = null
var car_position = Vector2.ZERO
var car_rotation = 0.0

var map_sprite: Sprite2D

func _ready():
	setup_map()
	convert_real_coordinates_to_screen()
	setup_city_nodes()

func setup_map():
	"""Setup peta dengan tekstur dan posisi yang sesuai"""
	map_sprite = Sprite2D.new()
	map_sprite.texture = map_texture
	map_sprite.position = Vector2(map_center_x, map_center_y)
	map_sprite.scale = Vector2(map_background_scale, map_background_scale)
	map_sprite.z_index = -1  # Pastikan peta berada di bawah node kota
	add_child(map_sprite)
	print("✅ Map setup complete")

func convert_real_coordinates_to_screen():
	"""Convert koordinat geografis asli ke koordinat layar dengan alignment ke map image"""
	# Find bounding box dari semua koordinat
	var min_lat = INF
	var max_lat = -INF
	var min_lon = INF
	var max_lon = -INF
	
	for coord in real_coordinates.values():
		var lat = coord[0]
		var lon = coord[1]
		min_lat = min(min_lat, lat)
		max_lat = max(max_lat, lat)
		min_lon = min(min_lon, lon)
		max_lon = max(max_lon, lon)
	
	# Map image settings - disesuaikan dengan posisi map background
	var map_width = map_original_width * map_calculation_scale
	var map_height = map_original_height * map_calculation_scale
	
	# Offset untuk positioning - map background positioned di center jadi kita perlu offset
	var map_offset_x = map_center_x - (map_width / 2)
	var map_offset_y = map_center_y - (map_height / 2)
	
	var lat_range = max_lat - min_lat
	var lon_range = max_lon - min_lon
	
	# Convert setiap koordinat kota dengan margin untuk better fit
	var margin_factor = 0.85  # Reduce sedikit untuk margin
	
	for city_id in real_coordinates.keys():
		var coord = real_coordinates[city_id]
		var lat = coord[0]
		var lon = coord[1]
		
		# Normalize koordinat (0-1 range)
		var norm_x = (lon - min_lon) / lon_range
		var norm_y = (max_lat - lat) / lat_range  # Flip Y karena layar Y increasing downward
		
		# Scale ke ukuran map dengan margin dan offset adjustment
		var screen_x = map_offset_x + (norm_x * map_width * margin_factor) + (map_width * (1 - margin_factor) / 2) + 20 + node_offset_x
		var screen_y = map_offset_y + (norm_y * map_height * margin_factor) + (map_height * (1 - margin_factor) / 2) + 10 + node_offset_y
		
		cities[city_id] = Vector2(screen_x, screen_y)
	
	print("✅ Converted ", cities.size(), " cities to align with map image")
	print("📍 Map bounds - Offset: (", map_offset_x, ", ", map_offset_y, "), Size: ", map_width, "x", map_height)
	print("📍 Coordinate ranges - Lat: ", min_lat, " to ", max_lat, ", Lon: ", min_lon, " to ", max_lon)
	
	# Debug: Print beberapa kota untuk verifikasi
	print("🏙️ Sample city positions:")
	print("   Surabaya: ", cities[1])
	print("   Malang: ", cities[19])
	print("   Banyuwangi: ", cities[26])

func setup_city_nodes():
	"""Setup node untuk setiap kota sebagai anak dari node peta"""
	for id in cities.keys():
		var city_node = Node2D.new()
		city_node.name = "City_" + str(id)
		city_node.position = cities[id]
		city_node.z_index = 1  # Pastikan node kota berada di atas peta
		add_child(city_node)
		print("Added city node: ", city_names[id], " at ", cities[id])

func get_map_bounds():
	"""Mengembalikan batas peta untuk sinkronisasi koordinat"""
	var map_width = map_original_width * map_background_scale
	var map_height = map_original_height * map_background_scale
	var map_offset_x = map_center_x - (map_width / 2)
	var map_offset_y = map_center_y - (map_height / 2)
	return {
		"offset_x": map_offset_x,
		"offset_y": map_offset_y,
		"width": map_width,
		"height": map_height
	}

func _draw():
	# Apply camera transformation
	var transform_matrix = Transform2D()
	transform_matrix = transform_matrix.scaled(Vector2(zoom_level, zoom_level))
	transform_matrix.origin = camera_position
	
	# Set transform untuk semua drawing
	draw_set_transform_matrix(transform_matrix)
	
	# Gambar koneksi antar kota
	for edge in edges:
		var from_pos = cities[edge[0]]
		var to_pos = cities[edge[1]]
		draw_line(from_pos, to_pos, Color.LIGHT_GRAY, 1)
		# Gambar jarak hanya untuk edge yang tidak terlalu panjang
		var mid_pos = (from_pos + to_pos) / 2
		if from_pos.distance_to(to_pos) < 100:
			draw_string(ThemeDB.fallback_font, mid_pos, str(edge[2]), HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color.GRAY)
	
	# Gambar rute yang dipilih
	if current_path.size() > 1:
		var line_color = Color.RED if simulation_mode == SimulationMode.SINGLE_ROUTE else Color.BLUE
		var line_width = 4 if simulation_mode == SimulationMode.SINGLE_ROUTE else 3
		
		for i in range(current_path.size() - 1):
			var from_pos = cities[current_path[i]]
			var to_pos = cities[current_path[i + 1]]
			draw_line(from_pos, to_pos, line_color, line_width)
			
			# Gambar panah arah
			var direction = (to_pos - from_pos).normalized()
			var arrow_pos = from_pos + direction * from_pos.distance_to(to_pos) * 0.7
			var arrow_size = 8
			var arrow_angle = direction.angle()
			
			# Draw arrow head
			var arrow_p1 = arrow_pos + Vector2(cos(arrow_angle - 2.8), sin(arrow_angle - 2.8)) * arrow_size
			var arrow_p2 = arrow_pos + Vector2(cos(arrow_angle + 2.8), sin(arrow_angle + 2.8)) * arrow_size
			draw_line(arrow_pos, arrow_p1, line_color, 2)
			draw_line(arrow_pos, arrow_p2, line_color, 2)
	
	# Gambar kota-kota
	for id in cities.keys():
		var pos = cities[id]
		var color = Color.BLUE
		var radius = 12
		
		# Highlight untuk Single Route mode
		if simulation_mode == SimulationMode.SINGLE_ROUTE:
			if id == selected_start_city:
				color = Color.GREEN
				radius = 15
			elif id == selected_end_city:
				color = Color.RED
				radius = 15
			elif id in multi_goals:
				color = Color.ORANGE
				radius = 13
		
		# Highlight untuk Multi-Destination mode
		elif simulation_mode == SimulationMode.MULTI_DESTINATION:
			if id == 1:  # Surabaya (start point)
				color = Color.GREEN
				radius = 15
			elif id in passenger_destinations:
				color = Color.ORANGE
				radius = 13
		
		# Draw city circle
		draw_circle(pos, radius, color)
		draw_circle(pos, radius, Color.WHITE, false, 2)
		
		# Draw city name
		var text_pos = pos + Vector2(-25, -25)
		draw_string(ThemeDB.fallback_font, text_pos, city_names[id], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.BLACK)
		
		# Draw city ID
		draw_string(ThemeDB.fallback_font, pos + Vector2(-4, 4), str(id), HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color.WHITE)
	
	# Gambar mobil/bus di atas semua elemen (terakhir agar paling atas)
	if car_texture:
		var car_scale = Vector2(0.1, 0.1)
		var car_transform = Transform2D()
		car_transform = car_transform.rotated(car_rotation)
		car_transform = car_transform.scaled(car_scale)
		car_transform.origin = car_position
		draw_set_transform_matrix(transform_matrix * car_transform)
		draw_texture(car_texture, Vector2(-car_texture.get_width()/2, -car_texture.get_height()/2))
	
	# Reset transform setelah menggambar
	draw_set_transform_matrix(Transform2D())

func update_simulation_state(start_city, end_city, path, mode, goals, destinations):
	"""Update status simulasi untuk rendering"""
	selected_start_city = start_city
	selected_end_city = end_city
	current_path = path
	simulation_mode = mode
	multi_goals = goals
	passenger_destinations = destinations
	queue_redraw()

@warning_ignore("shadowed_variable_base_class")
func update_camera_transform(position, zoom):
	"""Update camera transformation values"""
	camera_position = position
	zoom_level = zoom
	# Update position and scale of map sprite and city nodes
	if map_sprite:
		map_sprite.position = Vector2(map_center_x, map_center_y) * zoom + position
		map_sprite.scale = Vector2(map_background_scale, map_background_scale) * zoom
	for id in cities.keys():
		var city_node = get_node_or_null("City_" + str(id))
		if city_node:
			city_node.position = cities[id] * zoom + position
	queue_redraw()

@warning_ignore("shadowed_variable_base_class")
func update_car_rendering(texture, position, rotation):
	"""Update data mobil untuk rendering"""
	car_texture = texture
	car_position = position
	car_rotation = rotation
	queue_redraw() 
