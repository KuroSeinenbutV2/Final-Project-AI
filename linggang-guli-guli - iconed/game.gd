extends Node2D

# Data kota-kota Jawa Timur dengan nama dan posisi
var city_names = {}

# Koordinat geografis asli Jawa Timur (latitude, longitude)
var real_coordinates = {}

# Posisi kota di layar (akan dikalkulasi dari koordinat asli)
var cities = {}

# Data koneksi antar kota dengan jarak real (km) - sama persis dengan Python
var edges = []

# Graph representation untuk A* custom implementation (mirip NetworkX)
var graph = {}
var path = []
var speed = 100
var selected_start_city = -1
var selected_end_city = -1
var current_path = []
var total_distance = 0
var car_rotation = 0.0  # Untuk orientasi mobil

# Textures untuk mobil dan bus
var car_texture = preload("res://pngtree-red-sports-car-top-view-png-image_6564079.png")
var bus_texture = preload("res://buuussssh.png")

# Camera/Zoom control variables
var camera_position = Vector2.ZERO
var zoom_level = 1.0
var min_zoom = 0.5
var max_zoom = 4.0
var zoom_speed = 0.15
var pan_speed = 5.0
var is_dragging = false
var last_mouse_position = Vector2.ZERO

# Mode simulation - bisa switch antara single route dan multi destination
enum SimulationMode { SINGLE_ROUTE, MULTI_DESTINATION }
var simulation_mode = SimulationMode.SINGLE_ROUTE
var passenger_destinations = []  # Untuk mode multi destination
var multi_goals = []  # Untuk menyimpan multi-goals dari UI

var map_node: Node2D

func _ready():
	map_node = preload("res://map.gd").new()
	add_child(map_node)
	city_names = map_node.city_names  # Ambil data nama kota dari map_node
	convert_real_coordinates_to_screen()
	setup_graph()
	setup_ui()
	# Hide car sprite karena kita akan draw manual di _draw()
	$Car.visible = false
	$Car.z_index = 10  # Set z-index tinggi agar mobil berada di atas semua elemen lainnya

func convert_real_coordinates_to_screen():
	"""Convert koordinat geografis asli ke koordinat layar dengan alignment ke map image"""
	# Data kota sudah ada di map.gd, kita hanya perlu mengambil posisi dari map_node
	cities = map_node.cities
	print("✅ Retrieved city positions from map node")

func setup_graph():
	"""Setup graph seperti NetworkX di Python"""
	# Initialize graph as adjacency list dengan weights
	for id in cities.keys():
		graph[id] = {}
	
	# Add edges dengan weights (jarak real)
	for edge in map_node.edges:
		var from_id = edge[0]
		var to_id = edge[1]
		var weight = edge[2]
		graph[from_id][to_id] = weight
		graph[to_id][from_id] = weight  # Undirected graph

func setup_ui():
	update_ui_status()
	setup_dropdowns()
	connect_ui_signals()

func setup_dropdowns():
	"""Setup dropdown options dengan nama kota"""
	var from_dropdown = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/FromDropdown
	var to_dropdown = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/ToDropdown
	var add_city_dropdown = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/AddCityDropdown
	
	# Clear existing options
	from_dropdown.clear()
	to_dropdown.clear()
	add_city_dropdown.clear()
	
	# Add "Pilih Kota" option
	from_dropdown.add_item("-- Pilih Kota Asal --", -1)
	to_dropdown.add_item("-- Pilih Kota Tujuan --", -1)
	add_city_dropdown.add_item("-- Pilih Kota untuk Ditambah --", -1)
	
	# Add all cities to dropdowns
	for id in city_names.keys():
		from_dropdown.add_item(city_names[id], id)
		to_dropdown.add_item(city_names[id], id)
		add_city_dropdown.add_item(city_names[id], id)

