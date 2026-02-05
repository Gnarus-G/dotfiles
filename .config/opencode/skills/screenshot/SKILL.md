---
name: screenshot
description: Take screenshots using KDE Spectacle with various modes (fullscreen, current monitor, active window, window under cursor). Saves to ~/.local/share/screenshots/ and returns structured output with optional base64 encoding.
---

# Screenshot Skill

Take screenshots using KDE Spectacle. This skill provides reusable command generation, parameterized templates, and comprehensive error handling.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mode` | string | (required) | Screenshot mode: `fullscreen`, `current`, `active`, `window` |
| `delay` | integer | 0 | Delay before capture in milliseconds |
| `include_base64` | boolean | false | Include base64-encoded image in output |
| `output_dir` | string | `~/.local/share/screenshots` | Directory to save screenshots |

## Mode Mappings

| Mode | Spectacle Flag | Description |
|------|----------------|-------------|
| `fullscreen` | `-f` | Capture entire desktop |
| `current` | `-m` | Capture current monitor |
| `active` | `-a` | Capture active window |
| `window` | `-u` | Capture window under cursor |

## Reusable Command Generation

Generate the Spectacle command for a given mode:

```bash
# Set parameters
MODE="{mode}"
DELAY={delay}
OUTPUT_DIR="{output_dir:-~/.local/share/screenshots}"

# Create output directory if needed
mkdir -p "$OUTPUT_DIR"

# Generate timestamped filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="screenshot_${TIMESTAMP}.png"
OUTPUT_PATH="$OUTPUT_DIR/$FILENAME"

# Map mode to Spectacle flag
case "$MODE" in
  fullscreen) FLAG="-f" ;;
  current)    FLAG="-m" ;;
  active)     FLAG="-a" ;;
  window)     FLAG="-u" ;;
  *)          FLAG="-f" ;;  # Default to fullscreen
esac

# Build command
CMD="spectacle -b -o \"$OUTPUT_PATH\" $FLAG"

# Add delay if specified
if [ "$DELAY" -gt 0 ]; then
  CMD="$CMD -d $DELAY"
fi
```

## Error Handling

### 1. Check Spectacle Availability

```bash
if ! command -v spectacle &> /dev/null; then
  echo '{"success": false, "error": "Spectacle not found. Install KDE Spectacle."}' >&2
  exit 1
fi
```

### 2. Validate Mode Parameter

```bash
case "$MODE" in
  fullscreen|current|active|window) ;;
  *)
    echo "{\"success\": false, \"error\": \"Invalid mode: $MODE. Use: fullscreen, current, active, window\"}" >&2
    exit 1
    ;;
esac
```

### 3. Execute and Verify

```bash
# Run the command
eval "$CMD"
EXIT_CODE=$?

# Check if Spectacle succeeded
if [ $EXIT_CODE -ne 0 ]; then
  echo "{\"success\": false, \"error\": \"Spectacle failed with exit code $EXIT_CODE\"}" >&2
  exit 1
fi

# Verify file was created
if [ ! -f "$OUTPUT_PATH" ]; then
  echo "{\"success\": false, \"error\": \"Screenshot file not created at $OUTPUT_PATH\"}" >&2
  exit 1
fi

# Get file size
FILE_SIZE=$(stat -c%s "$OUTPUT_PATH" 2>/dev/null || stat -f%z "$OUTPUT_PATH" 2>/dev/null || echo "0")
```

### 4. Optional Base64 Encoding

```bash
BASE64_DATA=""
if [ "{include_base64}" = "true" ]; then
  BASE64_DATA=$(base64 -w 0 "$OUTPUT_PATH")
fi
```

## Output Format

The skill returns a JSON object:

```json
{
  "success": true,
  "path": "/home/user/.local/share/screenshots/screenshot_20240204_143022.png",
  "mode": "fullscreen",
  "filename": "screenshot_20240204_143022.png",
  "size_bytes": 123456,
  "base64": "iVBORw0KGgoAAAANS..."  // Optional
}
```

## Usage Examples

### Example 1: Fullscreen Screenshot (Default)

```bash
MODE="fullscreen"
DELAY=0
OUTPUT_DIR="~/.local/share/screenshots"

# [Command generation logic from above]
# [Error handling logic from above]

