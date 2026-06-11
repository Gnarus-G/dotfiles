# OpenCode browser plugin setup

This repo uses the **Chrome extension backend** for OpenCode browser automation.
On this machine, use **Chromium only**.

- package: `@different-ai/opencode-browser@4.6.1`
- OpenCode config: `.config/opencode/opencode.json`
- browser: `chromium`
- dedicated profile: `~/.opencode-browser/chromium-profile`
- extension directory: `~/.opencode-browser/extension`
- broker socket: `~/.opencode-browser/broker.sock`
- expected extension ID: `ncfalpcdanbcccbaakenefpokeioldgd`

## What this installs

There are two parts.

1. **Repo-managed config**
   - OpenCode plugin entry in `opencode.json`

2. **Machine-local install**
   - unpacked browser extension in `~/.opencode-browser/extension`
   - Chromium native messaging host manifest
   - local broker at `~/.opencode-browser/broker.sock`
   - dedicated Chromium launcher/profile

`./dev` handles the repo-managed config.
You must run the plugin installer once for the machine-local install.

## Prerequisites

- Chromium installed: `chromium`
- `node` / `npx` available
- this dotfiles repo synced with `./dev`

## 1. Sync dotfiles

From the repo root:

```bash
./dev
```

This should give you:

```text
~/.config/opencode/opencode.json
```

The config should include:

```json
"plugin": ["@different-ai/opencode-browser@4.6.1"]
```

## 2. Start the dedicated Chromium profile

Use the local desktop launcher:

```text
~/.local/share/applications/opencode-chromium.desktop
```

Or run it directly:

```bash
chromium --user-data-dir="$HOME/.opencode-browser/chromium-profile" --no-first-run --load-extension="$HOME/.opencode-browser/extension"
```

Do not use your primary personal browser profile.

## 3. Run the plugin installer once

```bash
npx @different-ai/opencode-browser@4.6.1 install
```

When prompted, follow the sections below.

### Step 3: Load & pin extension

In the dedicated Chromium profile, open:

```text
chrome://extensions
```

Then:

1. Enable **Developer mode**.
2. Click **Load unpacked**.
3. Select:

```text
~/.opencode-browser/extension
```

4. Pin **OpenCode Browser Automation** from the extensions menu.
5. Press Enter in the installer.

### Step 4: Extension ID

The package uses a fixed manifest key, so the extension ID should resolve automatically.

Expected ID:

```text
ncfalpcdanbcccbaakenefpokeioldgd
```

### Step 6: Native messaging manifest

The installer should write:

```text
~/.config/chromium/NativeMessagingHosts/com.opencode.browser_automation.json
```

For the dedicated `--user-data-dir` profile on this machine, also mirror it into the profile-local native messaging directory:

```bash
mkdir -p ~/.opencode-browser/chromium-profile/NativeMessagingHosts
cp ~/.config/chromium/NativeMessagingHosts/com.opencode.browser_automation.json \
  ~/.opencode-browser/chromium-profile/NativeMessagingHosts/com.opencode.browser_automation.json
```

Both manifests should point to:

```text
~/.opencode-browser/host-wrapper.sh
```

### Step 7: Configure OpenCode

Because this repo already manages `~/.config/opencode/opencode.json`, choose:

```text
4) Skip (does nothing)
```

Do not let the installer rewrite your dotfiles-managed config.

### Step 8: Optional Agent Skill

Choose:

```text
n
```

We do not need to copy the package skill into every repo.

### Step 9: Verify Extension Connection

You can skip this in the installer and verify manually after Chromium is ready.

## 4. Connect the extension

In the dedicated Chromium profile:

1. Make sure **OpenCode Browser Automation** is enabled.
2. Click the extension icon once.

That starts the native host and broker connection.

## 5. Verify machine-local install

Run:

```bash
npx @different-ai/opencode-browser@4.6.1 status
```

Healthy output should include:

```text
Broker status: ok (hostConnected=true)
```

You should also see the socket:

```bash
ls -l ~/.opencode-browser/broker.sock
```

## 6. Auto-launch Chromium for browser ops

Chromium is auto-launched at desktop login with an XDG autostart entry:

```text
~/.config/autostart/opencode-chromium.desktop
```

It launches the dedicated profile and loads the unpacked extension:

```bash
chromium --user-data-dir="$HOME/.opencode-browser/chromium-profile" --no-first-run --load-extension="$HOME/.opencode-browser/extension"
```

The source launcher is:

```text
~/.local/share/applications/opencode-chromium.desktop
```

To enable manually:

```bash
mkdir -p ~/.config/autostart
cp ~/.local/share/applications/opencode-chromium.desktop ~/.config/autostart/opencode-chromium.desktop
chmod +x ~/.config/autostart/opencode-chromium.desktop
```

After the extension has been clicked once and permissions are granted, it should reconnect automatically when Chromium starts.

## 7. Restart OpenCode

Restart OpenCode after the extension is connected.

Then test with:

```text
browser_status
```

or:

```text
browser_get_tabs
```

## Troubleshooting

### Cannot find `~/.opencode-browser/extension` in the file picker

Make sure you are browsing from **Home**, not from the dotfiles repo.

Correct path:

```text
/home/gnarus/.opencode-browser/extension
```

Wrong path:

```text
/home/gnarus/d/dotfiles/.opencode-browser/extension
```

Press **Ctrl+H** in the file picker if hidden folders are not visible.

### `Broker status: connect ENOENT ~/.opencode-browser/broker.sock`

The Chromium side has not started the broker yet.

Check:

1. The dedicated Chromium profile is open.
2. The extension is loaded from `~/.opencode-browser/extension`.
3. The extension is enabled.
4. You clicked the extension icon once.
5. The Chromium native messaging manifests exist:

```bash
ls ~/.config/chromium/NativeMessagingHosts/com.opencode.browser_automation.json
ls ~/.opencode-browser/chromium-profile/NativeMessagingHosts/com.opencode.browser_automation.json
```

Then rerun:

```bash
npx @different-ai/opencode-browser@4.6.1 status
```

### `Broker status: ok (hostConnected=false)`

The broker is running, but the extension is not connected.

Click the **OpenCode Browser Automation** extension icon once in the dedicated Chromium profile.
Then rerun `status`.

If it still stays false, restart the dedicated Chromium profile after mirroring the native messaging manifest into `~/.opencode-browser/chromium-profile/NativeMessagingHosts/`.

### OpenCode still says browser backend is not running

Usually OpenCode just needs a restart after the broker comes up.

### Need to reinstall after a package update

Rerun:

```bash
npx @different-ai/opencode-browser@4.6.1 install
```

Then reload the unpacked extension in:

```text
chrome://extensions
```

## Notes

- Use only the dedicated Chromium profile for automation.
- Do not use your primary personal browser profile.
- The plugin has broader trust requirements than the CDP-only browser plugin.
