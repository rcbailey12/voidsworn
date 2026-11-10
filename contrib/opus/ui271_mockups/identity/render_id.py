# Renders the #271 identity mockups with headless Chromium (Playwright). make_id.sh calls it.
# Usage: python3 render_id.py <site dir> <out dir>
import sys, asyncio
from playwright.async_api import async_playwright
SITE, OUT = sys.argv[1], sys.argv[2]
JOBS = [(i, 10, f'id{i}.png') for i in '123'] + [(i, 20, f'id{i}_20.png') for i in '123']
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page(viewport={'width': 1920, 'height': 1080}, device_scale_factor=1)
        for i, n, name in JOBS:
            await pg.goto(f'file://{SITE}/index_id.html?id={i}&n={n}')
            await pg.evaluate('document.fonts.ready')
            await pg.wait_for_timeout(900)
            await pg.screenshot(path=f'{OUT}/{name}')
        await b.close()
asyncio.run(main())
