'use strict';
// Issue 1739: the Python 3 a check may use. PYTHON wins when set; otherwise python3 then python (python then python3 on
// Windows), then the PC's Pillow Python. A candidate counts only when it runs and reports Python 3, so the Windows Store alias ("Python was not found",
// exit 9009) and Python 2 are passed over. modules: names that must import (for example ['PIL']). Returns the command or null.
const { spawnSync } = require('child_process');
function findPython(modules = []) {
  const win = process.platform === 'win32';
  let names = process.env.PYTHON ? [process.env.PYTHON] : win ? ['python', 'python3'] : ['python3', 'python'];
  // the PC jobs' Python with Pillow (runner_common.ps1 preflight 'pil'): PIL_PYTHON, then ComfyUI's portable Python, last
  if (!process.env.PYTHON) {
    if (process.env.PIL_PYTHON) names.push(process.env.PIL_PYTHON);
    if (win && process.env.USERPROFILE) names.push(require('path').join(process.env.USERPROFILE, 'Downloads', 'ComfyUI_windows_portable', 'python_embeded', 'python.exe'));
  }
  const code = ['import sys', ...modules.map(m => 'import ' + m), 'print(sys.version_info[0])'].join('; ');
  for (const py of names) {
    const r = spawnSync(py, ['-c', code], { encoding: 'utf8', windowsHide: true });
    if (!r.error && r.status === 0 && (r.stdout || '').trim() === '3') return py;
  }
  return null;
}
module.exports = { findPython };
