import wave
import struct
import math
import os

os.makedirs('assets/sounds', exist_ok=True)

def generate_tone(filename, duration, freq, volume=0.5):
    sample_rate = 44100
    n_samples = int(duration * sample_rate)
    
    with wave.open(filename, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2) # 2 bytes per sample (16-bit)
        w.setframerate(sample_rate)
        
        for i in range(n_samples):
            # Fade out
            env = 1.0 - (i / n_samples)
            value = int(volume * env * 32767.0 * math.sin(2.0 * math.pi * freq * i / sample_rate))
            data = struct.pack('<h', value)
            w.writeframesraw(data)

generate_tone('assets/sounds/shoot.wav', 0.1, 880) # High blip
generate_tone('assets/sounds/hit.wav', 0.1, 220) # Low blip
generate_tone('assets/sounds/die.wav', 0.3, 110) # Lower longer blip
generate_tone('assets/sounds/player_hurt.wav', 0.2, 440) # Medium blip
generate_tone('assets/sounds/battle_theme.ogg', 1.0, 440) # Dummy ogg

# Since Godot expects a real OGG for .ogg, let's just make it a WAV and name it .ogg (Godot might complain).
# Actually, Godot will complain if an ogg is not an ogg. Let's make it a wav and change the AudioManager.
