# JS semantics for the rules port: the game's numbers are JavaScript doubles, its bit operations are 32-bit, and its Math functions are V8's.
# Everything here reproduces the exact JS result, so the port gives identical numbers on every platform:
#   - 32-bit integer ops (Math.imul, |0, >>>) on GDScript's 64-bit int
#   - the game's PRNG (mulberry32, core.js rnd)
#   - Math.round as V8 does it (ties toward +infinity), not GDScript's round (ties away from zero)
#   - Math.sin, cos, atan2, exp: V8 uses fdlibm, ported here line for line (checked against Node on 300,000 inputs: 0 differences)
#   - Math.hypot: V8's scaled Kahan sum
#   - a stable sort (Array.prototype.sort is stable; GDScript's sort_custom is not)
#   - the canonical state text and SHA-256 that the golden records use
# (loaded with preload, so it runs headless without an editor import)
extends RefCounted
# The JS port keeps JS shapes (untyped Dictionaries, JS-style numbers), so the untyped-code warnings are silenced for this file only.
# Of the six classes the project leaves on, three stay ON here and give 0 warnings (Oct 26, checked by turning them into errors):
# integer_division and narrowing_conversion (the JS-port number traps) and unsafe_property_access. The other three are silenced
# because they are the JS shapes themselves (35 call arguments, 4 method calls, 6 discarded results at Oct 26): unsafe_call_argument
# (Variant into a typed float), unsafe_method_access (calls on untyped values) and return_value_discarded (JS ignores results the same way).
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "shadowed_variable", "shadowed_variable_base_class", "shadowed_global_identifier", "unused_variable", "unused_parameter", "confusable_local_declaration", "confusable_local_usage", "return_value_discarded", "incompatible_ternary")

# Scratch bytes for the float-word conversions: a fresh 8-byte buffer per call, never a shared static one, so rules code may run on a
# worker thread (the battle API's step() and threat_map()) while the scene thread converts floats too (Oct 26 review: the old static
# buffer was a data race). Costs about 0.2 microseconds a call.
static func _pb8() -> PackedByteArray:
	var p := PackedByteArray(); p.resize(8); return p

# ---- doubles as words ----
static func hi(x: float) -> int:
	var p := _pb8(); p.encode_double(0, x); return p.decode_s32(4)
static func lo(x: float) -> int:
	var p := _pb8(); p.encode_double(0, x); return p.decode_u32(0)
static func words(h: int, l: int) -> float:
	var p := _pb8(); p.encode_s32(4, to_i32(h)); p.encode_u32(0, l & 0xFFFFFFFF); return p.decode_double(0)
static func hex64(x: float) -> String:
	var p := _pb8(); p.encode_double(0, x)
	var s := ""
	for i in range(7, -1, -1): s += "%02x" % p[i]
	return s
static func from_hex64(h: String) -> float:
	var p := _pb8()
	for i in range(8): p[7 - i] = h.substr(i * 2, 2).hex_to_int()
	return p.decode_double(0)

# ---- 32-bit integer semantics ----
static func to_u32(x: int) -> int:
	return x & 0xFFFFFFFF
static func to_i32(x: int) -> int:
	x = x & 0xFFFFFFFF
	return x - 0x100000000 if x >= 0x80000000 else x
static func imul(a: int, b: int) -> int: # Math.imul, as an unsigned 32-bit result
	a = a & 0xFFFFFFFF; b = b & 0xFFFFFFFF
	var ah := (a >> 16) & 0xFFFF; var al := a & 0xFFFF
	var bh := (b >> 16) & 0xFFFF; var bl := b & 0xFFFF
	return (al * bl + (((ah * bl + al * bh) & 0xFFFF) << 16)) & 0xFFFFFFFF
static func js_int(x: float) -> int: # ToInt32 of a double (x|0)
	if is_nan(x) or is_inf(x): return 0
	var t := int(x) # truncates toward zero; doubles here are far below 2^63
	return to_i32(t)

# ---- PRNG: core.js rndSeed / rnd (mulberry32) ----
static var rng_s: int = 0 # kept as JS keeps it: rndSeed stores s>>>0, rnd stores a signed 32-bit value
static func rnd_seed(s: int) -> void:
	rng_s = to_u32(s)
static func rnd() -> float:
	rng_s = to_i32(rng_s + 0x6D2B79F5)
	var a := to_u32(rng_s)
	var t := imul(a ^ (a >> 15), 1 | a)
	t = to_u32(t + imul(t ^ (t >> 7), 61 | t)) ^ t
	return float(to_u32(t ^ (t >> 14))) / 4294967296.0