func connect_ui_signals():
	"""Connect UI button signals"""
	var find_button = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/FindRouteButton
	var reset_button = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/ResetButton
	var add_city_button = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/ButtonContainer/AddCityButton
	var clear_goals_button = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/ButtonContainer/ClearGoalsButton
	var about_button = $UI/AboutButton
	
	if not find_button.pressed.is_connected(_on_find_route_button_pressed):
		find_button.pressed.connect(_on_find_route_button_pressed)
	
	if not reset_button.pressed.is_connected(_on_reset_button_pressed):
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	if not add_city_button.pressed.is_connected(_on_add_city_button_pressed):
		add_city_button.pressed.connect(_on_add_city_button_pressed)
	
	if not clear_goals_button.pressed.is_connected(_on_clear_goals_button_pressed):
		clear_goals_button.pressed.connect(_on_clear_goals_button_pressed)
	
	if not about_button.pressed.is_connected(_on_about_button_pressed):
		about_button.pressed.connect(_on_about_button_pressed)

func _on_reset_button_pressed():
	"""Handler untuk tombol Reset"""
	reset_simulation()
	print("🔄 Reset simulation")
	update_ui_status()
	queue_redraw()

func _on_find_route_button_pressed():
	"""Handler untuk tombol Cari Rute"""
	var from_dropdown = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/FromDropdown
	var to_dropdown = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/ToDropdown
	
	# Pastikan dropdown sudah terinitialisasi
	if not from_dropdown or not to_dropdown:
		print("❌ UI elements tidak ditemukan!")
		update_ui_status_with_error("UI elements tidak ditemukan!")
		return
	
	var from_id = from_dropdown.get_selected_id()
	var to_id = to_dropdown.get_selected_id()
	
	# Validasi input lebih ketat
	if from_id == -1:
		print("❌ Pilih kota asal terlebih dahulu!")
		update_ui_status_with_error("Pilih kota asal terlebih dahulu!")
		return
	
	if to_id == -1:
		print("❌ Pilih kota tujuan terlebih dahulu!")
		update_ui_status_with_error("Pilih kota tujuan terlebih dahulu!")
		return
	
	if from_id == to_id:
		print("❌ Kota asal dan tujuan tidak boleh sama!")
		update_ui_status_with_error("Kota asal dan tujuan tidak boleh sama!")
		return
	
	# Validasi bahwa ID kota ada dalam data
	if not city_names.has(from_id):
		print("❌ Kota asal tidak valid!")
		update_ui_status_with_error("Kota asal tidak valid!")
		return
	
	if not city_names.has(to_id):
		print("❌ Kota tujuan tidak valid!")
		update_ui_status_with_error("Kota tujuan tidak valid!")
		return
	
	if not cities.has(from_id):
		print("❌ Posisi kota asal tidak ditemukan!")
		update_ui_status_with_error("Posisi kota asal tidak ditemukan!")
		return
	
	if not cities.has(to_id):
		print("❌ Posisi kota tujuan tidak ditemukan!")
		update_ui_status_with_error("Posisi kota tujuan tidak ditemukan!")
		return
	
	# Set selected cities
	selected_start_city = from_id
	selected_end_city = to_id
	print("🚩 Kota asal: ", city_names[selected_start_city])
	print("🎯 Kota tujuan: ", city_names[selected_end_city])
	
	# Jika ada multi_goals, gunakan multi-destination
	if multi_goals.size() > 0:
		var all_destinations = [selected_end_city] + multi_goals
		var optimized_route = find_multi_destination_route(selected_start_city, all_destinations)
		if optimized_route.size() == 0:
			print("❌ Tidak ada rute yang ditemukan untuk multi-destination!")
			update_ui_status_with_error("Tidak ada rute yang ditemukan untuk multi-destination!")
			return
		current_path = optimized_route
		total_distance = calculate_total_distance_from_path(optimized_route)
		# Convert to path points for car movement
		path = []
		for id in optimized_route:
			if cities.has(id):
				path.append(cities[id])
		print("🛣️ Rute Multi-Goals: ")
		for city_id in current_path:
			if city_names.has(city_id):
				print("   → ", city_names[city_id])
	else:
		# Cari rute terpendek menggunakan A* custom
		path = find_single_route(selected_start_city, selected_end_city)
		if current_path.size() == 0:
			print("❌ Tidak ada rute yang ditemukan!")
			update_ui_status_with_error("Tidak ada rute yang ditemukan antara kota tersebut!")
			return
		print("🛣️ Rute A* terpendek: ")
		for city_id in current_path:
			if city_names.has(city_id):
				print("   → ", city_names[city_id])
	
	print("📏 Total jarak: ", total_distance, " km")
	
	# Set car position ke kota asal dan mulai pergerakan
	if cities.has(selected_start_city):
		$Car.position = cities[selected_start_city]
		car_rotation = 0.0
		update_ui_status()
		queue_redraw()
	else:
		print("❌ Posisi kota asal tidak valid!")
		update_ui_status_with_error("Posisi kota asal tidak valid!")

