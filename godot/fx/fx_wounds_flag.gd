# Issue 1741 (R416): the one Wounds V2 switch every effects file reads. VS_WOUNDS_V2=1 (or true) turns it on for a run;
# otherwise the project setting rendering/effects/wounds_v2 (default false until Ryan approves the real 3D captures).
static func v2() -> bool:
	var v := OS.get_environment("VS_WOUNDS_V2")
	if not v.is_empty():
		return v == "1" or v.to_lower() == "true"
	return bool(ProjectSettings.get_setting("rendering/effects/wounds_v2", false))
