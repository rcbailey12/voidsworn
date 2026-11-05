"""R104 station metal repaint. Build inputs only, no runtime shader or geometry.

The three coats belong to whole construction groups. Small attached fittings
inherit their parent coat. Faction colour is reserved for two docking lips or
the existing tower band, and lights for one continuous strip per control face.
"""
TONES = ('#303e49', '#60727f', '#94a3ac')
RECESS = '#10171d'


def assign(parts, name):
    zones = []
    for obj in parts:
        label = obj.name
        # The entire spine and its small equipment share the middle coat.
        tone = 1
        if any(k in label for k in ('fin', 'radiator', 'control_tower', 'control_sensors',
                                    'secondary_sensor', 'secondary_sensors')):
            tone = 0
        if any(k in label for k in ('end_cap', 'control_tower_crown',
                                    'intake_', 'output_', 'cracking_tower',
                                    'tower_top', 'process_sensors')):
            tone = 2
        # No contrasting little sensor caps, clamps or gun cowlings.
        trim = float((label.startswith('berth_lip_') or label == 'cradle_outer_rail')
                     if name == 'fleet' else label == 'tower_top_band')
        lamp = float(label == ('control_tower' if name == 'fleet' else 'cracking_tower'))
        for attr, value in (('station_coat', tone / 2), ('station_mark', trim),
                            ('station_lamp', lamp)):
            a = obj.data.attributes.new(attr, 'FLOAT', 'POINT')
            a.data.foreach_set('value', [value] * len(obj.data.vertices))
        zones.append({'part': label, 'coat': tone, 'mark': bool(trim), 'lamp': bool(lamp)})
    return zones


def nodes(nt, n, mathn, mix, palette, linear, split, ao, name):
    def attribute(label):
        return n(nt, 'ShaderNodeAttribute', attribute_name=label).outputs['Fac']

    coat = attribute('station_coat')
    base = mix(nt, (*linear(TONES[0]), 1), (*linear(TONES[1]), 1),
               mathn(nt, 'GREATER_THAN', coat, .25))
    base = mix(nt, base, (*linear(TONES[2]), 1), mathn(nt, 'GREATER_THAN', coat, .75))
    geo = n(nt, 'ShaderNodeNewGeometry')
    pos = n(nt, 'ShaderNodeSeparateXYZ')
    nt.links.new(geo.outputs['Position'], pos.inputs[0])
    normal = n(nt, 'ShaderNodeSeparateXYZ')
    nt.links.new(geo.outputs['Normal'], normal.inputs[0])
    # A single broad guide on each existing lip. No repeated hazard checker.
    mark = attribute('station_mark')
    if name == 'fleet':
        center = mathn(nt, 'LESS_THAN', mathn(nt, 'ABSOLUTE', pos.outputs['X'], 0), 15)
        outer = mathn(nt, 'GREATER_THAN', mathn(nt, 'ABSOLUTE', pos.outputs['X'], 0), 11)
        mark = mathn(nt, 'MULTIPLY', mark, mathn(nt, 'MULTIPLY', center, outer))
        mark = mathn(nt, 'MULTIPLY', mark, mathn(nt, 'GREATER_THAN', normal.outputs['Z'], .9))
    else:
        # The real 0.8-unit band is trim, never a new base coat.
        mark = mathn(nt, 'MULTIPLY', mark, mathn(nt, 'GREATER_THAN', normal.outputs['Y'], .8))
    base = mix(nt, base, (*linear(palette['trim']), 1), mark)
    # Only geometry AO darkens recesses. No painted fake grooves or noise.
    cavity = mathn(nt, 'MULTIPLY', split.outputs['Red'], ao.outputs[0])
    cavity = mathn(nt, 'POWER', cavity, 1.5)
    base = mix(nt, (*linear(RECESS), 1), base, cavity)
    # Geometry edge mask, under 8 luma on flat surfaces. Mips suppress the thin
    # wear at battle distance; no grain or high-frequency albedo is baked.
    wear = mathn(nt, 'MULTIPLY', split.outputs['Blue'], .12)
    base = mix(nt, base, (.30, .34, .38, 1), wear)
    orm = n(nt, 'ShaderNodeCombineColor', mode='RGB')
    nt.links.new(ao.outputs[0], orm.inputs[0])
    nt.links.new(mathn(nt, 'SUBTRACT', .60, mathn(nt, 'MULTIPLY', wear, .8)), orm.inputs[1])
    nt.links.new(mathn(nt, 'ADD', .52, wear), orm.inputs[2])
    # One 3.6-unit continuous strip, rather than dotted windows. It follows an
    # existing control face; all other original light masks are suppressed.
    lamp = attribute('station_lamp')
    low, high = (8.0, 8.65) if name == 'fleet' else (9.0, 9.65)
    for value in (mathn(nt, 'GREATER_THAN', pos.outputs['Z'], low),
                  mathn(nt, 'LESS_THAN', pos.outputs['Z'], high),
                  mathn(nt, 'LESS_THAN', mathn(nt, 'ABSOLUTE', pos.outputs['X'], 0), 1.8),
                  mathn(nt, 'GREATER_THAN', mathn(nt, 'ABSOLUTE', normal.outputs['Y'], 0), .8)):
        lamp = mathn(nt, 'MULTIPLY', lamp, value)
    emission = mix(nt, (0, 0, 0, 1), (*palette['win'], 1), lamp)
    # Light is a physical inset on an existing face, with a dark surround.
    base = mix(nt, base, (*linear(RECESS), 1), lamp)
    return base, orm.outputs[0], emission
