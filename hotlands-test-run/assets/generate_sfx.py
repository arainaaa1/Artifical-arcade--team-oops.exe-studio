"""Generate original, offline synthesized effects for GLITCH//FALL."""

import math
import random
import struct
import wave
from pathlib import Path


OUTPUT = Path(__file__).resolve().parent / "audio"
RATE = 22050
OUTPUT.mkdir(parents=True, exist_ok=True)


def envelope(time: float, duration: float, attack: float = 0.008, release: float = 0.04) -> float:
	if time < attack:
		return time / attack
	if time > duration - release:
		return max(0.0, (duration - time) / release)
	return 1.0


def glide_phase(start_hz: float, end_hz: float, time: float, duration: float) -> float:
	return math.tau * (start_hz * time + 0.5 * (end_hz - start_hz) * time * time / duration)


def write_sound(name: str, duration: float, render) -> None:
	frame_count = round(RATE * duration)
	pcm = bytearray()
	for index in range(frame_count):
		time = index / RATE
		sample = max(-0.95, min(0.95, render(time, duration)))
		pcm.extend(struct.pack("<h", round(sample * 32767)))
	with wave.open(str(OUTPUT / name), "wb") as audio_file:
		audio_file.setnchannels(1)
		audio_file.setsampwidth(2)
		audio_file.setframerate(RATE)
		audio_file.writeframes(pcm)
	print(OUTPUT / name)


def jump(time: float, duration: float) -> float:
	phase = glide_phase(300, 620, time, duration)
	return 0.24 * envelope(time, duration) * (math.sin(phase) + 0.2 * math.sin(phase * 2))


def gravity_flip(time: float, duration: float) -> float:
	phase = glide_phase(170, 720, time, duration)
	return 0.24 * envelope(time, duration) * (math.sin(phase) + 0.3 * math.sin(phase * 1.5))


def time_slow(time: float, duration: float) -> float:
	phase = glide_phase(760, 310, time, duration)
	return 0.22 * envelope(time, duration, 0.02, 0.12) * (
		math.sin(phase) + 0.35 * math.sin(phase * 1.503)
	)


def time_resume(time: float, duration: float) -> float:
	phase = glide_phase(280, 740, time, duration)
	return 0.18 * envelope(time, duration, 0.01, 0.09) * math.sin(phase)


def object_move(time: float, duration: float) -> float:
	phase = glide_phase(150, 72, time, duration)
	thump = math.sin(phase) + 0.22 * math.sin(phase * 2)
	click = math.sin(math.tau * 1300 * time) * math.exp(-time * 52)
	return envelope(time, duration, 0.002, 0.09) * (0.25 * thump + 0.10 * click)


def switch_click(time: float, duration: float) -> float:
	phase_a = math.tau * 660 * time
	phase_b = glide_phase(790, 980, time, duration)
	return 0.18 * envelope(time, duration, 0.002, 0.12) * (
		math.sin(phase_a) + 0.38 * math.sin(phase_b * 1.4)
	)


def portal(time: float, duration: float) -> float:
	u = time / duration
	phase = glide_phase(420, 110, time, duration)
	airy = math.sin(math.tau * 1700 * time) * (1.0 - u)
	return envelope(time, duration, 0.04, 0.14) * (
		0.18 * math.sin(phase) + 0.06 * airy
	)


def fahhh(time: float, duration: float) -> float:
	u = time / duration
	fundamental = 390 - 205 * u + 8 * math.sin(math.tau * 5 * time)
	phase = math.tau * fundamental * time
	formant = 0.75 + 0.25 * math.sin(math.tau * 2.1 * time)
	voice = sum(math.sin(phase * harmonic) / harmonic for harmonic in range(1, 8))
	breath = math.sin(math.tau * 1900 * time) * math.exp(-time * 18)
	voice_env = envelope(time, duration, 0.025, 0.20)
	return 0.19 * voice_env * formant * voice + 0.035 * breath


def win_wacky(time: float, duration: float) -> float:
	# A tiny synthetic brass fanfare that ends in a deliberately silly low wobble.
	notes = ((0.00, 0.22, 392, 330), (0.19, 0.42, 523, 475),
			 (0.39, 0.69, 659, 420), (0.72, 1.20, 190, 112))
	for start, end, first_hz, last_hz in notes:
		if start <= time <= end:
			local_time = time - start
			local_duration = end - start
			phase = glide_phase(first_hz, last_hz, local_time, local_duration)
			wobble = 1.0 + 0.035 * math.sin(math.tau * 6 * local_time)
			brass = math.sin(phase) + 0.45 * math.sin(phase * 2) + 0.2 * math.sin(phase * 3)
			return 0.20 * envelope(local_time, local_duration, 0.012, 0.055) * brass * wobble
	return 0.0


write_sound("jump.wav", 0.16, jump)
write_sound("gravity_flip.wav", 0.34, gravity_flip)
write_sound("time_slow.wav", 0.48, time_slow)
write_sound("time_resume.wav", 0.24, time_resume)
write_sound("object_move.wav", 0.15, object_move)
write_sound("switch.wav", 0.22, switch_click)
write_sound("portal.wav", 0.32, portal)
write_sound("death_fahhh.wav", 0.56, fahhh)
write_sound("win_wacky.wav", 1.20, win_wacky)
