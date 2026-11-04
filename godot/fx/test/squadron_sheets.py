"""Make review sheets and motion loops from unaltered Godot captures."""
from pathlib import Path
import sys
from PIL import Image


def main():
    out = Path(sys.argv[1])
    factions = ['voidsworn', 'hegemony', 'corsair', 'chorus', 'ithar', 'deathless']
    for view in ['close', 'battle']:
        sheet = Image.new('RGB', (1920, 720), '#05070d')
        for i, faction in enumerate(factions):
            with Image.open(out / f'{faction}_{view}.png') as shot:
                shot = shot.convert('RGB').resize((640, 360), Image.Resampling.LANCZOS)
                sheet.paste(shot, ((i % 3) * 640, (i // 3) * 360))
        sheet.save(out / f'{view}_sheet.jpg', quality=95)
    for faction in factions[:-1]:
        frames = []
        paths = sorted(out.glob(f'{faction}_motion_*.png'))
        if len(paths) != 36:
            raise RuntimeError(f'{faction}: expected 36 motion frames, got {len(paths)}')
        for path in paths:
            with Image.open(path) as frame:
                frames.append(frame.convert('RGB').resize((1280, 720), Image.Resampling.LANCZOS))
        # Fixed time steps in the probe, played back at the same 12 fps.
        frames[0].save(out / f'{faction}_motion.gif', save_all=True,
                       append_images=frames[1:], duration=83, loop=0, optimize=True)
    names = ['Sunward Crusade', 'Hegemony Navy', 'Ashfall Hullbreakers',
             'The Chorus', 'The Glasswrights', 'Eclipse']
    rows = []
    for faction, name in zip(factions, names):
        links = ' | '.join(f'<a href="{faction}_{view}.png">{view}</a>'
                           for view in (['close', 'reverse', 'battle', 'launch', 'pass']
                                        if faction != 'deathless' else ['close', 'battle']))
        media = f'{faction}_motion.gif' if faction != 'deathless' else 'deathless_close.png'
        note = ('No native craft: FACTIONS.sq is null and no Eclipse hull has a hangar.'
                if faction == 'deathless' else 'Flight loop at 12 fps. Open the full captures below.')
        rows.append(f'<section><h2>{name}</h2><p>{note}</p><p>{links}</p>'
                    f'<img src="{media}" alt="{name}"></section>')
    (out / 'index.html').write_text(
        '<!doctype html><html lang="en"><meta charset="utf-8"><title>Squadron review</title>'
        '<style>body{background:#10151e;color:#e0e7f0;font:18px system-ui;max-width:1280px;'
        'margin:36px auto;padding:0 24px}a{color:#9ac9ff}img{width:100%}'
        'section{margin:48px 0}h1,h2{font-weight:600}</style>'
        '<h1>Squadron pass: issue 67</h1><p>Faction craft, banking, weaving and separate stern trails.</p>'
        '<p><a href="close_sheet.jpg">All close views</a> | '
        '<a href="battle_sheet.jpg">All battle-camera views</a></p>'
        + ''.join(rows) + '</html>', encoding='utf-8')
    print('SQUADRON_SHEETS: 2 sheets and 5 motion recordings')


if __name__ == '__main__':
    main()
