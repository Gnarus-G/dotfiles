# OpenCode browser plugin setup

This repo uses the **Chrome extension backend** for OpenCode browser automation.
It works with both **Google Chrome** and **Brave**.

- package: `@different-ai/opencode-browser@4.6.1`
- OpenCode config: `.config/opencode/opencode.json`
- extension directory: `~/.opencode-browser/extension`
- broker socket: `~/.opencode-browser/broker.sock`
- expected extension ID: `ncfalpcdanbcccbaakenefpokeioldgd`

## What this installs

There are two parts.

1. **Repo-managed config**
   - OpenCode plugin entry in `opencode.json`

2. **Machine-local install**
   - unpacked browser extension in `~/.opencode-browser/extension`
   - native messaging host manifests for installed Chromium browsers
   - local broker at `~/.opencode-browser/broker.sock`
   - optional dedicated browser launchers/profiles

`./dev` handles the repo-managed config.
You must run the plugin installer once for the machine-local install.

## Prerequisites

- `node` / `npx` available
- this dotfiles repo synced with `./dev`
- at least one supported Chromium browser:
  - Chrome: `google-chrome`
  - Brave: `brave`

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

## 2. Choose browser profile

Use a **dedicated browser profile** for automation.
Do not use your primary personal profile.

### Brave profile

This machine uses Brave with a dedicated profile:

```bash
brave --user-data-dir="$HOME/.opencode-browser/brave-profile" --no-first-run
```

A local desktop launcher also exists on this machine:

```text
~/.local/share/applications/opencode-brave.desktop
```

### Chrome profile

If Chrome is installed, use a dedicated Chrome profile:

```bash
google-chrome --user-data-dir="$HOME/.opencode-browser/chrome-profile" --no-first-run
```

If you prefer Chrome's named profiles, use the profile directory that matches your dedicated automation profile:

```bash
google-chrome --profile-directory="Profile 2"
```

## 3. Run the plugin installer once

```bash
npx @different-ai/opencode-browser@4.6.1 install
```

When prompted, follow the sections below.

### Step 3: Load & pin extension

Open the extension page in the dedicated browser profile:

- Brave: `brave://extensions`
- Chrome: `chrome://extensions`

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

### Step 6: Native messaging manifests

The installer writes manifests for supported Chromium browsers.

Expected paths include:

```text
~/.config/google-chrome/NativeMessagingHosts/com.opencode.browser_automation.json
~/.config/chromium/NativeMessagingHosts/com.opencode.browser_automation.json
~/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.opencode.browser_automation.json
```

The manifest should point to:

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

You can skip this in the installer and verify manually after the browser is ready.

## 4. Connect the extension

In the dedicated browser profile:

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

## 6. Auto-launch Brave for browser ops

For this machine, Brave is auto-launched at desktop login with an XDG autostart entry:

```text
~/.config/autostart/opencode-brave.desktop
```

It points to the same dedicated browser profile:

```bash
brave --user-data-dir="$HOME/.opencode-browser/brave-profile" --no-first-run
```

The source launcher is:

```text
~/.local/share/applications/opencode-brave.desktop
```

To enable manually:

```bash
mkdir -p ~/.config/autostart
cp ~/.local/share/applications/opencode-brave.desktop ~/.config/autostart/opencode-brave.desktop
chmod +x ~/.config/autostart/opencode-brave.desktop
```

After the extension has been clicked once and permissions are granted, it should reconnect automatically when Brave starts.

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

The browser side has not started the broker yet.

Check:

1. The dedicated browser profile is open.
2. The extension is loaded from `~/.opencode-browser/extension`.
3. The extension is enabled.
4. You clicked the extension icon once.
5. The native messaging manifest exists for your browser.

Chrome:

```bash
ls ~/.config/google-chrome/NativeMessagingHosts/com.opencode.browser_automation.json
```

Brave:

```bash
ls ~/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.opencode.browser_automation.json
```

Then rerun:

```bash
npx @different-ai/opencode-browser@4.6.1 status
```

### `Broker status: ok (hostConnected=false)`

The broker is running, but the extension is not connected.

Click the **OpenCode Browser Automation** extension icon once in the dedicated browser profile.
Then rerun `status`.

### OpenCode still says browser backend is not running

Usually OpenCode just needs a restart after the broker comes up.

### Need to reinstall after a package update

Rerun:

```bash
npx @different-ai/opencode-browser@4.6.1 install
```

Then reload the unpacked extension:

- Brave: `brave://extensions`
- Chrome: `chrome://extensions`

## Notes

- Use a dedicated Chrome or Brave profile for automation.
- Do not use your primary personal profile.
- The plugin has broader trust requirements than the CDP-only browser plugin.
