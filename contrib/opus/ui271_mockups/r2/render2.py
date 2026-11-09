# Renders the #271 round 2 mockups with headless Chromium (Playwright). make2.sh calls it.
# Usage: python3 render2.py <site dir> <out dir>
import sys, asyncio
from playwright.async_api import async_playwright
SITE, OUT = sys.argv[1], sys.argv[2]
JOBS = [(v, m, 10, f'r2_{v}{m}.png') for v in 'ABC' for m in 'rb']
EXTRA = sys.argv[3:]  # e.g. stress:B:b
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page(viewport={'width': 1920, 'height': 1080}, device_scale_factor=1)
        jobs = list(JOBS)
        for e in [x for x in EXTRA if x.startswith('stress')]:
            k, v, m = e.split(':'); jobs.append((v, m, 20, f'r2_stress_{v}{m}.png'))
        if 'pieces' in EXTRA:
            await pg.goto(f'file://{SITE}/pieces.html'); await pg.wait_for_timeout(800)
            await pg.screenshot(path=f'{OUT}/r2_pieces.png', full_page=True); jobs = []
        for v, m, n, name in jobs:
            await pg.goto(f'file://{SITE}/index2.html?v={v}&m={m}&n={n}')
            await pg.wait_for_timeout(800)
            await pg.screenshot(path=f'{OUT}/{name}')
        await b.close()
asyncio.run(main())
# the close-up sheet: python3 render2.py <site> <out> pieces
