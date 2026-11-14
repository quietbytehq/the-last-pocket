"""Original short physical-impact placeholders; replace with licensed ElevenLabs clips.
No sampled recordings, MIDI, third-party sounds, or musical notes are used.
"""
from pathlib import Path
import math, random, struct, wave
root=Path(__file__).resolve().parents[1]/'assets/audio'
rate=44100
for kind,seed,cutoff,decay,duration in [('ball',11,0.70,0.007,0.15),('cue',29,0.36,0.012,0.18),('rail',47,0.10,0.023,0.22),('pocket',73,0.055,0.05,0.32)]:
 rng=random.Random(seed); n=int(rate*duration);dry=[];low=0.0
 for i in range(n):
  t=i/rate;white=rng.uniform(-1,1);low+=cutoff*(white-low)
  transient=(white-low)*0.50+low*0.5 if kind=='ball' else low
  envelope=(1-math.exp(-t/0.00015))*math.exp(-t/decay)
  if kind=='pocket':envelope=(1-math.exp(-t/0.002))*math.exp(-t/decay)
  dry.append(transient*envelope)
 channels=[]
 for channel in range(2):
  samples=dry.copy()
  for delay,gain in [(0.018+channel*0.003,0.095),(0.039-channel*0.002,0.045),(0.071+channel*0.004,0.018)]:
   offset=int(delay*rate)
   for j in range(offset,n):samples[j]+=dry[j-offset]*gain
  channels.append(samples)
 peak=max(abs(x) for c in channels for x in c) or 1
 with wave.open(str(root/f'{kind}.wav'),'wb') as w:
  w.setnchannels(2);w.setsampwidth(2);w.setframerate(rate)
  w.writeframes(b''.join(struct.pack('<hh',int(max(-1,min(1,channels[0][i]/peak*0.72))*32767),int(max(-1,min(1,channels[1][i]/peak*0.72))*32767)) for i in range(n)))
print('Created four original stereo impact placeholders.')
