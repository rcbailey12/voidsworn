"""Issue 875: capital settings, trophy paint and craft reset must not drift.

Run inside Blender. Compare against the pre-job commit in memory, so the
proof still works after the runner commits it. Write no baseline or fixture.
"""
from pathlib import Path
import subprocess
import types

path = Path(__file__).with_name('stack.py')
repo = path.resolve().parents[4]
relative = path.resolve().relative_to(repo).as_posix()
BASELINE = '1a536dcd8bde52cc603a21ffea5bc08a7afe4c73'


def load(name, source):
    module = types.ModuleType(name)
    module.__file__ = str(path)
    exec(compile(source, str(path), 'exec'), module.__dict__)
    return module


old = load('old_hullbreaker_stack', subprocess.check_output(['git', 'show', BASELINE + ':' + relative], cwd=repo))
new = load('new_hullbreaker_stack', path.read_bytes())
assert new.CONCEPT == old.CONCEPT
assert new.CRAFT_PLATES == old.CRAFT_PLATES
for length in (26, 14.6, 1.6, 6.5, 9.5, 16.5, 26, 14.6):
    old.configure_size(length); new.configure_size(length)
    assert old.TROPHY == new.TROPHY, ('trophies', length)
    assert old.ZONES['pale'] == new.ZONES['pale'], ('grey trophy zone', length)
    if length > new.CRAFT_SIZE['max_length']:
        for field in ('LAYERS', 'ZONES', 'BARE', 'ZONE_BY_KIND'):
            assert getattr(old, field) == getattr(new, field), (field, length)
    else:
        for zone in new.CRAFT_PLATES:
            if zone != 'pale':
                assert new.ZONES[zone]['wear'] > old.ZONES[zone]['wear']
                assert new.ZONES[zone]['plate_var'] > old.ZONES[zone]['plate_var']
print('PASS stack: capital settings and resets match pre-job commit; palette, trophy share and grey zone unchanged', flush=True)
