"""One entry point for base sheets and their named Godot variants (issue 812).

VARIANTS maps a Godot hull id to a sheet callback. The callback runs after build(), before
finish(), so its parts, keep-outs, fit records and hard points use the same contract.
For replacements, build() can read K.variant before placing the base weapons.
"""
import re


def base_game(design):
    # Existing sheets store the hull id in a GAME line with the old data.js label.
    match = re.search(r'data\.js\s+([A-Za-z0-9_]+)', str(getattr(design, 'GAME', '')))
    if not match:
        raise ValueError('the sheet GAME line names no Godot hull id')
    return match.group(1)


def build(design, game=None):
    import kit
    import os
    import sys
    recipe = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..', 'recipe'))
    if recipe not in sys.path:
        sys.path.insert(0, recipe)
    import gamedata
    base = base_game(design)
    game = game or base
    callback = None
    if game != base:
        if gamedata.ship_attr(game, 'base') != base:
            raise ValueError(f'{game} is not a Godot variant of {base}')
        callback = getattr(design, 'VARIANTS', {}).get(game)
        if not callable(callback):
            raise ValueError(f'{design.CODE} has no variant builder for {game}')
    kit.use_kit(getattr(design, 'KIT', 'hullbreakers'))
    K = kit.Kit(design.CODE, design.LENGTH)
    K.game_ship = game
    K.variant = game if callback else ''
    design.build(K)
    if callback:
        callback(K)
    K.finish()
    return K
