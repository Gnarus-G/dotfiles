# 🖥️ Eww Multi-Monitor Bar Configuration

This eww configuration properly supports multiple monitors using window arguments.

## How It Works

**Window Arguments**: The `bar` window uses arguments for dynamic configuration:

```yuck
(defwindow bar [monitor_id ?y_offset ?reserve_distance]
  :monitor monitor_id
  :geometry (geometry :y { y_offset ?: "10px" } ...)
  :reserve (struts :distance { reserve_distance ?: "35px" } ...)
  (bar :index monitor_id))
```

**Multi-Monitor Support**: The `up` script:

1. Detects connected monitors using `xrandr`
2. Opens bars with proper arguments for each monitor
3. Network variables (`ip_address`, `net_interface`) are handled by `defpoll`

## Key Benefits

- ✅ **Proper eww patterns**: Uses window arguments as intended
- ✅ **Per-monitor positioning**: Different margins for primary/secondary monitors
- ✅ **Simple**: No overengineered generation scripts
- ✅ **Maintainable**: Clean, single configuration file

## Usage

```bash
./up    # Auto-detects monitors and opens positioned bars
./down  # Closes all eww windows
```

## Monitor Configuration

**Primary Monitor (index 0)**:

- Y offset: `10px`
- Reserve distance: `35px`

**Secondary Monitors (index 1+)**:

- Y offset: `5px`
- Reserve distance: `30px`

## Implementation

Each monitor gets a uniquely configured bar:

```bash
eww open bar \
  --id "bar0" \
  --screen 0 \
  --arg monitor_id=0 \
  --arg y_offset="10px" \
  --arg reserve_distance="35px"
```

The `monitor_id` argument provides workspace information specific to each monitor.
