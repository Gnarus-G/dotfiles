import test from 'node:test';
import assert from 'node:assert/strict';
import { isPaneVisible, parsePaneRows, selectedText } from '../.pi/agent/extensions/tmux-panes-lib.mjs';

test('parsePaneRows marks attached active unzoomed panes as visible', () => {
  const rows = parsePaneRows('s\t1\teditor\t0\t%4\t0\t1\t0\t1\t1\tzsh\t/home/me\t120x30\ttitle');
  assert.equal(rows.length, 1);
  assert.equal(rows[0].id, '%4');
  assert.equal(rows[0].visible, true);
  assert.equal(rows[0].label, '● s:1.0 editor zsh 120x30');
});

test('isPaneVisible hides inactive panes in zoomed windows', () => {
  assert.equal(isPaneVisible({ sessionAttached: true, windowActive: true, windowZoomed: true, paneActive: false }), false);
  assert.equal(isPaneVisible({ sessionAttached: true, windowActive: true, windowZoomed: true, paneActive: true }), true);
});

test('selectedText returns inclusive line ranges in either direction', () => {
  const lines = ['one', 'two', 'three', 'four'];
  assert.equal(selectedText(lines, 3, 1), 'two\nthree\nfour');
  assert.equal(selectedText(lines, 1, 3), 'two\nthree\nfour');
});
