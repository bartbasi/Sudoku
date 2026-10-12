extends "res://tests/unit_test.gd"
## The click sample: format, length, level, soft start and a silent end.

const FULL_SCALE: int = 32767


func _samples(stream: AudioStreamWAV) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var data: PackedByteArray = stream.data
	var count: int = data.size() / 2
	out.resize(count)
	for i: int in count:
		out[i] = data.decode_s16(i * 2)
	return out


func _peak(samples: PackedInt32Array, from: int, to: int) -> int:
	var best: int = 0
	for i: int in range(from, to):
		best = maxi(best, absi(samples[i]))
	return best


func test_format_is_16_bit_mono_one_shot() -> void:
	var stream: AudioStreamWAV = ClickSynth.build()
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "format")
	assert_eq(stream.mix_rate, 44100, "mix rate")
	assert_false(stream.stereo, "mono")
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_DISABLED, "no loop")
	assert_eq(stream.data.size() % 2, 0, "whole 16 bit samples")


func test_length_is_between_50_and_90_ms() -> void:
	for rate: int in [22050, 44100, 48000]:
		var stream: AudioStreamWAV = ClickSynth.build(rate)
		assert_eq(stream.mix_rate, rate, "mix rate %d" % rate)
		var ms: float = 1000.0 * float(stream.data.size() / 2) / float(rate)
		assert_true(ms >= 50.0 and ms <= 90.0, "length %.1f ms at %d Hz" % [ms, rate])
		assert_true(is_equal_approx(stream.get_length(), float(stream.data.size() / 2) / float(rate)), "get_length at %d Hz" % rate)


func test_peak_is_below_full_scale() -> void:
	var samples: PackedInt32Array = _samples(ClickSynth.build())
	var peak: int = _peak(samples, 0, samples.size())
	assert_true(peak < FULL_SCALE, "peak %d below full scale" % peak)
	# About minus 6 dBFS, so two overlapping clicks still cannot clip.
	assert_true(peak <= FULL_SCALE / 2, "peak %d at or below half scale" % peak)
	assert_true(peak >= FULL_SCALE / 4, "peak %d loud enough to hear" % peak)


func test_start_is_soft() -> void:
	var samples: PackedInt32Array = _samples(ClickSynth.build())
	var peak: int = _peak(samples, 0, samples.size())
	assert_eq(samples[0], 0, "first sample is silent")
	# The first half millisecond rises gently instead of jumping.
	var early: int = _peak(samples, 0, 22)
	assert_true(early < peak / 4, "first 0.5 ms peak %d is under a quarter of %d" % [early, peak])
	# Neighbouring samples near the start never jump hard.
	for i: int in range(1, 44):
		assert_true(absi(samples[i] - samples[i - 1]) < peak / 2, "no step at sample %d" % i)


func test_tail_ends_at_silence() -> void:
	var samples: PackedInt32Array = _samples(ClickSynth.build())
	var peak: int = _peak(samples, 0, samples.size())
	var last: int = samples.size() - 1
	assert_eq(samples[last], 0, "last sample is silent")
	var tail: int = _peak(samples, samples.size() - 44, samples.size())
	assert_true(tail < peak / 20, "last ms peak %d is under 5 percent of %d" % [tail, peak])


func test_decays_quickly() -> void:
	var samples: PackedInt32Array = _samples(ClickSynth.build())
	var peak: int = _peak(samples, 0, samples.size())
	var peak_at: int = 0
	for i: int in samples.size():
		if absi(samples[i]) == peak:
			peak_at = i
			break
	assert_true(peak_at < 441, "peak within the first 10 ms, at sample %d" % peak_at)
	var half: int = samples.size() / 2
	var second_half: int = _peak(samples, half, samples.size())
	assert_true(second_half < peak / 2, "second half peak %d well under %d" % [second_half, peak])


func test_same_output_every_build() -> void:
	assert_eq(ClickSynth.build().data, ClickSynth.build().data, "deterministic")
