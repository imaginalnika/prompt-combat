extends Node
## OpenAI-compatible chat-completions endpoint. No account or model defaults.
var endpoint := ""
var api_key := ""
var model := ""
var timeout_seconds := 30.0

func judge(system: String, messages: Array, _kind: String) -> Dictionary:
	if endpoint == "" or model == "": return {}
	if not endpoint.begins_with("https://") and not endpoint.begins_with("http://localhost:") and not endpoint.begins_with("http://127.0.0.1:"): return {}
	var http := HTTPRequest.new()
	http.timeout = timeout_seconds
	add_child(http)
	var headers := ["Content-Type: application/json"]
	if api_key != "": headers.append("Authorization: Bearer " + api_key)
	var history := [{"role": "system", "content": system}] + messages.duplicate(true)
	var error := http.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify({"model": model, "messages": history, "stream": false}))
	if error != OK:
		http.queue_free()
		return {}
	var response: Array = await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200: return {}
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	if not data is Dictionary or not data.get("choices") is Array or data["choices"].is_empty(): return {}
	var text := str(data["choices"][0].get("message", {}).get("content", ""))
	var parsed = preload("evaluation_helpers.gd")._parse_brace_window(text)
	return parsed if parsed is Dictionary else {}