func update_ui_status_with_error(error_msg):
	"""Update UI dengan pesan error"""
	if has_node("UI/InfoPanel/ScrollContainer/VBoxContainer/Instructions"):
		$UI/InfoPanel/ScrollContainer/VBoxContainer/Instructions.text = "[b]❌ Error:[/b] " + error_msg + "\n\n[b]Cara Menggunakan:[/b]\n1. Pilih kota [color=green]ASAL[/color] dari dropdown\n2. Pilih kota [color=red]TUJUAN[/color] dari dropdown\n3. Klik tombol 'Cari Rute Terpendek'"

# Custom A* implementation yang mirip dengan NetworkX astar_path
func astar_path_custom(start_id, end_id):
	"""Implementation A* seperti di NetworkX Python"""
	if not graph.has(start_id) or not graph.has(end_id):
		return []
	
	var open_set = [start_id]
	var came_from = {}
	var g_score = {}
	var f_score = {}
	
	# Initialize scores dengan INF
	for id in cities.keys():
		g_score[id] = INF
		f_score[id] = INF
	
	g_score[start_id] = 0
	f_score[start_id] = heuristic(start_id, end_id)
	
	while open_set.size() > 0:
		# Find node dengan f_score terkecil
		var current = open_set[0]
		var current_index = 0
		for i in range(open_set.size()):
			if f_score[open_set[i]] < f_score[current]:
				current = open_set[i]
				current_index = i
		
		# Jika sudah sampai tujuan
		if current == end_id:
			return reconstruct_path(came_from, current)
		
		open_set.remove_at(current_index)
		
		# Check semua neighbors
		for neighbor in graph[current].keys():
			var tentative_g_score = g_score[current] + graph[current][neighbor]
			
			if tentative_g_score < g_score[neighbor]:
				# This path ke neighbor lebih baik dari sebelumnya
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = g_score[neighbor] + heuristic(neighbor, end_id)
				
				if neighbor not in open_set:
					open_set.append(neighbor)
	
	return []  # No path found

func astar_path_length_custom(start_id, end_id):
	"""Calculate path length menggunakan A*"""
	var path_ids = astar_path_custom(start_id, end_id)
	var total_length = 0
	
	if path_ids.size() > 1:
		for i in range(path_ids.size() - 1):
			var from_city = path_ids[i]
			var to_city = path_ids[i + 1]
			total_length += graph[from_city][to_city]
	
	return total_length

func heuristic(_from_id, _to_id):
	"""Heuristic function untuk A* - menggunakan Euclidean distance"""
	# Bisa menggunakan 0 seperti di Python, atau distance untuk lebih optimal
	return 0  # Sama seperti di kode Python Anda

func reconstruct_path(came_from, current):
	"""Reconstruct path dari A* result"""
	var path_ids = [current]
	while came_from.has(current):
		current = came_from[current]
		path_ids.insert(0, current)
	return path_ids

# Mode Single Route (Google Maps style)
func find_single_route(start_id, end_id):
	"""Cari rute tunggal dari start ke end"""
	var path_ids = astar_path_custom(start_id, end_id)
	var path_points = []
	
	for id in path_ids:
		path_points.append(cities[id])
	
	current_path = path_ids
	total_distance = calculate_total_distance_from_path(path_ids)
	return path_points

# Mode Multi Destination (Bus route optimization seperti Python)
func find_multi_destination_route(start_id, destinations):
	"""Implementasi seperti kode Python - optimize route untuk multiple destinations"""
	var unique_destinations = []
	for dest in destinations:
		if dest not in unique_destinations:
			unique_destinations.append(dest)
	
	var current = start_id
	var final_route = [current]
	var remaining = unique_destinations.duplicate()
	
	while remaining.size() > 0:
		# Pilih next city terdekat dari remaining destinations
		var next_city = -1
		var min_length = INF
		
		for dest in remaining:
			var length = astar_path_length_custom(current, dest)
			if length < min_length and length > 0:
				min_length = length
				next_city = dest
		
		if next_city != -1:
			var path_to_next = astar_path_custom(current, next_city)
			if path_to_next.size() > 1:
				final_route.append_array(path_to_next.slice(1))  # Skip first element to avoid duplicates
			current = next_city
			remaining.erase(next_city)
		else:
			break  # No path found
	
	return final_route

