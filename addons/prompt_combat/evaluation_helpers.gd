extends RefCounted

static func normalize_rate_eval(raw: Dictionary) -> Dictionary:
	return {
		"success_rate": clampi(int(raw.get("success_rate", 50)), 0, 100),
		"cot": str(raw.get("cot", "")).strip_edges(),
	}

static func filter_spans(raw_spans, source: String) -> Array:
	var spans := []
	if raw_spans is Array:
		for s in raw_spans:
			var span := str(s).strip_edges()
			if span != "" and source.find(span) >= 0 and not spans.has(span):
				spans.append(span)
	return spans

static func _parse_brace_window(text: String) -> Variant:
	var start := text.find("{")
	var end := text.rfind("}")
	if start >= 0 and end > start:
		return JSON.parse_string(text.substr(start, end - start + 1))
	return null

static func _salvage_field(text: String, field: String) -> String:
	var parsed: Variant = _parse_brace_window(text)
	if parsed is Dictionary and not parsed.is_empty():
		return str(parsed.get(field, parsed.values()[0])).strip_edges()
	return text.replace("```", "").replace("{", "").replace("}", "").strip_edges()

static func _split_pages(text: String, limit: int) -> Array:
	var re := RegEx.new()
	re.compile("[^.!?…~\\n]+[.!?…~]*")
	var sentences: Array = []
	for m in re.search_all(text):
		var s := m.get_string().strip_edges()
		if s != "":
			sentences.append(s)
	if sentences.is_empty():
		return [text]
	var pages: Array = []
	var cur := ""
	for s in sentences:
		var joined: String = s if cur == "" else cur + "\n" + s
		if cur != "" and joined.length() > limit:
			pages.append(cur)
			cur = s
		else:
			cur = joined
	if cur != "":
		pages.append(cur)
	return pages
