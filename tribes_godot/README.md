# Prehistoric Tribes - Godot Port Project

## Dự án port game Java (decompiled) sang Godot Engine 4.2.2 cho Android

### ✅ Đã hoàn thành:

#### BƯỚC 1: Phân tích Source Code Java
- **5 màn hình chính** được xác định từ file `tribes.java` và `f.java`:
  1. **SPLASH_0** (l0) - Logo screen đầu tiên
  2. **SPLASH_1** (l1) - Logo screen thứ hai  
  3. **SPLASH_2** (l2) - Logo screen thứ ba
  4. **MENU** (state 3) - Main Menu với 5 options
  5. **GAME** (state 5) - In-game screen

#### BƯỚC 2: Thiết lập Dự án Godot
- **Viewport**: 320x240 (giữ nguyên tỉ lệ game Java gốc)
- **Stretch Mode**: canvas_items (pixel-perfect scaling)
- **Orientation**: Landscape (ngang)
- **Texture Filter**: Nearest (giữ nguyên pixel art)

#### Cấu trúc thư mục:
```
tribes_godot/
├── project.godot              # Cấu hình dự án
├── scenes/
│   ├── main.tscn             # Scene chính
│   └── main_menu_scene.gd    # Main Menu controller
├── scripts/
│   ├── main.gd               # Global controller
│   ├── game_state_manager.gd # State machine (SPLASH→MENU→GAME)
│   ├── virtual_controls.gd   # Touch controls cho Android
│   ├── sprite_data_manager.gd # Load sprites pi0/pi8/pi9
│   ├── audio_manager.gd      # Xử lý BGM/SFX
│   └── text_manager.gd       # Load text Việt hóa
├── resources/
│   ├── l0.png, l1.png, l2.png # Splash screens
├── sprites/
│   ├── pi0/ (27 frames)      # Sprite set 0
│   ├── pi8/ (12 frames)      # Sprite set 8
│   └── pi9/ (6 frames)       # Sprite set 9
├── audio/
│   ├── bgm/ (bgm_0-4.ogg)    # Background music
│   └── sfx/ (sfx_0-9.wav)    # Sound effects
└── data/
    ├── s.txt                 # Short UI strings (Vietnamese)
    ├── t.txt                 # Help/tutorial text
    └── d0.txt                # Story dialog (Vietnamese)
```

### ✅ Các hệ thống đã port:

1. **GameStateManager** - State machine từ `tribes.java`
   - Quản lý chuyển cảnh SPLASH → MENU → GAME
   - Timer cho splash screens (2000ms, 1000ms)
   - Singleton pattern để truy cập global

2. **VirtualControls** - Điều khiển cảm ứng
   - D-Pad (4 hướng) bên trái
   - Action buttons (SELECT, MENU, 0, 7, 9) bên phải
   - Ánh xạ sang key codes Java gốc
   - Hỗ trợ cả keyboard fallback

3. **SpriteDataManager** - Load sprites từ `pi0.txt`, `pi8.txt`, `pi9.txt`
   - Tự động load tất cả PNG trong folder
   - Sắp xếp theo thứ tự tên file
   - Truy cập qua index như Java gốc

4. **AudioManager** - Phát nhạc từ `a.java`
   - BGM players với crossfade support
   - 8 SFX players cho overlapping sounds
   - Volume control riêng BGM/SFX
   - Fade in/out effects

5. **TextManager** - Load text Việt hóa từ folder 0
   - `s.txt` - Short UI strings (| delimiter)
   - `t.txt` - Help text
   - `d0.txt` - Story dialog với scene offsets
   - Clean inline formatting (& → newline)

6. **MainMenuScene** - Main Menu từ `f.java`
   - 5 menu items: Chơi mới, Tiếp tục, Tùy chọn, Hướng dẫn, Thoát
   - Navigation logic (up/down/select)
   - Save game check
   - Signal-based event handling

### 🎮 Mapping Java → Godot:

| Java Component | Godot Equivalent | File |
|---------------|------------------|------|
| `MIDlet` (tribes.java) | GameStateManager | game_state_manager.gd |
| `Canvas` (f.java) | Node2D + Labels | main.gd, main_menu_scene_scene.gd |
| `Graphics.drawImage()` | Texture2D / Sprite2D | sprite_data_manager.gd |
| `Thread.sleep()` | Timer/Tween | game_state_manager.gd |
| `keyPressed()` | Input signals | virtual_controls.gd |
| `Image` class | Texture2D | sprite_data_manager.gd |
| `Player` (a.java) | AudioStreamPlayer | audio_manager.gd |
| `c.java` (text) | TextManager | text_manager.gd |
| `RecordStore` | ConfigFile/JSON | (TODO) |

### 🔧 Cách sử dụng:

1. **Import vào Godot Web Editor:**
   - Truy cập: https://editor.godotengine.org/releases/4.2.2.stable/
   - Click "Import" → Chọn folder `/workspace/tribes_godot`
   - Đợi import assets xong
   - Nhấn F5 để chạy

2. **Điều khiển:**
   - **Desktop**: Phím mũi tên/WASD + Enter/Space (select) + Esc (menu)
   - **Mobile**: Virtual D-Pad + Action buttons trên màn hình
   - **Touch**: Cảm ứng trực tiếp trên buttons

3. **Build cho Android:**
   - Export Template cho Android
   - Configure trong Project → Export
   - Add Android preset
   - Build APK

### 📋 Các bước tiếp theo:

#### BƯỚC 3: Port chi tiết từng màn hình (ĐANG THỰC HIỆN)

✅ **Main Menu Screen** - Hoàn thành:
- UI rendering với Labels
- Navigation logic (up/down/select)
- Save game check
- Signal-based event handling

⏳ **In-Game Screen** - Cần implement:
- Map rendering từ tile data
- Unit/Building classes từ `b.java`
- Resource management (gỗ, đá, thức ăn, xương)
- Pathfinding và AI
- Combat system
- Building construction
- Tech tree upgrades

⏳ **Options Screen**:
- Music/SFX volume sliders
- Difficulty selection (Dễ/Khó)
- Language selector (đã fix là Tiếng Việt)

⏳ **Help/Tutorial Screen**:
- Scrollable text display từ `t.txt`
- Page navigation

⏳ **Save/Load System**:
- Serialize game state
- Multiple save slots
- Load game validation

### 🎯 Lưu ý quan trọng:

1. **Không sửa đổi logic game** - Giữ nguyên 100% gameplay gốc
2. **Việt hóa mặc định** - Folder 0, không cần language selector
3. **Pixel-perfect** - Giữ nguyên aesthetic pixel art
4. **Android-first** - Touch controls ưu tiên hàng đầu
5. **Screen-by-Screen** - Port dứt điểm từng màn hình trước khi sang màn hình tiếp theo

### 📞 Hỗ trợ:

Nếu cần thêm thông tin về file Java cụ thể nào, yêu cầu file đó từ repo gốc để phân tích chi tiết.

---
**Phiên bản port**: 0.1.30 (matching Java original)
**Godot version**: 4.2.2 stable
**Target platform**: Android (web export supported)