static func rng_u32() -> int:
	return to_u32(rng_s)

# ---- Math.round (V8: ceil, then step back if that went more than half up) ----
static func jsround(x: float) -> float:
	if is_nan(x) or is_inf(x): return x
	var c := ceil(x)
	return c if c - 0.5 <= x else c - 1.0

# ---- fdlibm (V8 src/base/ieee754.cc) ----
# Unported maths branch: a hard stop, never a plausible number. The function returns NAN and sets not_ported; rules.gd's
# not_ported reads it, so the parity harness stops at the next record and the game's battle scene reports "NOT PORTED" (as for rules).
# Every fdlibm branch is ported except sin/cos of |x| > 2^19 pi (V8's __kernel_rem_pio2 big-argument reduction); the rules only pass angles.
static var not_ported := ""
static func _np(what: String) -> float:
	if not_ported == "": not_ported = "JSM " + what
	push_error("NOT PORTED: JSM " + what)
	return NAN
# fdlibm constants as exact IEEE words: Godot parses long decimal literals up to an ulp off (found Oct 25: 13 of them), so none are written as decimals
static var S1: float = words(0xBFC55555, 0x55555549)
static var S2: float = words(0x3F811111, 0x1110F8A6)
static var S3: float = words(0xBF2A01A0, 0x19C161D5)
static var S4: float = words(0x3EC71DE3, 0x57B1FE7D)
static var S5: float = words(0xBE5AE5E6, 0x8A2B9CEB)
static var S6: float = words(0x3DE5D93A, 0x5ACFD57C)
static var C1: float = words(0x3FA55555, 0x5555554C)
static var C2: float = words(0xBF56C16C, 0x16C15177)
static var C3: float = words(0x3EFA01A0, 0x19CB1590)
static var C4: float = words(0xBE927E4F, 0x809C52AD)
static var C5: float = words(0x3E21EE9E, 0xBDB4B1C4)
static var C6: float = words(0xBDA8FAE9, 0xBE8838D4)
static var INVPIO2: float = words(0x3FE45F30, 0x6DC9C883)
static var PIO2_1: float = words(0x3FF921FB, 0x54400000)
static var PIO2_1T: float = words(0x3DD0B461, 0x1A626331)
static var PIO2_2: float = words(0x3DD0B461, 0x1A600000)
static var PIO2_2T: float = words(0x3BA3198A, 0x2E037073)
static var PIO2_3: float = words(0x3BA3198A, 0x2E000000)
static var PIO2_3T: float = words(0x397B839A, 0x252049C1)
static var PI_O_2: float = words(0x3FF921FB, 0x54442D18)
static var PI_O_4: float = words(0x3FE921FB, 0x54442D18)
static var NEG_ZERO: float = words(0x80000000, 0)
static var PI_: float = words(0x400921FB, 0x54442D18)
static var PI_LO: float = words(0x3CA1A626, 0x33145C07)
static var INVLN2: float = words(0x3FF71547, 0x652B82FE)
static var P1: float = words(0x3FC55555, 0x5555553E)
static var P2: float = words(0xBF66C16C, 0x16BEBD93)
static var P3: float = words(0x3F11566A, 0xAF25DE2C)
static var P4: float = words(0xBEBBBD41, 0xC5D26BF1)
static var P5: float = words(0x3E663769, 0x72BEA4D0)
static var TWOM1000: float = words(0x01700000, 0x00000000)
static var TWO1023: float = words(0x7FE00000, 0x00000000)
static var EXP_OTH: float = words(0x40862E42, 0xFEFA39EF)
static var EXP_UTH: float = words(0xC0874910, 0xD52D3051)
static var EXP_E: float = words(0x4005BF0A, 0x8B145769)
static var EXP_HUGE: float = words(0x7E37E43C, 0x8800759C)
static var ATANHI: Array = [words(0x3FDDAC67, 0x0561BB4F), words(0x3FE921FB, 0x54442D18), words(0x3FEF730B, 0xD281F69B), words(0x3FF921FB, 0x54442D18)]
static var ATANLO: Array = [words(0x3C7A2B7F, 0x222F65E2), words(0x3C81A626, 0x33145C07), words(0x3C700788, 0x7AF0CBBD), words(0x3C91A626, 0x33145C07)]
static var AT: Array = [words(0x3FD55555, 0x5555550D), words(0xBFC99999, 0x9998EBC4), words(0x3FC24924, 0x920083FF), words(0xBFBC71C6, 0xFE231671), words(0x3FB745CD, 0xC54C206E), words(0xBFB3B0F2, 0xAF749A6D), words(0x3FB10D66, 0xA0D03D51), words(0xBFADDE2D, 0x52DEFD9A), words(0x3FA97B4B, 0x24760DEB), words(0xBFA2B444, 0x2C6A6C2F), words(0x3F90AD3A, 0xE322DA11)]
static var LN2HI: Array = [words(0x3FE62E42, 0xFEE00000), words(0xBFE62E42, 0xFEE00000)]
static var LN2LO: Array = [words(0x3DEA39EF, 0x35793C76), words(0xBDEA39EF, 0x35793C76)]
static func _ksin(x: float, y: float, iy: int) -> float:
	var ix := hi(x) & 0x7fffffff
	if ix < 0x3e400000:
		if js_int(x) == 0: return x
	var z := x * x; var v := z * x
	var r := S2 + z * (S3 + z * (S4 + z * (S5 + z * S6)))
	if iy == 0: return x + v * (S1 + z * r)
	return x - ((z * (0.5 * y - v * r) - y) - v * S1)
