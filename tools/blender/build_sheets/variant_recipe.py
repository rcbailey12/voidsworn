"""Write a separate recipe for a sheet's named variant, retaining the base recipe's pipeline settings.
Usage: python variant_recipe.py BASE_JSON DATA_JS_ID OUT_JSON
Write OUT_JSON into tools/recipe/ships, set SHIP to its filename without .json, then run the ordinary recipe .bat stages.
Direct Blender jobs may instead set R209_SHIP to OUT_JSON. Never overwrite the base recipe or its assets.
"""
import ast
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RECIPE = os.path.normpath(os.path.join(HERE, '..', '..', 'recipe'))
sys.path.insert(0, RECIPE)
import gamedata


def make_variant(base, game):
    if gamedata.ship_attr(game, 'base') != base['game_ship']:
        raise ValueError(f'{game} is not a variant of {base["game_ship"]}')
    src = os.path.join(HERE, 'ships', base['sheet'] + '.py')
    supported = ()
    for node in ast.parse(open(src, encoding='utf-8').read()).body:
        if isinstance(node, ast.Assign) and any(getattr(t, 'id', '') == 'VARIANTS' for t in node.targets):
            supported = ast.literal_eval(node.value)
    if game not in supported:
        raise ValueError(f'{game}: this sheet has no authored variant parts')
    out = dict(base)
    out.update(ship=base['ship'] + '__' + game, game_ship=game, game_code=base['game_code'] + '__' + game,
               name=gamedata.ship_attr(game, 'n'), cell=base['cell'] + '__' + game)
    return out


if __name__ == '__main__':
    base_path, game, output = sys.argv[1:]
    if os.path.abspath(base_path) == os.path.abspath(output):
        raise SystemExit('The variant recipe must have its own path')
    recipe = make_variant(json.load(open(base_path, encoding='utf-8')), game)
    with open(output, 'x', encoding='utf-8', newline='\n') as f:
        json.dump(recipe, f, indent=1)
        f.write('\n')
    print('Wrote', output)
