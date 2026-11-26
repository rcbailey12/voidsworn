# Issue 1741 (R416): the one Wounds V2 switch every effects file reads. On by default since Ryan's yes on the Nov 24
# Morning Pick Sheet (item 5), after the before and after pictures. VS_WOUNDS_V2=0 (or false) still turns it off for a
# run, which now shows a plain neutral wound (the old faction looks are retired); the project setting
# rendering/effects/wounds_v2 can turn it off too.
static func v2() -> bool:
	var v := OS.get_environment("VS_WOUNDS_V2")
	if not v.is_empty():
		return v == "1" or v.to_lower() == "true"
	return bool(ProjectSettings.get_setting("rendering/effects/wounds_v2", true))