static func _kcos(x: float, y: float) -> float:
	var ix := hi(x) & 0x7fffffff
	if ix < 0x3e400000:
		if js_int(x) == 0: return 1.0
	var z := x * x
	var r := z * (C1 + z * (C2 + z * (C3 + z * (C4 + z * (C5 + z * C6)))))
	if ix < 0x3FD33333: return 1.0 - (0.5 * z - (z * r - x * y))
	var qx: float
	if ix > 0x3fe90000: qx = 0.28125
	else: qx = words(ix - 0x00200000, 0)
	var hz := 0.5 * z - qx; var a := 1.0 - qx
	return a - (hz - (z * r - x * y))
const NPIO2_HW := [0x3FF921FB,0x400921FB,0x4012D97C,0x401921FB,0x401F6A7A,0x4022D97C,0x4025FDBB,0x402921FB,0x402C463A,0x402F6A7A,0x4031475C,0x4032D97C,0x40346B9C,0x4035FDBB,0x40378FDB,0x403921FB,0x403AB41B,0x403C463A,0x403DD85A,0x403F6A7A,0x40407E4C,0x4041475C,0x4042106C,0x4042D97C,0x4043A28C,0x40446B9C,0x404534AC,0x4045FDBB,0x4046C6CB,0x40478FDB,0x404858EB,0x404921FB]
static func _rem_pio2(x: float, y: Array) -> int:
	var hx := hi(x); var ix := hx & 0x7fffffff
	var z: float; var w: float; var t: float; var r: float; var fn: float; var n: int; var i: int; var j: int
	if ix <= 0x3fe921fb:
		y[0] = x; y[1] = 0.0; return 0
	if ix < 0x4002d97c:
		if hx > 0:
			z = x - PIO2_1
			if ix != 0x3ff921fb:
				y[0] = z - PIO2_1T; y[1] = (z - y[0]) - PIO2_1T
			else:
				z -= PIO2_2; y[0] = z - PIO2_2T; y[1] = (z - y[0]) - PIO2_2T
			return 1
		else:
			z = x + PIO2_1
			if ix != 0x3ff921fb:
				y[0] = z + PIO2_1T; y[1] = (z - y[0]) + PIO2_1T
			else:
				z += PIO2_2; y[0] = z + PIO2_2T; y[1] = (z - y[0]) + PIO2_2T
			return -1
	if ix <= 0x413921fb:
		t = absf(x); n = js_int(t * INVPIO2 + 0.5); fn = float(n)
		r = t - fn * PIO2_1; w = fn * PIO2_1T
		if n < 32 and ix != NPIO2_HW[n - 1]:
			y[0] = r - w
		else:
			j = ix >> 20; y[0] = r - w; i = j - ((hi(y[0]) >> 20) & 0x7ff)
			if i > 16:
				t = r; w = fn * PIO2_2; r = t - w; w = fn * PIO2_2T - ((t - r) - w); y[0] = r - w; i = j - ((hi(y[0]) >> 20) & 0x7ff)
				if i > 49:
					t = r; w = fn * PIO2_3; r = t - w; w = fn * PIO2_3T - ((t - r) - w); y[0] = r - w
		y[1] = (r - y[0]) - w
		if hx < 0:
			y[0] = -y[0]; y[1] = -y[1]; return -n
		return n
	_np("sin/cos of |x| > 2^19 pi (big-argument reduction)"); y[0] = NAN; y[1] = NAN; return 0
