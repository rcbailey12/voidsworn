"""Variant assemblies of existing faction parts. No second copy of their shapes."""


def eclipse_arc_turret(size=0.86):
    """E12: the kit's corona projector on its null cannon's fixed traverse foot.

    The axial breech turns with the emitter. Only the existing vertical foot stays
    fixed, so the gun remains seated when it turns. All fit data follows the move.
    """
    import kit
    from mathutils import Matrix
    ep = kit.HP
    base = ep.gun(size=size, weapon='gauss')
    base.comps = [c for c in base.comps if c['role'] == 'mount']
    arc = ep.spinal(1.05, r=0.24, collar_r=0.4, collar_len=0.45, block_len=0.36, block_r=0.33)
    arc.transform(Matrix.Translation((-0.3, 0, 0.48)))
    for c in arc.comps:
        c['role'] = 'turn'
    base.extend(arc, 'arc_')
    base.type = 'corona_arc'
    base.fit = dict(arc.fit, pivot=ep.P((0, 0, 0.48)), reach=1.5, mount='turret')
    return base
