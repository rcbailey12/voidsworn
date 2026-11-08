### engagement (run2, run4)

| Run | GPU ms | GPU change | Frame median ms | Frame change | Frame p99 ms | Render CPU ms | Draw calls (view + shadow) | Triangles drawn (view + shadow) | Sessions, GPU spread |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Base (everything on) | 2.38 |  | 6.93 |  | 14.7 | 1.32 | 447 + 294 | 4.00M + 2.92M | 6, 6.1% |
| Shadows off | 2.10 | -0.31 | 7.03 | -0.13 | 18.6 | 1.19 | 446 + 0 | 4.00M + 0.00M | 6, 9.1% |
| MSAA 2x | 2.03 | -0.32 | 7.32 | +0.37 | 19.0 | 1.42 | 447 + 304 | 4.00M + 2.92M | 6, 6.2% |
| MSAA off | 1.77 | -0.62 | 7.29 | +0.08 | 16.3 | 1.41 | 449 + 314 | 4.00M + 2.92M | 6, 2.5% |
| Effects off | 2.03 | -0.35 | 5.18 | -1.54 | 7.2 | 1.06 | 401 + 293 | 3.87M + 2.92M | 6, 1.0% |
| Post off (SSAO, SSIL, glow) | 1.74 | -0.66 | 7.01 | -0.26 | 17.6 | 1.28 | 449 + 304 | 4.00M + 2.92M | 6, 3.7% |
| HUD off | 2.42 | +0.02 | 6.18 | -0.73 | 13.6 | 1.03 | 444 + 294 | 4.00M + 2.92M | 6, 3.2% |
| World off (planet, rocks, clouds) | 1.69 | -0.70 | 6.88 | -0.20 | 15.4 | 1.24 | 388 + 273 | 2.51M + 2.36M | 6, 3.4% |
| Ships hidden | 1.32 | -1.06 | 1.97 | -4.94 | 3.6 | 0.46 | 90 + 41 | 1.62M + 0.56M | 6, 1.3% |
| 3D at half size (quarter pixels) | 1.50 | -0.89 | 7.04 | +0.23 | 15.6 | 1.35 | 447 + 309 | 4.00M + 2.92M | 6, 3.4% |
| Fleet x2 (a copy of every hull) | 3.22 | +0.83 | 7.48 | +0.60 | 31.1 | 1.61 | 556 + 417 | 6.36M + 5.44M | 6, 3.3% |
| Three deaths during the frames | 2.50 | +0.11 | 8.00 | +0.46 | 42.2 | 1.59 | 476 + 327 | 4.26M + 3.18M | 6, 3.9% |
| Floor (board and sky only) | 0.58 | -1.80 | 0.92 | -6.01 | 1.4 | 0.14 | 2 + 0 | 0.01M + 0.00M | 6, 0.5% |

### turn (run1)

| Run | GPU ms | GPU change | Frame median ms | Frame change | Frame p99 ms | Render CPU ms | Draw calls (view + shadow) | Triangles drawn (view + shadow) | Sessions, GPU spread |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Base (everything on) | 2.49 |  | 5.53 |  | 13.6 | 1.17 | 286 + 569 | 3.02M + 5.43M | 3, 1.4% |
| Shadows off | 1.90 | -0.59 | 4.97 | -0.56 | 12.9 | 0.83 | 286 + 0 | 3.02M + 0.00M | 3, 2.3% |
| MSAA 2x | 2.25 | -0.24 | 5.37 | -0.15 | 13.3 | 1.14 | 284 + 569 | 3.02M + 5.43M | 3, 0.6% |
| MSAA off | 1.84 | -0.67 | 5.69 | +0.06 | 14.0 | 1.23 | 284 + 569 | 3.02M + 5.43M | 3, 1.5% |
| Effects off | 2.30 | -0.19 | 3.84 | -1.57 | 7.5 | 0.92 | 237 + 547 | 2.90M + 5.43M | 3, 0.7% |
| Post off (SSAO, SSIL, glow) | 1.79 | -0.70 | 5.54 | -0.29 | 13.3 | 1.16 | 285 + 569 | 3.02M + 5.43M | 3, 0.7% |
| HUD off | 2.49 | -0.01 | 4.83 | -0.77 | 14.8 | 0.90 | 285 + 569 | 3.02M + 5.43M | 3, 0.8% |
| World off (planet, rocks, clouds) | 1.58 | -0.92 | 5.44 | -0.43 | 13.4 | 1.10 | 228 + 522 | 1.54M + 4.73M | 3, 2.6% |
| Ships hidden | 1.47 | -1.02 | 2.12 | -3.39 | 4.5 | 0.45 | 84 + 47 | 1.61M + 0.71M | 3, 0.8% |
| 3D at half size (quarter pixels) | 1.46 | -1.03 | 5.52 | -0.07 | 17.4 | 1.20 | 291 + 569 | 3.02M + 5.43M | 3, 3.0% |
| Fleet x2 (a copy of every hull) | 3.14 | +0.66 | 6.07 | +0.25 | 16.0 | 1.48 | 330 + 805 | 4.20M + 10.15M | 3, 1.3% |
| Three deaths during the frames | 2.55 | +0.06 | 5.69 | +0.12 | 16.2 | 1.26 | 315 + 609 | 3.28M + 5.95M | 3, 0.4% |
| Floor (board and sky only) | 0.59 | -1.90 | 0.93 | -4.57 | 1.4 | 0.14 | 2 + 0 | 0.01M + 0.00M | 3, 0.3% |

### res (run3_res)

| Run | GPU ms | GPU change | Frame median ms | Frame change | Frame p99 ms | Render CPU ms | Draw calls (view + shadow) | Triangles drawn (view + shadow) | Sessions, GPU spread |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Base (everything on) | 2.44 |  | 7.58 |  | 22.0 | 1.47 | 450 + 294 | 4.00M + 2.92M | 3, 4.5% |
| 3D at 2560x1440 | 3.19 | +0.76 | 7.07 | -0.17 | 18.2 | 1.34 | 450 + 314 | 4.00M + 2.92M | 3, 2.7% |
| 3D at 3840x2160 | 5.46 | +3.04 | 7.17 | +0.16 | 16.5 | 1.40 | 446 + 294 | 4.00M + 2.92M | 3, 1.8% |
