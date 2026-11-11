import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';

const source = await readFile(new URL('../.pi/agent/extensions/commit.ts', import.meta.url), 'utf8');
const code = stripTypeScriptTypes(source)
  .replace(/^import .* from .*;$/gm, '');
const Type = { Object: x => x, Array: x => x, String: () => ({}) };
const load = new Function('Type', code.replace('export default ', 'return '));

for (const exitCode of [0, 1]) {
  test(`commit tool invokes git-ac directly and reports exit ${exitCode}`, async () => {
    let tool;
    const calls = [];
    const result = { stdout: 'commit output', stderr: 'provider details', code: exitCode };
    load(Type)({
      registerTool: definition => { tool = definition; },
      exec: async (...args) => { calls.push(args); return result; },
    });
    const paths = ['file with spaces', "quote'file", '--option-like-path'];
    const signal = new AbortController().signal;
    const output = await tool.execute('id', { paths }, signal, undefined, { cwd: '/repo' });
    assert.deepEqual(calls, [['git-ac', ['-y', '--', ...paths], { cwd: '/repo', signal }]]);
    assert.equal(Boolean(output.isError), exitCode !== 0);
    assert.match(output.content[0].text, /commit output/);
    assert.match(output.content[0].text, /provider details/);
  });
}
