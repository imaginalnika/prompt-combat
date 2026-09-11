extends RefCounted
class _Watcher:
	var key: String
	var kind: String
	var on_chunk: Callable
	var on_done: Callable
	var state: int = 0
	var value: Variant = null
var _buffer := ""
var _raw := ""
var _watchers: Array[_Watcher] = []
var _finished := false
func watch_string(key: String, on_chunk: Callable, on_done: Callable) -> void:
	var w := _Watcher.new()
	w.key = key
	w.kind = "string"
	w.on_chunk = on_chunk
	w.on_done = on_done
	w.value = ""
	_watchers.append(w)
func watch_array(key: String, on_done: Callable) -> void:
	var w := _Watcher.new()
	w.key = key
	w.kind = "array"
	w.on_done = on_done
	_watchers.append(w)
func watch_number(key: String, on_done: Callable) -> void:
	var w := _Watcher.new()
	w.key = key
	w.kind = "number"
	w.on_done = on_done
	_watchers.append(w)
func feed(chunk: String) -> void:
	if _finished:
		return
	_buffer += chunk
	_raw += chunk
	_progress()
func finish() -> void:
	if _finished:
		return
	_finished = true
	for w in _watchers:
		if w.state == 1 and w.kind == "string":
			w.state = 2
			if w.on_done.is_valid():
				w.on_done.call(str(w.value))
	var final_parse: Variant = _parse_final_json(_raw)
	if final_parse is Dictionary:
		for w in _watchers:
			if not final_parse.has(w.key):
				continue
			var v: Variant = final_parse[w.key]
			match w.kind:
				"string":
					var s := str(v)
					if str(w.value) != s:
						w.value = s
						if w.on_done.is_valid():
							w.on_done.call(s)
				"number":
					var n := _number_value(v)
					if float(w.value if w.value != null else 0) != n:
						w.value = n
						if w.on_done.is_valid():
							w.on_done.call(n)
				"array":
					var arr: Array = v if v is Array else []
					if w.value != arr:
						w.value = arr
						if w.on_done.is_valid():
							w.on_done.call(arr)
func _parse_final_json(text: String) -> Variant:
	var s := text.find("{")
	var e := text.rfind("}")
	if s < 0 or e <= s:
		return null
	return JSON.parse_string(text.substr(s, e - s + 1))
func _number_value(v: Variant) -> float:
	if v is float or v is int:
		return float(v)
	var s := str(v).strip_edges()
	return s.to_float() if s.is_valid_float() else 0.0
func _progress() -> void:
	var safety := 0
	while safety < 64:
		safety += 1
		var made := false
		for w in _watchers:
			if w.state == 1 and w.kind == "string":
				var before_len := _buffer.length()
				_progress_string(w)
				if _buffer.length() != before_len or w.state == 2:
					made = true
		var earliest = null
		var earliest_idx := -1
		for w in _watchers:
			if w.state != 0:
				continue
			var marker := '"%s":' % w.key
			var idx := _buffer.find(marker)
			if idx < 0:
				continue
			if earliest_idx == -1 or idx < earliest_idx:
				earliest_idx = idx
				earliest = w
		if earliest:
			if _process_state0(earliest, earliest_idx):
				made = true
		if not made:
			return
func _process_state0(w: _Watcher, idx: int) -> bool:
	var marker := '"%s":' % w.key
	var after := idx + marker.length()
	while after < _buffer.length() and _buffer[after] in [" ", "\t", "\n", "\r"]:
		after += 1
	if after >= _buffer.length():
		return false
	match w.kind:
		"string":
			if _buffer[after] != '"':
				return false
			w.state = 1
			w.value = ""
			_buffer = _buffer.substr(after + 1)
			_progress_string(w)
			return true
		"number":
			var prev_state := w.state
			_progress_number(w, after)
			return w.state != prev_state
		"array":
			if _buffer[after] != '[':
				return false
			var prev_state := w.state
			_progress_array(w, after)
			return w.state != prev_state
	return false
func _progress_string(w: _Watcher) -> void:
	var i := 0
	var found := false
	while i < _buffer.length():
		var c := _buffer[i]
		if c == "\\":
			if i + 1 < _buffer.length():
				var next := _buffer[i + 1]
				match next:
					"n": w.value = str(w.value) + "\n"
					"t": w.value = str(w.value) + "\t"
					"r": w.value = str(w.value) + "\r"
					"\"": w.value = str(w.value) + "\""
					"\\": w.value = str(w.value) + "\\"
					"/": w.value = str(w.value) + "/"
					_: w.value = str(w.value) + next
				i += 2
				continue
			else:
				break
		if c == '"':
			found = true
			break
		w.value = str(w.value) + c
		i += 1
	if found:
		_buffer = _buffer.substr(i + 1)
		w.state = 2
		if w.on_chunk.is_valid():
			w.on_chunk.call(str(w.value))
		if w.on_done.is_valid():
			w.on_done.call(str(w.value))
	else:
		_buffer = _buffer.substr(i)
		if w.on_chunk.is_valid():
			w.on_chunk.call(str(w.value))
func _progress_number(w: _Watcher, after: int) -> void:
	var quoted := false
	if after < _buffer.length() and _buffer[after] == '"':
		quoted = true
		after += 1
	var end := after
	while end < _buffer.length():
		var c := _buffer[end]
		if c in ["-", "+", ".", "e", "E"] or (c >= "0" and c <= "9"):
			end += 1
		else:
			break
	if end >= _buffer.length():
		return
	if quoted and _buffer[end] != '"':
		return
	var num_str := _buffer.substr(after, end - after).strip_edges()
	if num_str == "":
		return
	var num: float = num_str.to_float()
	w.state = 2
	w.value = num
	_buffer = _buffer.substr(end + (1 if quoted else 0))
	if w.on_done.is_valid():
		w.on_done.call(num)
func _progress_array(w: _Watcher, after: int) -> void:
	var depth := 0
	var in_str := false
	var escape := false
	var i := after
	while i < _buffer.length():
		var c := _buffer[i]
		if in_str:
			if escape:
				escape = false
			elif c == "\\":
				escape = true
			elif c == '"':
				in_str = false
		else:
			if c == '"':
				in_str = true
			elif c == "[":
				depth += 1
			elif c == "]":
				depth -= 1
				if depth == 0:
					break
		i += 1
	if i >= _buffer.length() or depth != 0:
		return
	var array_str := _buffer.substr(after, i - after + 1)
	var parsed = JSON.parse_string(array_str)
	w.state = 2
	w.value = parsed if parsed is Array else []
	_buffer = _buffer.substr(i + 1)
	if w.on_done.is_valid():
		w.on_done.call(w.value)
