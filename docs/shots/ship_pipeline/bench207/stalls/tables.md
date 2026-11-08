| Run | Mode | Session | Frame median ms | Frame p99 ms | Frames over 16.7 ms (of 720) | GPU median ms |
|---|---|---:|---:|---:|---:|---:|
| before (1) | base | 1 | 5.92 | 14.6 | 6 | 2.41 |
| before (1) | base | 2 | 6.57 | 18.1 | 8 | 2.40 |
| before (1) | base | 3 | 6.11 | 12.7 | 4 | 2.44 |
| before (2) | base | 1 | 5.99 | 13.4 | 5 | 2.39 |
| before (2) | base | 2 | 6.28 | 18.0 | 8 | 2.39 |
| before (2) | base | 3 | 5.98 | 13.4 | 5 | 2.43 |
| before (1) | deaths | 1 | 6.16 | 15.2 | 5 | 2.44 |
| before (1) | deaths | 2 | 6.79 | 20.9 | 8 | 2.51 |
| before (1) | deaths | 3 | 6.36 | 12.8 | 4 | 2.47 |
| before (2) | deaths | 1 | 6.19 | 15.9 | 7 | 2.43 |
| before (2) | deaths | 2 | 6.63 | 21.5 | 11 | 2.50 |
| before (2) | deaths | 3 | 6.41 | 12.5 | 4 | 2.44 |
| after (1) | base | 1 | 6.02 | 10.0 | 0 | 2.41 |
| after (1) | base | 2 | 6.38 | 10.6 | 0 | 2.40 |
| after (1) | base | 3 | 5.90 | 9.3 | 0 | 2.46 |
| after (2) | base | 1 | 5.92 | 10.2 | 0 | 2.39 |
| after (2) | base | 2 | 6.34 | 10.4 | 0 | 2.39 |
| after (2) | base | 3 | 5.95 | 9.3 | 0 | 2.45 |
| after (1) | deaths | 1 | 6.22 | 10.3 | 0 | 2.43 |
| after (1) | deaths | 2 | 6.59 | 10.6 | 0 | 2.49 |
| after (1) | deaths | 3 | 6.27 | 9.8 | 0 | 2.46 |
| after (2) | deaths | 1 | 6.23 | 10.9 | 0 | 2.45 |
| after (2) | deaths | 2 | 6.70 | 10.7 | 0 | 2.48 |
| after (2) | deaths | 3 | 6.22 | 9.9 | 0 | 2.46 |

| Main-thread step | Before: calls, median, worst ms | After: calls, median, worst ms |
|---|---:|---:|
| death pieces built (cut ready) (`piece_meshes`) | 58, 53.71, 85.0 | 60, 1.89, 2.8 |
| hull damage rebuild shown (`breach_apply`) | 168, 5.07, 11.1 | 158, 1.60, 3.3 |
| volley fired (`volley`) | 168, 1.06, 59.4 | 156, 1.01, 4.5 |
| ship death started (`death`) | 18, 8.99, 20.0 | 18, 4.66, 7.1 |
| ship breaks up (`break_up`) | 18, 1.03, 1.3 | 18, 0.95, 1.3 |
| death vent jet (`L:l_split_vent`) | none | none |

| Gate run (after) | Mode | Session | Frame median ms | Frame p99 ms | GPU median ms |
|---|---|---:|---:|---:|---:|
| g1_1 | base | 1 | 5.93 | 9.9 | 2.40 |
| g1_1 | base | 2 | 6.37 | 9.5 | 2.40 |
| g1_1 | base | 3 | 5.93 | 9.6 | 2.46 |
| g1_2 | base | 1 | 6.03 | 10.0 | 2.41 |
| g1_2 | base | 2 | 6.51 | 10.6 | 2.40 |
| g1_2 | base | 3 | 5.92 | 9.0 | 2.45 |
| g1_1 | res_2160 | 1 | 6.10 | 9.6 | 5.39 |
| g1_1 | res_2160 | 2 | 6.43 | 11.0 | 5.44 |
| g1_1 | res_2160 | 3 | 6.11 | 9.2 | 5.47 |
| g1_2 | res_2160 | 1 | 6.11 | 10.5 | 5.41 |
| g1_2 | res_2160 | 2 | 6.37 | 10.2 | 5.47 |
| g1_2 | res_2160 | 3 | 6.10 | 9.4 | 5.48 |
