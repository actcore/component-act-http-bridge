# Open a session targeting the upstream ACT-HTTP host, exercise tools
# through it, then close. The session-id is captured from the open
# response and threaded into subsequent calls' metadata.

# 1. open-session args schema (driven by Config / schemars).
POST {{baseurl}}/sessions/open-args-schema
{}
HTTP 200
[Asserts]
jsonpath "$.type" == "object"
jsonpath "$.properties.url" exists

# 2. Open a session with the upstream URL.
POST {{baseurl}}/sessions
{"arguments": {"url": "{{upstream_url}}"}}
HTTP 201
[Asserts]
jsonpath "$.id" matches "act-http_\\d+"
[Captures]
session_id: jsonpath "$.id"

# 3. list-tools should now proxy to the upstream and surface its catalog.
POST {{baseurl}}/tools
{"metadata": {"std:session-id": "{{session_id}}"}}
HTTP 200
[Asserts]
jsonpath "$.tools" count >= 1
jsonpath "$.tools[*].name" contains "get_current_time"

# 4. call-tool through the bridge.
POST {{baseurl}}/tools/get_current_time
{"arguments": {}, "metadata": {"std:session-id": "{{session_id}}"}}
HTTP 200
[Asserts]
jsonpath "$.content[0].data" matches "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}"

# 5. With explicit timezone arg.
POST {{baseurl}}/tools/get_current_time
{"arguments": {"timezone": "Europe/Moscow"}, "metadata": {"std:session-id": "{{session_id}}"}}
HTTP 200
[Asserts]
jsonpath "$.content[0].data" matches "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}"

# 6. Unknown upstream tool — error surfaces through the bridge.
POST {{baseurl}}/tools/nonexistent_tool_xyz
{"arguments": {}, "metadata": {"std:session-id": "{{session_id}}"}}
HTTP *
[Asserts]
jsonpath "$.error" exists

# 7. Close the session.
DELETE {{baseurl}}/sessions/{{session_id}}
HTTP 204

# 8. Calls referencing the closed session-id surface std:session-not-found
# (mapped to 404 by act-types::http::error_kind_to_status).
POST {{baseurl}}/tools/get_current_time
{"arguments": {}, "metadata": {"std:session-id": "{{session_id}}"}}
HTTP 404
[Asserts]
jsonpath "$.error.kind" == "std:session-not-found"