static func sin(x: float) -> float:
	var ix := hi(x) & 0x7fffffff
	if ix <= 0x3fe921fb: return _ksin(x, 0.0, 0)
	if ix >= 0x7ff00000: return x - x
	var y := [0.0, 0.0]; var n := _rem_pio2(x, y)
	match n & 3:
		0: return _ksin(y[0], y[1], 1)
		1: return _kcos(y[0], y[1])
		2: return -_ksin(y[0], y[1], 1)
		_: return -_kcos(y[0], y[1])
static func cos(x: float) -> float:
	var ix := hi(x) & 0x7fffffff
	if ix <= 0x3fe921fb: return _kcos(x, 0.0)
	if ix >= 0x7ff00000: return x - x
	var y := [0.0, 0.0]; var n := _rem_pio2(x, y)
	match n & 3:
		0: return _kcos(y[0], y[1])
		1: return -_ksin(y[0], y[1], 1)
		2: return -_kcos(y[0], y[1])
		_: return _ksin(y[0], y[1], 1)
# named _atan: inside this script a bare atan() would call Godot's built-in (C library) atan instead (found Oct 25)
static func atan(x: float) -> float: return _atan(x)
static func _atan(x: float) -> float:
	var hx := hi(x); var ix := hx & 0x7fffffff; var id: int
	if ix >= 0x44100000:
		if ix > 0x7ff00000 or (ix == 0x7ff00000 and lo(x) != 0): return x + x
		return ATANHI[3] + ATANLO[3] if hx > 0 else -ATANHI[3] - ATANLO[3]
	if ix < 0x3fdc0000:
		if ix < 0x3e400000:
			if 1e300 + x > 1.0: return x
		id = -1
	else:
		x = absf(x)
		if ix < 0x3ff30000:
			if ix < 0x3fe60000:
				id = 0; x = (2.0 * x - 1.0) / (2.0 + x)
			else:
				id = 1; x = (x - 1.0) / (x + 1.0)
		else:
			if ix < 0x40038000:
				id = 2; x = (x - 1.5) / (1.0 + 1.5 * x)
			else:
				id = 3; x = -1.0 / x
	var z := x * x; var w := z * z
	var s1: float = z * (AT[0] + w * (AT[2] + w * (AT[4] + w * (AT[6] + w * (AT[8] + w * AT[10])))))
	var s2: float = w * (AT[1] + w * (AT[3] + w * (AT[5] + w * (AT[7] + w * AT[9]))))
	if id < 0: return x - x * (s1 + s2)
	var zz: float = ATANHI[id] - ((x * (s1 + s2) - ATANLO[id]) - x)
	return -zz if hx < 0 else zz
const TINY := 1e-300
static func atan2(y: float, x: float) -> float:
	if is_nan(x) or is_nan(y): return x + y
	var hx := hi(x); var ix := hx & 0x7fffffff; var lx := lo(x)
	var hy := hi(y); var iy := hy & 0x7fffffff; var ly := lo(y)
	if ((hx - 0x3ff00000) | lx) == 0: return _atan(y)
	var m := ((hy >> 31) & 1) | ((hx >> 30) & 2)
	if (iy | ly) == 0:
		match m:
			0, 1: return y
			2: return PI_ + TINY
			3: return -PI_ - TINY
	if (ix | lx) == 0: return -PI_O_2 - TINY if hy < 0 else PI_O_2 + TINY
	if ix == 0x7ff00000: # x is INF
		if iy == 0x7ff00000:
			match m:
				0: return PI_O_4 + TINY
				1: return -PI_O_4 - TINY
				2: return 3.0 * PI_O_4 + TINY
				_: return -3.0 * PI_O_4 - TINY
		else:
			match m:
				0: return 0.0
				1: return NEG_ZERO
				2: return PI_ + TINY
				_: return -PI_ - TINY
	if iy == 0x7ff00000: return -PI_O_2 - TINY if hy < 0 else PI_O_2 + TINY # y is INF
	var k := (iy - ix) >> 20; var z: float
	if k > 60:
		z = PI_O_2 + 0.5 * PI_LO; m &= 1
	elif hx < 0 and k < -60: z = 0.0
	else: z = _atan(absf(y / x))
	match m:
		0: return z
		1: return -z
		2: return PI_ - (z - PI_LO)
		_: return (z - PI_LO) - PI_
