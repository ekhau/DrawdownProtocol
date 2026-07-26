class_name SeedUtil
## Deterministic sub-seed derivation (SplitMix64-style, engine-version-proof).
## Spec: docs/Phase_3/02_Procedural_Generation_Spec.md.
## Independent streams so regenerating one system never perturbs another.

const STREAM_WORLD := 1
const STREAM_EVENTS := 2
const STREAM_TILES := 3
const STREAM_NAMES := 4


static func sub_seed(base_seed: int, stream: int) -> int:
	var z: int = base_seed + stream * -0x61C8864680B583EB  # 0x9E3779B97F4A7C15 as signed
	z = (z ^ (z >> 30)) * -0x40A7B892E31B1A47              # 0xBF58476D1CE4E5B9
	z = (z ^ (z >> 27)) * -0x6B2FB644ECCEEE15              # 0x94D049BB133111EB
	return z ^ (z >> 31)
