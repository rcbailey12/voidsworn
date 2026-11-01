# A4 job chain (Nov 1 2026): long PC work (the 28-ship rebuild, about 2 hours) as a chain of short queued jobs, one at a time. The
# watcher runs the OLDEST queue\*.bat first, so dropping all the jobs in at once would make every other stream's capture wait behind
# them; here each job queues the next one as its last step, with a fresh timestamp, so anything queued meanwhile runs first.
#   python chain.py LIST QUEUE_DIR TAG
# LIST: one entry per line, popped from the top. A ship code becomes a4_rb_<NN>_<CODE>_<TAG>.bat (a4tools\a4_ship.bat, then the
# chain again); "@path\to\job.bat" copies that finishing job (it must call the chain itself to go on). Empty list: the chain ends.
# Log: LIST + ".log" (one line per job queued).
import sys, os, time


def crlf(s): return s.replace('\r\n', '\n').replace('\n', '\r\n')


def main():
    lst, qdir, tag = sys.argv[1:4]
    lines = [l.strip() for l in open(lst).read().splitlines() if l.strip() and not l.startswith('#')]
    log = open(lst + '.log', 'a')
    if not lines:
        log.write(time.strftime('%H:%M:%S') + ' chain done\n'); print('[chain] done'); return
    head, rest = lines[0], lines[1:]
    done_n = sum(1 for _ in open(lst + '.log')) if os.path.exists(lst + '.log') else 0
    py = r'"%USERPROFILE%\Downloads\ComfyUI_windows_portable\python_embeded\python.exe"'
    again = f'{py} -s a4tools\\a4\\chain.py "{lst}" "{qdir}" {tag}\n'
    if head.startswith('@'):
        src = head[1:]; name = f'a4_rb_{done_n:02d}_{os.path.splitext(os.path.basename(src))[0]}_{tag}.bat'
        body = open(src).read()
    else:
        name = f'a4_rb_{done_n:02d}_{head}_{tag}.bat'
        body = (f'@echo off\nrem A4 rebuild chain {tag}: {head} (paint v2, 4096 bakes, concept paint), then queue the next job\n'
                f'set A4CODE={head}\ncall a4tools\\a4_ship.bat\nset A4CODE=\n' + again + 'exit /b 0\n')
    tmp = os.path.join(os.path.dirname(os.path.abspath(lst)), name + '.tmp'); open(tmp, 'w', newline='').write(crlf(body))  # beside the list, not in the queue
    open(lst, 'w').write('\n'.join(rest) + ('\n' if rest else ''))
    os.replace(tmp, os.path.join(qdir, name))  # appears whole, with a fresh timestamp
    log.write(time.strftime('%H:%M:%S') + ' queued ' + name + '\n'); print('[chain] queued', name, len(rest), 'left')


if __name__ == '__main__':
    main()