const HALF := [0.5, -0.5]
static func exp(x: float) -> float:
	var hx := to_u32(hi(x)); var xsb := (hx >> 31) & 1; hx &= 0x7fffffff
	var hi_ := 0.0; var lo_ := 0.0; var k := 0; var t: float; var c: float; var y: float
	if hx >= 0x40862E42: # |x| >= 709.78...
		if hx >= 0x7ff00000:
			if ((hx & 0xfffff) | lo(x)) != 0: return x + x # NaN
			return x if xsb == 0 else 0.0 # exp(+-inf) = {inf, 0}
		if x > EXP_OTH: return EXP_HUGE * EXP_HUGE # overflow
		if x < EXP_UTH: return TWOM1000 * TWOM1000 # underflow
	if hx > 0x3fd62e42:
		if hx < 0x3FF0A2B2:
			if x == 1.0: return EXP_E # V8 special-cases exp(1) (the reduction below gets its last bit wrong)
			hi_ = x - LN2HI[xsb]; lo_ = LN2LO[xsb]; k = 1 - xsb - xsb
		else:
			k = js_int(INVLN2 * x + HALF[xsb]); t = float(k); hi_ = x - t * LN2HI[0]; lo_ = t * LN2LO[0]
		x = hi_ - lo_
	elif hx < 0x3e300000:
		if 1e300 + x > 1.0: return 1.0 + x
	else: k = 0
	t = x * x; c = x - t * (P1 + t * (P2 + t * (P3 + t * (P4 + t * P5))))
	if k == 0: return 1.0 - ((x * c) / (c - 2.0) - x)
	y = 1.0 - ((lo_ - (x * c) / (2.0 - c)) - hi_)
	if k >= -1021:
		if k == 1024: return y * 2.0 * TWO1023
		return y * words(0x3FF00000 + (k << 20), 0)
	return y * words(0x3FF00000 + ((k + 1000) << 20), 0) * TWOM1000
