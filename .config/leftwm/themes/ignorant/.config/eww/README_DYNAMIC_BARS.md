# 🖥️ Dynamic Multi-Monitor Bar System

This system automatically detects connected monitors and generates appropriate eww bar configurations dynamically.

## 📁 Files Overview

- **`eww.yuck.template`** - Base template containing all widgets except bar window definitions
- **`eww.yuck`** - Generated configuration file (auto-generated, don't edit manually)
- **`generate_bars.sh`** - Script to generate dynamic bar configurations
- **`cleanup_bars.sh`** - Script to clean up generated configurations

## 🔄 How It Works

### 1. **Template System**

- The base configuration is stored in `eww.yuck.template`
- This contains all your widgets, styling, and logic
- Bar window definitions are generated dynamically

### 2. **Monitor Detection**

- Uses `xrandr --query | grep " connected"` to detect active monitors
- Automatically creates bar definitions for each detected monitor

### 3. **Bar Generation Rules**

- **Monitor 0 (Primary)**: `bar` with 10px top margin, 35px reserve
- **Monitor 1+**: `bar1`, `bar2`, etc. with 5px top margin, 30px reserve
- Each bar uses the same `(bar :index N)` widget with different indices

### 4. **Automatic Integration**

- The `up` script automatically runs `generate_bars.sh` before starting eww
- The `down` script runs `cleanup_bars.sh` to restore the template
- No manual intervention needed when adding/removing monitors

## 🚀 Usage

### Normal Operation

Just use your theme as normal:

```bash
./up    # Automatically detects monitors and creates bars
./down  # Automatically cleans up generated configs
```

### Manual Generation

```bash
cd .config/eww
./generate_bars.sh    # Generate bars based on current monitors
./cleanup_bars.sh     # Restore template (removes generated bars)
```

### Adding New Widgets

Edit `eww.yuck.template`, not `eww.yuck`. Your changes will be preserved across theme restarts.

## 🔧 Monitor Configuration

The system automatically handles:

- **1 Monitor**: Creates only `bar` (primary)
- **2 Monitors**: Creates `bar` + `bar1`
- **3 Monitors**: Creates `bar` + `bar1` + `bar2`
- **N Monitors**: Creates `bar` + `bar1` + ... + `barN-1`

## 📝 Customization

To modify bar positioning or styling for specific monitors, edit the `generate_bar_def()` function in `generate_bars.sh`:

```bash
# Different Y positions for different monitors
if [ $monitor_index -eq 2 ]; then
    y_pos="15px"    # Special positioning for third monitor
    distance="40px"
fi
```

## 🐛 Troubleshooting

### Bars not appearing on new monitor

```bash
./down && ./up    # Restart theme to detect new monitors
```

### Template got corrupted

```bash
cp eww.yuck.backup eww.yuck.template    # Restore from backup
```

### Manual cleanup needed

```bash
./cleanup_bars.sh    # Reset to template state
```

## 📊 System Benefits

- ✅ **Automatic**: No manual configuration when adding/removing monitors
- ✅ **Consistent**: All bars use the same widgets and styling
- ✅ **Maintainable**: Single source of truth in template file
- ✅ **Flexible**: Easy to customize per-monitor settings
- ✅ **Safe**: Automatic cleanup prevents config pollution
