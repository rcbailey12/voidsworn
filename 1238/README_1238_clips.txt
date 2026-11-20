1238 clips re-encoded on the PC with the ffmpeg already in Downloads\trellis2\code\venv (imageio_ffmpeg v7.1); nothing installed.
Settings: scale to 720p, libx264 crf 26 preset medium, yuv420p, AAC 128k, faststart. 51.32 s, 60 fps each. The source AVIs are kept.
AUDIO CHECK: both source AVIs have a pcm_s16le 48 kHz stereo track, but volumedetect reads mean and max -91.0 dB on each,
which is digital silence. The "with sound" clips carry no audible sound; the mp4s are silent too because the source is.
