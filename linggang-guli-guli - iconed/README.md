# 🗺️ Linggang Guli Guli - Simulasi Google Maps Jawa Timur

## 📋 **Deskripsi Project**

Simulasi navigasi GPS untuk wilayah Jawa Timur menggunakan **Godot Engine 4.4**. Project ini mengimplementasikan algoritma **A* pathfinding** untuk mencari rute terpendek antar 26 kota di Jawa Timur dengan data geografis yang akurat.

## ✨ **Fitur Utama**

### 🚗 **Single Route Navigation**
- Pilih kota asal dan tujuan dari dropdown
- Algoritma A* untuk mencari rute terpendek
- Visualisasi pergerakan mobil mengikuti rute
- Display total jarak dalam kilometer

### 🎯 **Multi-Goals Routing** *(Fitur Baru!)*
- **Tambah multiple destinations** sebelum mencapai tujuan akhir
- **Smart pathfinding** yang mengoptimalkan urutan kunjungan
- **Visual indicators** dengan warna berbeda untuk setiap jenis kota:
  - 🟢 **Hijau**: Kota asal
  - 🔴 **Merah**: Tujuan akhir  
  - 🟠 **Orange**: Goals intermediate
  - 🔵 **Biru**: Kota biasa

### 🎮 **Interactive Controls**
- **Mouse wheel**: Zoom in/out
- **Click & drag**: Pan around map
- **Keyboard shortcuts**:
  - `R`: Reset zoom dan pan
  - `M`: Switch mode (Multi-destination/Single route)

## 🏙️ **26 Kota Jawa Timur**

1. Surabaya   14. Kediri
2. Gresik     15. Nganjuk  
3. Sidoarjo   16. Tulungagung
4. Mojokerto  17. Blitar
5. Jombang    18. Trenggalek
6. Bojonegoro 19. Malang
7. Lamongan   20. Pasuruan
8. Tuban      21. Probolinggo
9. Madiun     22. Lumajang
10. Ngawi     23. Bondowoso
11. Magetan   24. Situbondo
12. Ponorogo  25. Jember
13. Pacitan   26. Banyuwangi

## 🔧 **Cara Menggunakan**

### **🎯 Multi-Goals Navigation (Rekomendasi)**

1. **Pilih Kota Asal**: Dropdown "🚩 Dari"
2. **Pilih Kota Tujuan Akhir**: Dropdown "🎯 Ke"
3. **Tambah Goals** (opsional):
   - Pilih kota dari dropdown "-- Pilih Kota untuk Ditambah --"
   - Klik tombol **"➕ Tambah Kota"**
   - Ulangi untuk menambah lebih banyak goals
4. **Mulai Navigasi**: Klik **"🔍 Cari Rute Terpendek"**
5. **Monitor Progress**: Lihat mobil bergerak mengikuti rute optimal

### **🚗 Single Route Navigation**

1. Pilih kota asal dan tujuan
2. Langsung klik "🔍 Cari Rute Terpendek"
3. Tidak perlu menambah goals

### **🎮 Kontrol Tambahan**

- **🔄 Reset**: Hapus semua pilihan dan mulai dari awal
- **🗑️ Hapus Semua Goals**: Hapus semua intermediate goals
- **Zoom & Pan**: Mouse wheel + drag untuk navigasi peta

## 🧠 **Algoritma & Teknologi**

### **A* Pathfinding Algorithm**
```gdscript
func astar_path_custom(start_id, end_id):
    # Custom implementation mirip NetworkX Python
    # Menggunakan heuristic distance untuk optimasi
```

### **Multi-Destination Optimization**
```gdscript
func find_multi_destination_route(start_id, destinations):
    # Greedy nearest-neighbor approach
    # Optimal untuk traveling salesman problem
```

### **Data Geografis Real**
- Koordinat latitude/longitude asli dari 26 kota
- Jarak antar kota berdasarkan data real (km)
- Konversi koordinat geografis ke screen coordinates

## 📊 **Contoh Output**

```
🔍 Multi-destination pathfinding:
   Start: Surabaya
   Goals: [Malang, Banyuwangi, Jember]
   → Next: Malang (distance: 78 km)
   → Next: Jember (distance: 172 km)  
   → Next: Banyuwangi (distance: 105 km)

🛣️ Rute Multi-Destination: 
   → Surabaya
   → Sidoarjo
   → Pasuruan
   → Malang
   → Lumajang
   → Jember
   → Banyuwangi

📏 Total jarak: 355 km
```

## 🎨 **Visual Features**

- **🗺️ Peta Jawa Timur**: Background map dengan skala akurat
- **🚗 Animasi Mobil**: Bergerak dan berputar mengikuti arah rute
- **📍 City Markers**: Lingkaran dengan nama dan nomor kota
- **➡️ Route Lines**: Garis dengan panah arah (warna berbeda untuk multi-goals)
- **📏 Distance Labels**: Jarak antar kota ditampilkan pada koneksi

## 🚀 **Menjalankan Project**

1. **Install Godot Engine 4.4+**
2. **Open Project**: Buka `project.godot`
3. **Run Scene**: Tekan F5 atau klik Play
4. **Enjoy!**: Mulai eksplorasi rute di Jawa Timur

## 🛠️ **Technical Details**

- **Engine**: Godot 4.4
- **Language**: GDScript
- **Architecture**: Node2D dengan Canvas UI
- **Assets**: PNG images untuk peta dan mobil
- **Data Structure**: Graph adjacency list dengan weights
- **Algorithms**: A* pathfinding + Greedy TSP solver

## 🎯 **Fitur Perbaikan**

### ✅ **Yang Sudah Diperbaiki**
- ✅ Implementasi tombol "➕ Tambah Kota" yang berfungsi
- ✅ Validasi input untuk mencegah duplikasi goals
- ✅ Display real-time daftar goals yang sudah ditambahkan
- ✅ Multi-destination pathfinding yang optimal
- ✅ Visual feedback dengan warna berbeda untuk route types
- ✅ Error handling dan user feedback
- ✅ Reset functionality untuk goals

### 🔄 **Cara Kerja Multi-Goals**
1. User menambah beberapa kota sebagai "goals" intermediate
2. Sistem menggabungkan goals + destination akhir
3. Algoritma A* mencari rute optimal yang mengunjungi semua goals
4. Menggunakan nearest-neighbor approach untuk optimasi urutan
5. Mobil bergerak mengikuti rute yang sudah dioptimalkan

## 📱 **UI Components**

- **FromDropdown**: Pilih kota asal
- **ToDropdown**: Pilih kota tujuan akhir  
- **AddCityDropdown**: Pilih kota untuk ditambah ke goals
- **AddCityButton**: Tombol untuk menambah kota ke goals
- **ClearGoalsButton**: Hapus semua goals
- **GoalsDisplay**: Tampilan daftar goals yang aktif
- **Instructions**: Panduan penggunaan dan status
- **RouteInfo**: Informasi total jarak

---

**🇮🇩 Made with ❤️ for exploring East Java, Indonesia** 