func calculate_total_distance_from_path(path_ids):
	"""Calculate total distance dari array path IDs"""
	var total = 0
	
	if path_ids.size() > 1:
		for i in range(path_ids.size() - 1):
			var from_city = path_ids[i]
			var to_city = path_ids[i + 1]
			if graph[from_city].has(to_city):
				total += graph[from_city][to_city]
	
	return total

func generate_random_passengers(num_passengers):
	"""Generate random passengers seperti di Python"""
	var all_nodes = cities.keys()
	all_nodes.erase(1)  # Remove Surabaya (start point)
	
	passenger_destinations = []
	for i in range(num_passengers):
		var random_dest = all_nodes[randi() % all_nodes.size()]
		passenger_destinations.append(random_dest)
	
	print("🧍 Daftar Tujuan Penumpang:")
	for i in range(passenger_destinations.size()):
		print("Penumpang ", i + 1, ": ", city_names[passenger_destinations[i]], " (kode: ", passenger_destinations[i], ")")

func update_ui_status():
	"""Update status UI dengan informasi terkini"""
	var instructions_text = get_instructions_text()
	var route_info_text = get_route_info_text()
	
	if has_node("UI/InfoPanel/ScrollContainer/VBoxContainer/Instructions"):
		$UI/InfoPanel/ScrollContainer/VBoxContainer/Instructions.text = instructions_text
	
	if has_node("UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInfo"):
		$UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInfo.text = route_info_text
	
	# Update goals display
	update_goals_display()

func update_goals_display():
	"""Update display multi-goals di UI"""
	if has_node("UI/InfoPanel/ScrollContainer/VBoxContainer/GoalsDisplay"):
		var goals_display = $UI/InfoPanel/ScrollContainer/VBoxContainer/GoalsDisplay
		if multi_goals.size() > 0:
			var goals_text = "[b]🎯 Multi-Goals Aktif:[/b]\n"
			for i in range(multi_goals.size()):
				var city_id = multi_goals[i]
				goals_text += str(i + 1) + ". [color=orange]" + city_names[city_id] + "[/color]\n"
			goals_display.text = goals_text
		else:
			goals_display.text = "[color=gray]Belum ada goals ditambahkan[/color]"

func get_instructions_text():
	var instructions_text = ""
	
	if simulation_mode == SimulationMode.SINGLE_ROUTE:
		if selected_start_city == -1 or selected_end_city == -1:
			instructions_text = "[b]🗺️ Truck Simulator - Jawa Timur[/b]\n\n[b]Mode:[/b] Single Route (GUI)\n[b]Cara Menggunakan:[/b]\n1. Pilih kota [color=green]ASAL[/color] dari dropdown\n2. Pilih kota [color=red]TUJUAN[/color] dari dropdown\n3. Klik tombol 'Cari Rute Terpendek'\n4. Lihat rute A* dan pergerakan mobil\n\n[b]Kontrol Peta:[/b]\n• [color=yellow]Mouse Wheel[/color]: Zoom In/Out\n• [color=yellow]Click & Drag[/color]: Geser peta\n• [color=yellow]R[/color]: Reset zoom dan posisi\n• [color=yellow]M[/color]: Multi-Destination mode\n\n[b]Status:[/b] Pilih kota asal dan tujuan"
		else:
			var route_text = ""
			for i in range(current_path.size()):
				if i > 0:
					route_text += " → "
				route_text += city_names[current_path[i]]
			
			instructions_text = "[b]🚗 Rute Ditemukan![/b]\n\n[b]Asal:[/b] [color=green]" + city_names[selected_start_city] + "[/color]\n[b]Tujuan:[/b] [color=red]" + city_names[selected_end_city] + "[/color]\n\n[b]Rute A*:[/b]\n" + route_text + "\n\n[b]Kontrol:[/b] Mouse wheel (zoom), drag (pan), R (reset)\n\n[b]Status:[/b] Mobil sedang bergerak..."
	
	else:  # MULTI_DESTINATION mode
		if passenger_destinations.size() == 0:
			instructions_text = "[b]🚌 Bus Route Optimizer[/b]\n\n[b]Mode:[/b] Multi-Destination\n[b]Cara Menggunakan:[/b]\n1. Tekan [G] untuk generate random passengers\n2. Lihat optimized route untuk semua tujuan\n3. Tekan [M] untuk kembali ke Single Route\n\n[b]Kontrol Peta:[/b]\n• [color=yellow]Mouse Wheel[/color]: Zoom In/Out\n• [color=yellow]Click & Drag[/color]: Geser peta\n• [color=yellow]R[/color]: Reset zoom dan posisi\n\n[b]Status:[/b] Generate passengers dulu"
		else:
			var route_text = ""
			for i in range(current_path.size()):
				if i > 0:
					route_text += " → "
				route_text += city_names[current_path[i]]
			
			instructions_text = "[b]🚌 Optimized Bus Route[/b]\n\n[b]Passengers:[/b] " + str(passenger_destinations.size()) + " orang\n[b]Unique Destinations:[/b] " + str(len(set_from_array(passenger_destinations))) + " kota\n\n[b]Route:[/b]\n" + route_text
	
	return instructions_text

