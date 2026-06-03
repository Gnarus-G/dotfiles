export function isPaneVisible(pane) {
  if (!pane.sessionAttached || !pane.windowActive) return false;
  if (pane.windowZoomed && !pane.paneActive) return false;
  return true;
}

function bool(value) {
  return value === '1' || value === 'true';
}

export function parsePaneRows(output) {
  return output
    .split('\n')
    .filter((line) => line.trim().length > 0)
    .map((line) => {
      const [
        sessionName = '',
        windowIndex = '',
        windowName = '',
        paneIndex = '',
        id = '',
        paneActive = '0',
        windowActive = '0',
        windowZoomed = '0',
        sessionAttached = '0',
        _paneVisible = '',
        command = '',
        path = '',
        size = '',
        title = '',
      ] = line.split('\t');

      const pane = {
        sessionName,
        windowIndex,
        windowName,
        paneIndex,
        id,
        paneActive: bool(paneActive),
        windowActive: bool(windowActive),
        windowZoomed: bool(windowZoomed),
        sessionAttached: bool(sessionAttached),
        command,
        path,
        size,
        title,
      };
      const visible = isPaneVisible(pane);
      return {
        ...pane,
        visible,
        label: `${visible ? '●' : '○'} ${sessionName}:${windowIndex}.${paneIndex} ${windowName} ${command} ${size}`.trim(),
        description: `${path}${title ? ` — ${title}` : ''}`,
      };
    });
}

export function selectedText(lines, anchor, cursor) {
  const start = Math.max(0, Math.min(anchor, cursor));
  const end = Math.min(lines.length - 1, Math.max(anchor, cursor));
  return lines.slice(start, end + 1).join('\n');
}
