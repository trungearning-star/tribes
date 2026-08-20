# Prehistoric Tribes - Godot Port Project

## Dự án port game Java (Decompiled) sang Godot Engine 4.2

### Cấu trúc thư mục:
```
tribes_godot/
├── project.godot          # File cấu hình dự án Godot
├── icon.png               # Icon ứng dụng
├── scenes/                # Các scene file (.tscn)
│   └── main.tscn         # Scene chính (Splash → Menu → Game)
├── scripts/              # GDScript files
│   ├── main.gd           # Controller chính
│   ├── game_state_manager.gd  # Quản lý state machine
│   ├── virtual_controls.gd    # Điều khiển cảm ứng Android
│   ├── sprite_data_manager.gd # Load và quản lý sprites
│   └── audio_manager.gd       # Xử lý âm thanh BGM/SFX
├── sprites/              # Sprite images từ Java game
│   ├── pi0/             # Sprite set 0 (27 frames)
│   ├── pi8/             # Sprite set 8 (12 frames)
│   └── pi9/             # Sprite set 9 (6 frames)
├── audio/               # Audio files
│   ├── bgm/            # Background music (bgm_0-4.ogg)
│   └── sfx/            # Sound effects (sfx_0-9.wav)
├── data/               # Data files (text, saves)
└── fonts/              # Fonts (nếu cần)
```

### Hướng dẫn sử dụng:

#### BƯỚC 1: Import vào Godot Web Editor
1. Truy cập https://editor.godotengine.org/releases/4.2.2.stable/
2. Click "Import Project"
3. Chọn folder `tribes_godot` làm project folder
4. Godot sẽ tự động import resources

#### BƯỚC 2: Cấu hình cho Android
Project đã được cấu hình sẵn trong `project.godot`:
- Viewport: 320x240 (giữ nguyên tỉ lệ Java gốc)
- Stretch Mode: canvas_items (pixel-perfect)
- Orientation: Landscape (ngang)
- Input mappings cho touch controls

#### BƯỚC 3: Chạy thử
1. Nhấn F5 hoặc click nút Play
2. Splash screens sẽ hiển thị tuần tự (l0 → l1 → l2)
3. Sau đó chuyển sang Main Menu
4. Virtual controls sẽ hiện ở 2 bên màn hình

### Các màn hình sẽ implement (theo thứ tự):

1. **Splash Screen** (DONE ✓)
   - Hiển thị logo THQ/Gear Games
   - Tự động chuyển sau 1-2 giây
   
2. **Main Menu** (TODO)
   - New Game
   - Continue
   - Options
   - Help
   
3. **In-Game Screen** (TODO)
   - Map rendering
   - Unit management
   - Building construction
   - Resource management
   
4. **Pause/Options Menu** (TODO)
5. **Game Over/Victory Screen** (TODO)

### Mapping từ Java sang Godot:

| Java Component | Godot Equivalent |
|---------------|------------------|
| MIDlet | Node (GameStateManager) |
| Canvas | Node2D / Control |
| Graphics | TextureRect / draw_* methods |
| Image | Texture2D / Image |
| Thread.sleep() | Tween / Timer |
| keyPressed() | InputEventKey / Signals |
| repaint() | _process() with update |
| RecordStore (save) | ConfigFile / JSON |

### Tài nguyên đã xử lý:
- ✅ Sprites: pi0 (27), pi8 (12), pi9 (6) PNG files
- ✅ BGM: 5 OGG files (bgm_0-4)
- ✅ SFX: 10 WAV files (sfx_0-9)
- ✅ Text data: Folder 0 (Vietnamese)

### Next Steps:
1. Implement Main Menu scene với UI buttons
2. Load splash images (l0.png, l1.png, l2.png) nếu có
3. Implement game loop và state transitions
4. Port map rendering logic từ f.java
5. Add unit/building classes
6. Implement save/load system

### Lưu ý:
- Giữ nguyên logic game Java gốc 100%
- Tối ưu theo chuẩn Godot (GDScript, signals, scenes)
- Hỗ trợ điều khiển cảm ứng cho Android
- Maintain 320x240 resolution với pixel-perfect scaling
