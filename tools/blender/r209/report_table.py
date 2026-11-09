# Issue 209 round 1: the per-cell numbers table for the report, from the cell JSON files the builders write.
# usage: python3 report_table.py CELLS_JSON_DIR [cells]
import os, sys, json
J = sys.argv[1]; CELLS = (sys.argv[2] if len(sys.argv) > 2 else 'A,B0,B1,B2,B3').split(',')
print('| Cell | Triangles | Draw calls (merged) | Objects before merge | Generated pieces | Fallbacks | Parts off the hull | Parts across a break line | Section ragged (T1, T2) |')
print('|---|---:|---:|---:|---:|---|---|---|---|')
for c in CELLS:
    p = os.path.join(J, c + '.json')
    if not os.path.exists(p): print(f'| {c} | not built | | | | | | | |'); continue
    m = json.load(open(p)); g = m.get('generations', []); fb = [x['part'] for x in g if 'fallback' in x.get('source', '')]
    gen = [x for x in g if 'fallback' not in x.get('source', '')]
    bf = m.get('break_fit', {}); au = m.get('audit', {})
    print(f"| {c} | {m['triangles']:,} | {m['draw_calls_merged']} | {m['objects']} | {len(gen)} | {', '.join(fb) or 'none'} | "
          f"{len(au.get('problems', []))} | {len(au.get('crossing_break_lines', []))} | {bf.get('T1_jag', '?')}, {bf.get('T2_jag', '?')} |")