# ---- Math.pow: V8 12.4 (the V8 in Node 22, the oracle) src/base/ieee754.cc pow, line for line; checked against Node ----
static var PW_DPH1: float = words(0x3FE2B803, 0x40000000)
static var PW_DPL1: float = words(0x3E4CFDEB, 0x43CFD006)
static var PW_L1: float = words(0x3FE33333, 0x33333303)
static var PW_L2: float = words(0x3FDB6DB6, 0xDB6FABFF)
static var PW_L3: float = words(0x3FD55555, 0x518F264D)
static var PW_L4: float = words(0x3FD17460, 0xA91D4101)
static var PW_L5: float = words(0x3FCD864A, 0x93C9DB65)
static var PW_L6: float = words(0x3FCA7E28, 0x4A454EEF)
static var PW_LG2: float = words(0x3FE62E42, 0xFEFA39EF)
static var PW_LG2H: float = words(0x3FE62E43, 0x00000000)
static var PW_LG2L: float = words(0xBE205C61, 0x0CA86C39)
static var PW_OVT: float = words(0x3C971547, 0x652B82FE)
static var PW_CP: float = words(0x3FEEC709, 0xDC3A03FD)
static var PW_CPH: float = words(0x3FEEC709, 0xE0000000)
static var PW_CPL: float = words(0xBE3E2FE0, 0x145B01F5)
static var PW_IVLN2: float = words(0x3FF71547, 0x652B82FE)
static var PW_IVLN2H: float = words(0x3FF71547, 0x60000000)
static var PW_IVLN2L: float = words(0x3E54AE0B, 0xF85DDF44)
static var PW_HUGE: float = words(0x7E37E43C, 0x8800759C)
static var PW_TINY: float = words(0x01A56E1F, 0xC2F8F359)
static var PW_THIRD: float = words(0x3FD55555, 0x55555555)
static func _sl(x: float, l: int) -> float: return words(hi(x), l)
static func _sh(x: float, h: int) -> float: return words(h, lo(x))
static func pow(x: float, y: float) -> float:
	var hx := hi(x); var lx := lo(x); var hy := hi(y); var ly := lo(y); var ix := hx & 0x7fffffff; var iy := hy & 0x7fffffff
	var z: float; var ax: float; var z_h: float; var z_l: float; var p_h: float; var p_l: float; var y1: float; var t1: float; var t2: float
	var r: float; var s: float; var t: float; var u: float; var v: float; var w: float; var i: int; var j: int; var k: int; var yisint: int; var n: int
	if (iy | ly) == 0: return 1.0
	if ix > 0x7ff00000 or (ix == 0x7ff00000 and lx != 0) or iy > 0x7ff00000 or (iy == 0x7ff00000 and ly != 0): return x + y
	yisint = 0
	if hx < 0:
		if iy >= 0x43400000: yisint = 2
		elif iy >= 0x3ff00000:
			k = (iy >> 20) - 0x3ff
			if k > 20:
				j = ly >> (52 - k)
				if ((j << (52 - k)) & 0xFFFFFFFF) == ly: yisint = 2 - (j & 1)
			elif ly == 0:
				j = iy >> (20 - k)
				if (j << (20 - k)) == iy: yisint = 2 - (j & 1)
	if ly == 0:
		if iy == 0x7ff00000:
			if ((ix - 0x3ff00000) | lx) == 0: return y - y
			elif ix >= 0x3ff00000: return y if hy >= 0 else 0.0
			else: return -y if hy < 0 else 0.0
		if iy == 0x3ff00000:
			return 1.0 / x if hy < 0 else x
		if hy == 0x40000000: return x * x
		if hy == 0x3fe00000 and hx >= 0: return sqrt(x)
	ax = absf(x)
	if lx == 0 and (ix == 0x7ff00000 or ix == 0 or ix == 0x3ff00000):
		z = ax
		if hy < 0: z = 1.0 / z
		if hx < 0:
			if ((ix - 0x3ff00000) | yisint) == 0: z = NAN
			elif yisint == 1: z = -z
		return z
	n = (hx >> 31) + 1
	if (n | yisint) == 0: return NAN
	s = 1.0
	if (n | (yisint - 1)) == 0: s = -1.0
	if iy > 0x41e00000: # |y| > 2^31
		if iy > 0x43f00000: # |y| > 2^64: must overflow or underflow
			if ix <= 0x3fefffff: return PW_HUGE * PW_HUGE if hy < 0 else PW_TINY * PW_TINY
			if ix >= 0x3ff00000: return PW_HUGE * PW_HUGE if hy > 0 else PW_TINY * PW_TINY
		if ix < 0x3fefffff: return s * PW_HUGE * PW_HUGE if hy < 0 else s * PW_TINY * PW_TINY
		if ix > 0x3ff00000: return s * PW_HUGE * PW_HUGE if hy > 0 else s * PW_TINY * PW_TINY
		t = ax - 1.0 # |1-x| <= 2^-20: log(x) by x - x^2/2 + x^3/3 - x^4/4
		w = (t * t) * (0.5 - t * (PW_THIRD - t * 0.25))
		u = PW_IVLN2H * t; v = t * PW_IVLN2L - w * PW_IVLN2
		t1 = _sl(u + v, 0); t2 = v - (t1 - u)
		return _pow_tail(y, t1, t2, s)
	n = 0
	if ix < 0x00100000:
		ax *= 9007199254740992.0; n -= 53; ix = hi(ax)
	n += (ix >> 20) - 0x3ff; j = ix & 0x000fffff; ix = j | 0x3ff00000
	if j <= 0x3988E: k = 0
	elif j < 0xBB67A: k = 1
	else:
		k = 0; n += 1; ix -= 0x00100000
	ax = _sh(ax, ix)
	var bpk := 1.5 if k == 1 else 1.0; var dph := PW_DPH1 if k == 1 else 0.0; var dpl := PW_DPL1 if k == 1 else 0.0
	u = ax - bpk; v = 1.0 / (ax + bpk); var ss := u * v; var s_h := _sl(ss, 0)
	var t_h := _sh(0.0, ((ix >> 1) | 0x20000000) + 0x00080000 + (k << 18)); var t_l := ax - (t_h - bpk); var s_l := v * ((u - s_h * t_h) - s_h * t_l)
	var s2 := ss * ss; r = s2 * s2 * (PW_L1 + s2 * (PW_L2 + s2 * (PW_L3 + s2 * (PW_L4 + s2 * (PW_L5 + s2 * PW_L6))))); r += s_l * (s_h + ss)
	s2 = s_h * s_h; t_h = _sl(3.0 + s2 + r, 0); t_l = r - ((t_h - 3.0) - s2)
	u = s_h * t_h; v = s_l * t_h + t_l * ss; p_h = _sl(u + v, 0); p_l = v - (p_h - u)
	z_h = PW_CPH * p_h; z_l = PW_CPL * p_h + p_l * PW_CP + dpl
	t = float(n); t1 = _sl((((z_h + z_l) + dph) + t), 0); t2 = z_l - (((t1 - t) - dph) - z_h)
	return _pow_tail(y, t1, t2, s)