func get_route_info_text():
	var route_info_text = "Total Jarak: - km"
	
	if simulation_mode == SimulationMode.SINGLE_ROUTE:
		route_info_text = "🎯 Total Jarak: " + str(total_distance) + " km"
	elif simulation_mode == SimulationMode.MULTI_DESTINATION:
			route_info_text = "🚌 Total Jarak: " + str(total_distance) + " km"
	
	return route_info_text

func set_from_array(arr):
	"""Helper function untuk mendapatkan unique values dari array"""
	var unique = []
	for item in arr:
		if item not in unique:
			unique.append(item)
	return unique

func _process(delta):
	if path.size() > 0:
		var next_point = path[0]
		var old_position = $Car.position
		$Car.position = $Car.position.move_toward(next_point, speed * delta)
		
		# Update car rotation to face movement direction
		if old_position != $Car.position:
			var direction = ($Car.position - old_position).normalized()
			car_rotation = direction.angle() + PI/2  # Tambahkan PI/2 agar mobil menghadap ke depan
		
		if $Car.position.distance_to(next_point) < 5:
			path.remove_at(0)
		
		# Update car rendering di map_node
		map_node.update_car_rendering($Car.texture, $Car.position, car_rotation)
		
		# Redraw setiap frame saat mobil bergerak
		queue_redraw()

func _input(event):
	# Handle Zoom (Mouse Wheel)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = min(zoom_level + zoom_speed, max_zoom)
			map_node.update_camera_transform(camera_position, zoom_level)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = max(zoom_level - zoom_speed, min_zoom)
			map_node.update_camera_transform(camera_position, zoom_level)
			queue_redraw()
		# Handle Drag Start
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_dragging = true
			last_mouse_position = event.position
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
	
	# Handle Pan (Mouse Drag)
	elif event is InputEventMouseMotion and is_dragging:
		var delta_mouse = event.position - last_mouse_position
		camera_position -= delta_mouse / zoom_level
		last_mouse_position = event.position
		map_node.update_camera_transform(camera_position, zoom_level)
		queue_redraw()
	
	# Keyboard controls
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			# Toggle mode simulasi
			if simulation_mode == SimulationMode.SINGLE_ROUTE:
				simulation_mode = SimulationMode.MULTI_DESTINATION
				$Car.texture = bus_texture  # Ganti ke tekstur bus
				print("🚌 Mode switched to Multi-Destination (Bus Route Optimizer)")
			else:
				simulation_mode = SimulationMode.SINGLE_ROUTE
				$Car.texture = car_texture  # Kembali ke tekstur mobil
				print("🚗 Mode switched to Single Route (Truck Simulator)")
			update_ui_status()
			update_map_rendering()
			queue_redraw()
		
		elif event.keycode == KEY_G and simulation_mode == SimulationMode.MULTI_DESTINATION:
			# Generate random passengers
			generate_random_passengers(randi() % 20 + 10)  # 10-30 passengers
			
			# Calculate optimized route
			var optimized_route = find_multi_destination_route(1, passenger_destinations)  # Start from Surabaya
			current_path = optimized_route
			total_distance = calculate_total_distance_from_path(optimized_route)
			# Convert to path points for car movement
			path = []
			for id in optimized_route:
				path.append(cities[id])
			
			print("\n🚌 Rute Bus Otonom (dengan A*):")
			var route_names = []
			for id in optimized_route:
				route_names.append(city_names[id])
			print(" -> ".join(route_names))
			print("📏 Total jarak: ", total_distance, " km")
			$Car.position = cities[1]  # Start from Surabaya
			update_ui_status()
			queue_redraw()
		
		# Reset zoom and pan dengan R key
		elif event.keycode == KEY_R:
			camera_position = Vector2.ZERO
			zoom_level = 1.0
			map_node.update_camera_transform(camera_position, zoom_level)
			print("🔄 Reset zoom dan pan")
			queue_redraw()

