class_name SeededRng
extends RefCounted
## A small seedable random number generator in our own code (xoshiro128**),
## so puzzle IDs never change if Godot's RandomNumberGenerator does.
##
## Only integer math is used, and every value is kept to 32 bits, so no
## operation can overflow GDScript's 64 bit int. The same seed gives the same
## sequence on every platform. Not for anything security related.

const MASK32: int = 0xFFFFFFFF
const GOLDEN: int = 0x9E3779B9

var _s0: int = 0
var _s1: int = 0
var _s2: int = 0
var _s3: int = 0


func _init(seed_value: int = 0) -> void:
	set_seed(seed_value)


## Starts the sequence again from seed_value. Every int is a valid seed,
## negative ones included; all 64 bits are used.
func set_seed(seed_value: int) -> void:
	var low: int = seed_value & MASK32
	var high: int = (seed_value >> 32) & MASK32
	var x: int = _fmix32(low ^ _fmix32(high ^ 0x5BD1E995))
	x = (x + GOLDEN) & MASK32
	_s0 = _fmix32(x)
	x = (x + GOLDEN) & MASK32
	_s1 = _fmix32(x)
	x = (x + GOLDEN) & MASK32
	_s2 = _fmix32(x)
	x = (x + GOLDEN) & MASK32
	_s3 = _fmix32(x)
	# The four words come from four different inputs to a bijection, so at
	# most one can be zero and the state is never all zero.


## The next value, 0 to 4294967295.
func next_u32() -> int:
	var result: int = _mul32(_rotl((_s1 * 5) & MASK32, 7), 9)
	var t: int = (_s1 << 9) & MASK32
	_s2 ^= _s0
	_s3 ^= _s1
	_s1 ^= _s2
	_s0 ^= _s3
	_s2 ^= t
	_s3 = _rotl(_s3, 11)
	return result


## A value from 0 to bound - 1, without modulo bias. bound must be 1 or more;
## a smaller bound returns 0.
func next_int(bound: int) -> int:
	if bound <= 1:
		return 0
	# Reject the top values that would make some results more likely.
	var span: int = MASK32 + 1
	var limit: int = span - span % bound
	var value: int = next_u32()
	while value >= limit:
		value = next_u32()
	return value % bound


## Shuffles values in place (Fisher-Yates).
func shuffle(values: PackedInt32Array) -> void:
	var i: int = values.size() - 1
	while i > 0:
		var j: int = next_int(i + 1)
		var swap: int = values[i]
		values[i] = values[j]
		values[j] = swap
		i -= 1


## Low 32 bits of a * b for 32 bit a and b. Splitting b in two 16 bit halves
## keeps every partial product under 2^48.
static func _mul32(a: int, b: int) -> int:
	return (a * (b & 0xFFFF) + (((a * (b >> 16)) & 0xFFFF) << 16)) & MASK32


static func _rotl(x: int, k: int) -> int:
	return ((x << k) | (x >> (32 - k))) & MASK32


## The MurmurHash3 finalizer: spreads every input bit over the output.
static func _fmix32(value: int) -> int:
	var h: int = value & MASK32
	h ^= h >> 16
	h = _mul32(h, 0x85EBCA6B)
	h ^= h >> 13
	h = _mul32(h, 0xC2B2AE35)
	h ^= h >> 16
	return h
