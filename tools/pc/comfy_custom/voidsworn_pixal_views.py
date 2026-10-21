# Voidsworn: Pixal3D multi-view conditioning with a free camera per view (azimuth + elevation), so an elevated concept 3/4 view
# can sit alongside eye-level side views. Same maths as the built-in Pixal3DMultiViewConditioning (orbit rig, shared scale),
# which hard-codes elevation 0 and 90-degree steps. Drop into ComfyUI/custom_nodes/.
import math, torch, logging
import comfy.utils
from comfy_extras import nodes_trellis2 as T2

class VoidswornPixal3DViews:
    @classmethod
    def INPUT_TYPES(cls):
        opt = {f'view{i}': ('IMAGE',) for i in range(1, 7)}
        return {'required': {'clip_vision_model': ('CLIP_VISION',), 'fov': ('FLOAT', {'default': 20.0, 'min': 1.0, 'max': 170.0, 'step': 0.01}),
                             'cams': ('STRING', {'default': '0,0;90,0;180,0;270,0', 'multiline': False,
                                                 'tooltip': 'azimuth,elevation in degrees per connected view, ; separated. 0 = front, 90 = left, 270 = right.'})},
                'optional': opt}
    RETURN_TYPES = ('CONDITIONING', 'CONDITIONING'); RETURN_NAMES = ('positive', 'negative'); FUNCTION = 'run'; CATEGORY = 'voidsworn'
    def run(self, clip_vision_model, fov, cams, **views):
        imgs = [views[f'view{i}'] for i in range(1, 7) if views.get(f'view{i}') is not None]
        cam = [tuple(float(x) for x in c.split(',')) for c in cams.split(';') if c.strip()]
        if len(cam) != len(imgs): raise ValueError(f'{len(imgs)} views but {len(cam)} cameras')
        items = []
        for v in imgs:
            v = v[0][None]
            if v.shape[-1] == 4: v = v[..., :3] * v[..., 3:4]
            if v.shape[1:3] != (1024, 1024): v = comfy.utils.common_upscale(v.movedim(-1, 1), 1024, 1024, 'lanczos', 'disabled').movedim(1, -1)
            items.append(v)
        az = [c[0] - cam[0][0] for c in cam]; el = [c[1] for c in cam]; f = math.radians(fov)
        c2w = T2._orbit_camera_to_world(az, el, T2._VIEW_PAD * 0.5 / math.tan(f / 2.0))
        out = T2._build_pixal3d_conditioning(clip_vision_model, torch.cat(items, 0), c2w, torch.full((len(items),), f), torch.ones(1), num_views=len(items))
        r = getattr(out, 'result', None) or getattr(out, 'args', None) or out
        logging.info(f'VoidswornPixal3DViews: {len(items)} views, cams {cam}')
        return tuple(r)

NODE_CLASS_MAPPINGS = {'VoidswornPixal3DViews': VoidswornPixal3DViews}
NODE_DISPLAY_NAME_MAPPINGS = {'VoidswornPixal3DViews': 'Voidsworn Pixal3D Views (free cameras)'}
