# Renders the #271 mockups with headless Chromium (Playwright). make.sh calls it.
# Usage: python3 render.py <site dir> <out dir>
import sys, asyncio
from playwright.async_api import async_playwright
SITE, OUT = sys.argv[1], sys.argv[2]
JOBS = [(l, v, 10, f'o{l}{v[0]}.png') for l in '123' for v in ('restrained', 'bold')] + [(l, 'restrained', 20, f's{l}.png') for l in '123']
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page(viewport={'width': 1920, 'height': 1080}, device_scale_factor=1)
        for l, v, n, name in JOBS:
            await pg.goto(f'file://{SITE}/index.html?l={l}&v={v}&n={n}')
            await pg.wait_for_timeout(700)
            await pg.screenshot(path=f'{OUT}/{name}')
        await b.close()
asyncio.run(main())
