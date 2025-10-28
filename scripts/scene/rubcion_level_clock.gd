class_name RubiconLevelClock extends Resource

static func measure_to_millisecond(measure : float, bpm : float, time_signature_numerator : float) -> float:
	return measure * (60000.0 / (bpm / time_signature_numerator))

static func beats_to_millisecond(beat : float, bpm : float) -> float:
	return beat * (60000.0 / bpm)

static func steps_to_millisecond(step : float, bpm : float, time_signature_denominator : float) -> float:
	return step * (60000.0 / bpm / time_signature_denominator)

static func measure_to_beats(measure : float, time_signature_numerator : float) -> float:
	return measure * time_signature_numerator

static func measure_to_steps(measure : float, time_signature_numerator : float, time_signature_denominator : float) -> float:
	return beats_to_steps(measure_to_beats(measure, time_signature_numerator), time_signature_denominator)

static func beats_to_steps(beats : float, time_signature_denominator : float) -> float:
	return beats * time_signature_denominator

static func beats_to_measures(beats : float, time_signature_numerator : float) -> float:
	return beats / time_signature_numerator

static func steps_to_measures(steps : float, time_signature_numerator : float, time_signature_denominator : float) -> float:
	return steps / (time_signature_numerator * time_signature_denominator)
