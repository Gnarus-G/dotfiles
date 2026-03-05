# Verification (GPU Acceleration Required)

Run these in order.

## 1) ROCm Sees GPU

```bash
rocminfo
```

Expected: AMD GPU appears in output.

## 2) Service Is Running

```bash
systemctl --user status ollama --no-pager
```

Expected: `active (running)`.

## 3) Ollama API Responds

```bash
curl -s http://0.0.0.0:11434/api/tags
```

Expected: JSON response (even if model list is empty).

## 4) Model Inference Works

```bash
~/.local/opt/ollama/bin/ollama run llama3.2:1b "Say hello in one sentence."
```

Expected: normal response text with no startup errors.

## 5) Confirm No ROCm Errors in Logs

```bash
journalctl --user -u ollama -n 100 --no-pager
```

Expected: no repeated GPU/ROCm failure messages.
