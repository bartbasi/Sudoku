class_name ClickSynth
extends RefCounted
## Builds the one click sound in code. No audio files.
##
## The click is a short bright tone with a small upward pitch glide, which
## reads as positive. A raised cosine attack keeps the start soft, an
## exponential decay keeps it short, and a raised cosine fade lands the
## last sample on exactly zero so there is never a pop.

const LENGTH_SEC: float = 0.07
const ATTACK_SEC: float = 0.004
const FADE_SEC: float = 0.012
const DECAY_PER_SEC: float = 55.0
const START_HZ: float = 1650.0
const END_HZ: float = 1900.0
const OVERTONE_GAIN: float = 0.18
## Peak level as a fraction of full scale (about minus 6 dBFS). Two clicks
## overlapping still stay below full scale.
const PEAK: float = 0.45


static func build(mix_rate: int = 44100) -> AudioStreamWAV:
	var rate: int = maxi(mix_rate, 8000)
	var count: int = int(round(LENGTH_SEC * rate))
	var attack: int = maxi(1, int(round(ATTACK_SEC * rate)))
	var fade: int = maxi(1, int(round(FADE_SEC * rate)))

	var raw: PackedFloat32Array = PackedFloat32Array()
	raw.resize(count)
	var phase: float = 0.0
	var loudest: float = 0.0
	for i: int in count:
		var t: float = float(i) / rate
		var progress: float = float(i) / float(count - 1)
		var freq: float = lerpf(START_HZ, END_HZ, progress)
		var tone: float = sin(phase) + OVERTONE_GAIN * sin(2.0 * phase)
		phase += TAU * freq / rate

		var env: float = exp(-DECAY_PER_SEC * t)
		if i < attack:
			env *= 0.5 - 0.5 * cos(PI * float(i) / float(attack))
		var from_end: int = count - 1 - i
		if from_end < fade:
			env *= 0.5 - 0.5 * cos(PI * float(from_end) / float(fade))

		var value: float = tone * env
		raw[i] = value
		loudest = maxf(loudest, absf(value))

	var gain: float = PEAK / loudest if loudest > 0.0 else 0.0
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for i: int in count:
		var sample: int = clampi(int(round(raw[i] * gain * 32767.0)), -32767, 32767)
		data.encode_s16(i * 2, sample)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream
