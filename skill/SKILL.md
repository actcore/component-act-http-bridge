---
name: act-http-bridge
description: Proxies a remote ACT-HTTP server's tools as local ACT tools
metadata:
  act: {}
---

# act-http-bridge

Proxies a remote ACT-HTTP server's tools as local ACT tools.

## How sessions work here

This component requires a session. Open one against the upstream you
want to proxy, then thread the returned id into every tool call as
`std:session-id` metadata.

Open-session args:

| field | type | required | description |
| --- | --- | --- | --- |
| `url` | string | yes | Base URL of the upstream ACT-HTTP host (e.g. `http://localhost:3000`) |
| `headers` | object | no | Default headers to add to every upstream request — typically auth |

Without `std:session-id`, `list-tools` returns an empty list and
`call-tool` errors with `std:invalid-args`.

## Example

```text
open_session({"url": "http://localhost:3000"})
→ {"id": "act-http_0", "metadata": {}}

list_tools(_meta = {std:session-id: "act-http_0"})
→ tools advertised by the upstream

call_tool("get_current_time", {}, _meta = {std:session-id: "act-http_0"})
→ "2026-05-06T20:36:05.699507800+00:00"

close_session("act-http_0")
```