# Output result
cat << EOF
{
  "success": true,
  "path": "$OUTPUT_PATH",
  "mode": "$MODE",
  "filename": "$FILENAME",
  "size_bytes": $FILE_SIZE
}
EOF
```

### Example 2: Active Window with Delay

```bash
MODE="active"
DELAY=2000  # 2 second delay
OUTPUT_DIR="~/.local/share/screenshots"

# [Command generation logic from above]
# [Error handling logic from above]

# Output result
jq -n \
  --arg path "$OUTPUT_PATH" \
  --arg mode "$MODE" \
  --arg filename "$FILENAME" \
  --argjson size "$FILE_SIZE" \
  '{success: true, path: $path, mode: $mode, filename: $filename, size_bytes: $size}'
```

### Example 3: Window Under Cursor with Base64

```bash
MODE="window"
DELAY=0
OUTPUT_DIR="~/.local/share/screenshots"
INCLUDE_BASE64=true

# [Command generation logic from above]
# [Error handling logic from above]

# Generate base64 if requested
BASE64_OUTPUT="null"
if [ "$INCLUDE_BASE64" = "true" ]; then
  BASE64_OUTPUT="\"$(base64 -w 0 "$OUTPUT_PATH")\""
fi

# Output result
cat << EOF
{
  "success": true,
  "path": "$OUTPUT_PATH",
  "mode": "$MODE",
  "filename": "$FILENAME",
  "size_bytes": $FILE_SIZE,
  "base64": $BASE64_OUTPUT
}
EOF
```

## List Screenshots

To list all saved screenshots:

```bash
OUTPUT_DIR="{output_dir:-~/.local/share/screenshots}"
SCREENSHOTS=()

# Find all PNG files sorted by modification time (newest first)
while IFS= read -r file; do
  [ -f "$file" ] || continue
  stat_info=$(stat -c '{"filename":"%n","path":"%N","size_bytes":%s,"modified":%Y}' "$file" 2>/dev/null || \
              stat -f '{"filename":"%N","path":"%N","size_bytes":%z,"modified":%m}' "$file" 2>/dev/null)
  SCREENSHOTS+=("$stat_info")
done < <(find "$OUTPUT_DIR" -maxdepth 1 -name "*.png" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | cut -d' ' -f2-)

