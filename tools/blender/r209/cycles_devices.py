"""Select the Cycles render devices used by the ship recipe."""
import bpy


def configure_cycles_device(scene):
    """Prefer OptiX, then CUDA, and fall back to CPU when neither is available."""
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
    except (AttributeError, KeyError):
        prefs = None

    if prefs is not None:
        for backend in ('OPTIX', 'CUDA'):
            try:
                prefs.compute_device_type = backend
                prefs.refresh_devices()
            except (RuntimeError, TypeError, ValueError):
                continue
            devices = [d.name for d in prefs.devices if d.type == backend]
            if not devices:
                continue
            for d in prefs.devices:
                d.use = (d.type == backend)
            scene.cycles.device = 'GPU'
            print(f'Cycles device: {backend} ({", ".join(devices)})', flush=True)
            return backend

    scene.cycles.device = 'CPU'
    print('Cycles device: CPU', flush=True)
    return 'CPU'