# pow, from "split up y into y1+y2 and compute (y1+y2)*(t1+t2)" to the end (shared by both log branches)
static func _pow_tail(y: float, t1: float, t2: float, s: float) -> float:
	var z: float; var p_h: float; var p_l: float; var y1: float; var r: float; var t: float; var u: float; var v: float; var w: float
	var i: int; var j: int; var k: int; var n: int
	y1 = _sl(y, 0); p_l = (y - y1) * t1 + y * t2; p_h = y1 * t1; z = p_l + p_h; j = hi(z); i = lo(z)
	if j >= 0x40900000:
		if ((j - 0x40900000) | i) != 0: return s * PW_HUGE * PW_HUGE
		elif p_l + PW_OVT > z - p_h: return s * PW_HUGE * PW_HUGE
	elif (j & 0x7fffffff) >= 0x4090cc00:
		if ((j - to_i32(0xc090cc00)) | i) != 0: return s * PW_TINY * PW_TINY
		elif p_l <= z - p_h: return s * PW_TINY * PW_TINY
	i = j & 0x7fffffff; k = (i >> 20) - 0x3ff; n = 0
	if i > 0x3fe00000:
		n = j + (0x00100000 >> (k + 1)); k = ((n & 0x7fffffff) >> 20) - 0x3ff
		t = _sh(0.0, n & ~(0x000fffff >> k)); n = ((n & 0x000fffff) | 0x00100000) >> (20 - k)
		if j < 0: n = -n
		p_h -= t
	t = _sl(p_l + p_h, 0); u = t * PW_LG2H; v = (p_l - (t - p_h)) * PW_LG2 + t * PW_LG2L; z = u + v; w = v - (z - u)
	t = z * z; t1 = z - t * (P1 + t * (P2 + t * (P3 + t * (P4 + t * P5)))); r = (z * t1) / ((t1 - 2.0) - (w + z * w)); z = 1.0 - (r - z)
	j = hi(z) + (n << 20)
	if (j >> 20) <= 0: return s * scalbn(z, n) # subnormal output
	z = _sh(z, hi(z) + (n << 20))
	return s * z
# scalbn(x, n) = x * 2^n with one rounding (fdlibm s_scalbn.c; the same result as C's correctly rounded std::scalbn that V8 calls)
static var TWO54: float = words(0x43500000, 0)
static var TWOM54: float = words(0x3C900000, 0)
static func scalbn(x: float, n: int) -> float:
	var hx := hi(x); var lx := lo(x); var k := (hx & 0x7ff00000) >> 20
	if k == 0: # 0 or subnormal x
		if ((hx & 0x7fffffff) | lx) == 0: return x
		x *= TWO54; hx = hi(x); k = ((hx & 0x7ff00000) >> 20) - 54
		if n < -50000: return PW_TINY * x
	if k == 0x7ff: return x + x # NaN or Inf
	k = k + n
	if k > 0x7fe: return PW_HUGE * _copysign(PW_HUGE, x)
	if k > 0: return _sh(x, (hx & to_i32(0x800fffff)) | (k << 20))
	if k <= -54:
		if n > 50000: return PW_HUGE * _copysign(PW_HUGE, x)
		return PW_TINY * _copysign(PW_TINY, x)
	k += 54
	return _sh(x, (hx & to_i32(0x800fffff)) | (k << 20)) * TWOM54
static func _copysign(a: float, b: float) -> float: return absf(a) if hi(b) >= 0 else -absf(a)
static func hypot(a: Array) -> float: # V8 Math.hypot
	var mx := 0.0; var ab := []
	for v in a:
		var q := absf(float(v)); ab.append(q)
		if q > mx: mx = q
	if mx == 0.0: return 0.0
	var sum := 0.0; var comp := 0.0
	for v in ab:
		var n: float = v / mx; var s := n * n - comp; var p := sum + s
		comp = (p - sum) - s; sum = p
	return sqrt(sum) * mx

# ---- arrays ----
static func amin(a: Array) -> float: # Math.min(...a)
	var m := INF
	for v in a:
		if float(v) < m: m = float(v)
	return m
static func amax(a: Array) -> float:
	var m := -INF
	for v in a:
		if float(v) > m: m = float(v)
	return m