# Output as JSON array
TOTAL=${#SCREENSHOTS[@]}
echo "{"
echo "  \"count\": $TOTAL,"
echo "  \"directory\": \"$OUTPUT_DIR\","
echo "  \"screenshots\": ["
for i in "${!SCREENSHOTS[@]}"; do
  [ $i -lt $TOTAL ] && echo "    ${SCREENSHOTS[$i]}," || echo "    ${SCREENSHOTS[$i]}"
done
echo "  ]"
echo "}"
```

## Dependencies

- **KDE Spectacle**: Screenshot capture utility
- **base64**: For encoding (usually available via coreutils)
- **date**: For timestamps (coreutils)
- **stat**: For file info (coreutils)
- **jq** (optional): For robust JSON formatting
- **X11 Environment**: Required for Spectacle to function

## Installation

### Kubuntu/Debian-based Systems
```bash
# Install Spectacle
sudo apt update
sudo apt install spectacle

# Verify installation
which spectacle
spectacle --version
```

### Arch-based Systems
```bash
# Install Spectacle
sudo pacman -S spectacle

# Verify installation
which spectacle
spectacle --version
```

### Fedora/RHEL-based Systems
```bash
# Install Spectacle
sudo dnf install spectacle

# Verify installation
which spectacle
spectacle --version
```

### Verification
After installation, verify Spectacle is working:
```bash
spectacle --help
```

## X11 Environment Setup

Spectacle requires a running X11 session. For headless environments or remote sessions:

```bash
# Check if X11 is available
if [ -z "$DISPLAY" ]; then
    echo "Error: DISPLAY environment variable not set"
    exit 1
fi

# Verify X11 access
if ! xdpyinfo >/dev/null 2>&1; then
    echo "Error: Cannot connect to X server"
    exit 1
fi
```

## Base64 Usage Recommendations

### When to Use Base64
- **Recommended**: When the client environment cannot access local filesystem
- **Use for**: Quick sharing, remote environments, or when file paths aren't accessible
- **Ideal for**: Small to medium screenshots (under 2MB)

### When to Avoid Base64
- **Large screenshots**: Images over 2MB can cause performance issues
- **Local access**: When you need to save or edit screenshots directly
- **Memory constraints**: Base64 increases file size by ~33%

### Performance Considerations
```bash
# Check image size before encoding
FILE_SIZE=$(stat -c%s "$OUTPUT_PATH")

if [ "$FILE_SIZE" -gt 2000000 ]; then
    echo "Warning: Large screenshot detected ($((FILE_SIZE/1024))KB). Consider using file path instead of base64."
fi
```

### Client Capability Detection
If your MCP client supports file operations, prefer returning file paths:
```json
{
  "success": true,
  "path": "/home/user/.local/share/screenshots/screenshot_20240204_143022.png",
  "mode": "fullscreen",
  "filename": "screenshot_20240204_143022.png",
  "size_bytes": 123456
}
```

Otherwise, include base64 for environments without file access:
```json
{
  "success": true,
  "path": "/home/user/.local/share/screenshots/screenshot_20240204_143022.png",
  "mode": "fullscreen",
  "filename": "screenshot_20240204_143022.png",
  "size_bytes": 123456,
  "base64": "iVBORw0KGgoAAAANS..."
}
```

## Troubleshooting

### Common Issues

1. **Spectacle not found**
   ```bash
   # Solution: Install Spectacle
   sudo apt install spectacle  # Ubuntu/Debian
   sudo pacman -S spectacle    # Arch
   sudo dnf install spectacle  # Fedora
   ```

2. **X11 connection refused**
   ```bash
   # Solution: Check X11 environment
   echo $DISPLAY
   xdpyinfo
   ```

3. **Permission denied**
   ```bash
   # Solution: Check file permissions
   ls -la ~/.local/share/screenshots/
   chmod 755 ~/.local/share/screenshots/
   ```

4. **Base64 encoding fails**
   ```bash
   # Solution: Check coreutils installation
   which base64
   sudo apt install coreutils  # If missing
   ```

### Arch-based Systems
```bash
# Install Spectacle
sudo pacman -S spectacle

# Verify installation
which spectacle
spectacle --version
```

### Fedora/RHEL-based Systems
```bash
# Install Spectacle
sudo dnf install spectacle

# Verify installation
which spectacle
spectacle --version
```

### Verification
After installation, verify Spectacle is working:
```bash
spectacle --help
```

## Base64 Usage Recommendations

### When to Use Base64
- **Recommended**: When the client environment cannot access local filesystem
- **Use for**: Quick sharing, remote environments, or when file paths aren't accessible
- **Ideal for**: Small to medium screenshots (under 2MB)

### When to Avoid Base64
- **Large screenshots**: Images over 2MB can cause performance issues
- **Local access**: When you need to save or edit screenshots directly
- **Memory constraints**: Base64 increases file size by ~33%

### Performance Considerations
```bash
# Check image size before encoding
FILE_SIZE=$(stat -c%s "$OUTPUT_PATH")

if [ "$FILE_SIZE" -gt 2000000 ]; then
    echo "Warning: Large screenshot detected ($((FILE_SIZE/1024))KB). Consider using file path instead of base64."
fi
```

### Client Capability Detection
If your MCP client supports file operations, prefer returning file paths:
```json
{
  "success": true,
  "path": "/home/user/.local/share/screenshots/screenshot_20240204_143022.png",
  "mode": "fullscreen",
  "filename": "screenshot_20240204_143022.png",
  "size_bytes": 123456
}
```

Otherwise, include base64 for environments without file access:
```json
{
  "success": true,
  "path": "/home/user/.local/share/screenshots/screenshot_20240204_143022.png",
  "mode": "fullscreen",
  "filename": "screenshot_20240204_143022.png",
  "size_bytes": 123456,
  "base64": "iVBORw0KGgoAAAANS..."
}
```

## Error Response Format

On failure, output:

```json
{
  "success": false,
  "error": "Description of what went wrong"
}
```

## Notes

- Spectacle requires a running KDE Plasma session or compatible environment
- The `-b` flag runs Spectacle in background mode (no GUI)
- Screenshots are saved as PNG files with timestamps
- The skill handles both GNU stat (Linux) and BSD stat (macOS) formats