func reset_simulation():
	# Reset all simulation states
	selected_start_city = -1
	selected_end_city = -1
	path = []
	current_path = []
	total_distance = 0
	passenger_destinations = []
	multi_goals = []  # Clear multi-goals
	
	# Reset dropdowns to default selection
	if has_node("UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/FromDropdown"):
		$UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/FromDropdown.selected = 0
	if has_node("UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/ToDropdown"):
		$UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/ToDropdown.selected = 0

func _on_add_city_button_pressed():
	"""Handler untuk tombol Add City - menambahkan kota ke multi-goals"""
	var add_city_dropdown = $UI/InfoPanel/ScrollContainer/VBoxContainer/RouteInputs/AddCityDropdown
	var city_id = add_city_dropdown.get_selected_id()
	if city_id == -1:
		print("❌ Pilih kota untuk ditambahkan!")
		update_ui_status_with_error("Pilih kota untuk ditambahkan!")
		return
	if city_id in multi_goals:
		print("❌ Kota sudah ada dalam daftar tujuan!")
		update_ui_status_with_error("Kota sudah ada dalam daftar!")
		return
	multi_goals.append(city_id)
	print("✅ Menambahkan ", city_names[city_id], " ke daftar tujuan")
	update_ui_status()
	queue_redraw()

func _on_clear_goals_button_pressed():
	"""Handler untuk tombol Clear Goals - membersihkan semua multi-goals"""
	multi_goals.clear()
	print("🔄 Membersihkan semua tujuan tambahan")
	update_ui_status()
	queue_redraw()

func _on_about_button_pressed():
	"""Handler untuk tombol About - menampilkan dialog about"""
	var about_dialog = $UI/AboutDialog
	if about_dialog:
		about_dialog.popup_centered()
		print("ℹ️ Membuka dialog About")

func get_nearest_city(screen_pos):
	var closest_city = -1
	var min_distance = 50  # Radius untuk klik
	
	# Convert screen position ke world position
	var world_pos = (screen_pos - camera_position) / zoom_level
	
	for id in cities.keys():
		var distance = world_pos.distance_to(cities[id])
		if distance < min_distance / zoom_level:  # Adjust threshold dengan zoom
			min_distance = distance * zoom_level
			closest_city = id
	
	return closest_city

func _draw():
	# Apply camera transformation for overall drawing
	var transform_matrix = Transform2D()
	transform_matrix = transform_matrix.scaled(Vector2(zoom_level, zoom_level))
	transform_matrix.origin = camera_position
	
	# Update status simulasi di map_node (rendering peta, kota, dan mobil ditangani oleh map_node)
	map_node.update_simulation_state(selected_start_city, selected_end_city, current_path, simulation_mode, multi_goals, passenger_destinations)
	
	# Update camera transform di map_node
	map_node.update_camera_transform(camera_position, zoom_level)

func join(array, separator):
	"""Helper function untuk join array menjadi string"""
	var result = ""
	for i in range(array.size()):
		if i > 0:
			result += separator
		result += str(array[i])
	return result

func update_map_rendering():
	"""Update rendering di map node"""
	map_node.update_simulation_state(
		selected_start_city,
		selected_end_city,
		current_path,
		simulation_mode,
		multi_goals,
		passenger_destinations
	)
