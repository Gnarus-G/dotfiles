# OpenCode browser plugin setup

This repo uses the **Chrome extension backend** for OpenCode browser automation:

- package: `@different-ai/opencode-browser@4.6.1`
- OpenCode config: `.config/opencode/opencode.json`
- dedicated Chrome launcher: `.local/share/applications/claude-chrome.desktop`

This guide is the **working setup for a new machine**.

## What this installs

There are two parts:

1. **Repo-managed config**
   - OpenCode plugin entry in `opencode.json`
   - `Claude Chrome` desktop launcher

2. **Machine-local install**
   - unpacked Chrome extension in `~/.opencode-browser/extension`
   - native messaging host manifest
   - local broker at `~/.opencode-browser/broker.sock`

`./dev` handles part 1.
You must run the plugin installer once for part 2.

## Prerequisites

- `google-chrome` installed
- `node` / `npx` available
- this dotfiles repo synced with `./dev`

## 1. Sync dotfiles

From the repo root:

```bash
./dev
```

This should give you:

- `~/.config/opencode/opencode.json`
- `~/.local/share/applications/claude-chrome.desktop`

The desktop launcher opens the dedicated Chrome profile used for browser automation.

## 2. Start the dedicated Chrome profile

Launch **Claude Chrome** from your app launcher.

Or run it directly:

```bash
google-chrome --profile-directory="Profile 2"
```

On this machine, `Profile 2` is the profile named **Claude**.
If the profile name/number differs on another machine, update the `.desktop` file accordingly.

## 3. Run the plugin installer once

```bash
npx @different-ai/opencode-browser@4.6.1 install
```

When prompted:

### Step 3: Load & pin extension

In the **Claude** Chrome profile:

1. Open `chrome://extensions`
2. Enable **Developer mode**
3. Click **Load unpacked**
4. Select:

```text
~/.opencode-browser/extension
```

5. Pin the extension from the Chrome extensions menu
6. Press Enter in the installer

### Step 4: Extension ID

The package uses a fixed manifest key, so the extension ID should resolve automatically.

Expected ID:

```text
ncfalpcdanbcccbaakenefpokeioldgd
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

You can skip this in the installer and verify manually after Chrome is ready.

## 4. Connect the extension

Still in the **Claude** Chrome profile:

1. Make sure **OpenCode Browser Automation** is enabled
2. Click the extension icon once

That starts the native host / broker connection.

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

## 6. Restart OpenCode

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

### Error: cannot connect to `~/.opencode-browser/broker.sock`

This means the Chrome side is not connected yet.

Check:

1. Chrome is open in the **Claude** profile
2. The extension is loaded from `~/.opencode-browser/extension`
3. The extension is enabled
4. You clicked the extension icon once
5. Native messaging manifest exists:

```bash
ls ~/.config/google-chrome/NativeMessagingHosts/com.opencode.browser_automation.json
```

Then rerun:

```bash
npx @different-ai/opencode-browser@4.6.1 status
```

### OpenCode still says browser backend is not running

Usually OpenCode just needs a restart after the broker comes up.

### Need to reinstall after a package update

Rerun:

```bash
npx @different-ai/opencode-browser@4.6.1 install
```

Then reload the unpacked extension in `chrome://extensions`.

## Notes

- This setup assumes a **dedicated Chrome profile** for automation.
- Do not use your primary personal profile.
- The plugin has much broader trust requirements than the CDP-only browser plugin.
