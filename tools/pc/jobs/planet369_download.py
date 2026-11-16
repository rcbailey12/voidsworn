"""Issue 369: credit first, download into TEMP, and retain a per-file receipt.

Poly Haven API content supplied by Poly Haven. No API is used by the game.
No files are deleted. Run through planet369_download.bat.
"""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[3]
DEST = ROOT / 'godot/world/rocks'
CACHE = Path(os.environ['TEMP']) / 'voidsworn_issue369_sources'
UA = {'User-Agent': 'Voidsworn-asset-prep-issue369/1.0'}
SVS = 'https://svs.gsfc.nasa.gov/4720/'
NASA_TERMS = 'https://www.nasa.gov/nasa-brand-center/images-and-media/'
PH_TERMS = 'https://polyhaven.com/license'
API_TERMS = 'https://raw.githubusercontent.com/Poly-Haven/Public-API/master/ToS.md'
ROCKS = ['namaqualand_boulder_02', 'namaqualand_boulder_03',
         'namaqualand_boulder_04', 'namaqualand_boulder_05',
         'namaqualand_boulder_06', 'boulder_01', 'rock_07', 'rock_09']


def get(url):
    for attempt in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120) as r:
                return r.read()
        except Exception:
            if attempt == 2:
                raise
            time.sleep(2)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def run():
    CACHE.mkdir(parents=True, exist_ok=True)
    DEST.mkdir(parents=True, exist_ok=True)
    date = dt.datetime.now(dt.timezone.utc).isoformat()
    # Read the current source page and terms BEFORE any asset download.
    svs = get(SVS)
    nasa = get(NASA_TERMS)
    ph = get(PH_TERMS)
    api = get(API_TERMS)
    assert b"Scientific Visualization Studio" in svs
    assert b'copyright' in nasa and b'third' in nasa
    assert b'CC0' in ph and b'Permitted Use' in api
    receipt = {'read_at_utc': date, 'sources': [], 'files': [],
               'terms': [{'url': u, 'sha256': digest(b)} for u, b in
                         [(SVS, svs), (NASA_TERMS, nasa), (PH_TERMS, ph), (API_TERMS, api)]]}

    def save_receipt():
        (DEST / 'SOURCES_369.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='ascii')

    def download(url, relative, source, md5=None):
        path = CACHE / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        data = path.read_bytes() if path.exists() else get(url)
        if md5 and hashlib.md5(data).hexdigest() != md5:
            raise ValueError('Source checksum mismatch: ' + url)
        if not path.exists():
            path.write_bytes(data)
        receipt['files'].append({'file': relative, 'url': url, 'source': source,
                                 'sha256': digest(data), 'bytes': len(data), 'read_at_utc': date})
        save_receipt()
        print(relative, len(data), flush=True)
        return data

    # Separate instrument datasets, both explicitly credited by the CGI kit page.
    # No third-party copyright notice is attached to either of these two maps.
    for name, dataset in [('lroc_color_poles_8k.tif', 'LROC WAC natural colour mosaic'),
                          ('ldem_16_uint.tif', 'LRO LOLA gridded laser altimetry')]:
        receipt['sources'].append({'id': name, 'page': SVS, 'dataset': dataset,
                                   'credit': "NASA's Scientific Visualization Studio",
                                   'visualizer': 'Ernie Wright (STC)',
                                   'licence': 'US government public domain; NASA media guidelines',
                                   'terms': NASA_TERMS, 'read_at_utc': date})
        save_receipt()
        download('https://svs.gsfc.nasa.gov/vis/a000000/a004700/a004720/' + name, name, name)
    for rock in ROCKS:
        page_url = 'https://polyhaven.com/a/' + rock
        page = get(page_url)
        assert b'CC0' in page, 'Asset page does not show CC0: ' + rock
        info = json.loads(get('https://api.polyhaven.com/info/' + rock))
        files = json.loads(get('https://api.polyhaven.com/files/' + rock))
        assert info.get('type') == 2, 'Expected a model: ' + rock
        receipt['sources'].append({'id': rock, 'page': page_url, 'page_sha256': digest(page),
                                   'credit': ', '.join(info['authors']) + ' / Poly Haven',
                                   'roles': info['authors'], 'licence': 'CC0-1.0',
                                   'terms': PH_TERMS, 'read_at_utc': date})
        save_receipt()
        item = files['gltf']['1k']['gltf']
        download(item['url'], rock + '/source.gltf', rock, item['md5'])
        # Keep the geometry plus scan colour and AO/roughness. Normal maps are
        # unnecessary for the vertex-colour conversion, so do not fetch them.
        for rel, f in item['include'].items():
            if rel.endswith('.bin') or '_diff_' in rel or '_arm_' in rel:
                download(f['url'], rock + '/' + rel, rock, f['md5'])
    print('SOURCE RECEIPTS', DEST / 'SOURCES_369.json')


if __name__ == '__main__':
    argparse.ArgumentParser(description=__doc__).parse_args()
    run()