# stable merge sort with a JS-style comparator (negative, zero or positive)
static func ssort(a: Array, cmp: Callable) -> Array:
	var n := a.size()
	if n < 2: return a
	var src := a.duplicate(); var dst := src.duplicate(); var width := 1
	while width < n:
		var i := 0
		while i < n:
			var mid := mini(i + width, n); var end := mini(i + 2 * width, n); var l := i; var r := mid; var k := i
			while l < mid and r < end:
				if float(cmp.call(src[r], src[l])) < 0.0:
					dst[k] = src[r]; r += 1
				else:
					dst[k] = src[l]; l += 1
				k += 1
			while l < mid:
				dst[k] = src[l]; l += 1; k += 1
			while r < end:
				dst[k] = src[r]; r += 1; k += 1
			i += 2 * width
		var tmp := src; src = dst; dst = tmp; width *= 2
	for i in range(n): a[i] = src[i]
	return a
static func has_same(a: Array, x) -> bool: # Array.prototype.includes for objects (identity)
	for v in a:
		if typeof(v) == typeof(x) and is_same(v, x): return true
	return false
static func index_same(a: Array, x) -> int:
	for i in range(a.size()):
		if typeof(a[i]) == typeof(x) and is_same(a[i], x): return i
	return -1

# ---- canonical state text (identical rules to golden.js canon) ----
static func is_unit(v) -> bool:
	return v is Dictionary and v.has("id") and v.has("side") and v.has("hp") and v["id"] != null and v["side"] != null
static func num(v) -> String:
	var f := float(v)
	if f == floor(f) and absf(f) < 9007199254740992.0: return str(int(f))
	return "\"d:" + hex64(f) + "\""
static func jstr(s: String) -> String: # JSON.stringify for a string
	var o := "\""
	for ch in s:
		var c := ch.unicode_at(0)
		if ch == "\"": o += "\\\""
		elif ch == "\\": o += "\\\\"
		elif c == 8: o += "\\b"
		elif c == 12: o += "\\f"
		elif c == 10: o += "\\n"
		elif c == 13: o += "\\r"
		elif c == 9: o += "\\t"
		elif c < 0x20: o += "\\u%04x" % c
		else: o += ch
	return o + "\""
# plain=true: data tables (no ship references); otherwise a nested ship is written as "@id"
static func canon(v, top: String = "", skip: Dictionary = {}, plain: bool = false) -> String:
	if v == null: return "null"
	match typeof(v):
		TYPE_BOOL: return "true" if v else "false"
		TYPE_INT, TYPE_FLOAT: return num(v)
		TYPE_STRING, TYPE_STRING_NAME: return jstr(String(v))
		TYPE_ARRAY:
			var parts := PackedStringArray()
			for x in v: parts.append(canon(x, "", {}, plain))
			return "[" + ",".join(parts) + "]"
		TYPE_DICTIONARY:
			if top == "" and not plain and is_unit(v): return jstr("@" + String(v["id"]))
			var ks := []
			for k in v.keys():
				if v[k] == null or skip.has(k): continue
				if typeof(v[k]) == TYPE_CALLABLE: continue
				ks.append(String(k))
			ks.sort()
			var parts := PackedStringArray()
			for k in ks: parts.append(jstr(k) + ":" + canon(v[k], "", {}, plain))
			return "{" + ",".join(parts) + "}"
	return "null"
static func sha256(s: String) -> String:
	var h := HashingContext.new(); h.start(HashingContext.HASH_SHA256); h.update(s.to_utf8_buffer())
	return h.finish().hex_encode()
# Number to string as JS prints it in a template literal (Number.prototype.toString): integers without ".0",
# other values as the shortest decimal that reads back to the same double (fixed notation; the log never needs exponents).
static func numstr(x) -> String:
	if x is int: return str(x)
	if x is bool: return "true" if x else "false"
	var f := float(x)
	if is_nan(f): return "NaN"
	if is_inf(f): return "Infinity" if f > 0 else "-Infinity"
	if f == floor(f) and absf(f) < 9.0e18: return str(int(f))
	for d in range(1, 18):
		var s := String.num(f, d)
		if float(s) == f: return s
	return String.num(f, 17)
# String.prototype.replace with a string pattern: the first occurrence only
static func rep1(s: String, a: String, b: String) -> String:
	var i := s.find(a)
	return s if i < 0 else s.substr(0, i) + b + s.substr(i + a.length())
