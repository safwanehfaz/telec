#!/bin/bash

set -euo pipefail

BOT_TOKEN="${INPUT_BOT_TOKEN:-}"
CHAT_ID="${INPUT_CHAT_ID:-}"
FILE_PATH="${INPUT_FILE_PATH:-}"
TIMEOUT="${INPUT_TIMEOUT:-15}"
REQUEST_TEXT="${INPUT_REQUEST_TEXT:-Upload the build artifact?}"
FAIL_ON_NO="${INPUT_FAIL_ON_NO:-false}"

API_BASE="https://api.telegram.org/bot${BOT_TOKEN}"

require_input() {
	local name="$1"
	local value="$2"
	if [[ -z "$value" ]]; then
		echo "Missing required input: $name" >&2
		exit 1
	fi
}

json_get() {
	local json="$1"
	local expr="$2"
	python3 - "$expr" <<'PY' <<<"$json"
import json
import sys

expr = sys.argv[1]
data = json.load(sys.stdin)

# Supported forms:
#   key1.key2
#   key1.key2[0].key3
def get(obj, path):
		cur = obj
		for part in path.split('.'):
				if '[' in part and part.endswith(']'):
						name, idx = part[:-1].split('[', 1)
						cur = cur.get(name, []) if isinstance(cur, dict) else []
						cur = cur[int(idx)] if len(cur) > int(idx) else None
				else:
						cur = cur.get(part) if isinstance(cur, dict) else None
				if cur is None:
						return None
		return cur

value = get(data, expr)
if value is None:
		sys.exit(1)
if isinstance(value, bool):
		print("true" if value else "false")
else:
		print(value)
PY
}

telegram_post() {
	local method="$1"
	shift
	curl -sS --fail -X POST "${API_BASE}/${method}" "$@"
}

telegram_get() {
	local method="$1"
	shift
	curl -sS --fail "${API_BASE}/${method}" "$@"
}

write_output() {
	local key="$1"
	local val="$2"
	{
		echo "${key}=${val}"
	} >> "$GITHUB_OUTPUT"
}

require_input "bot_token" "$BOT_TOKEN"
require_input "chat_id" "$CHAT_ID"
require_input "file_path" "$FILE_PATH"

if [[ ! -f "$FILE_PATH" ]]; then
	echo "File does not exist: $FILE_PATH" >&2
	exit 1
fi

if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
	echo "timeout must be an integer (seconds). Got: $TIMEOUT" >&2
	exit 1
fi

NONCE="$(date +%s)$RANDOM"
YES_TOKEN="telec_yes_${NONCE}"
NO_TOKEN="telec_no_${NONCE}"

KEYBOARD_JSON=$(printf '[ [{"text":"Yes","callback_data":"%s"},{"text":"No","callback_data":"%s"}] ]' "$YES_TOKEN" "$NO_TOKEN")

send_resp=$(telegram_post "sendMessage" \
	--data-urlencode "chat_id=${CHAT_ID}" \
	--data-urlencode "text=${REQUEST_TEXT}" \
	--data-urlencode "reply_markup={\"inline_keyboard\":${KEYBOARD_JSON}}")

send_ok="false"
if send_ok_val=$(json_get "$send_resp" "ok" 2>/dev/null); then
	send_ok="$send_ok_val"
fi

if [[ "$send_ok" != "true" ]]; then
	echo "Failed to send approval message." >&2
	echo "$send_resp" >&2
	exit 1
fi

message_id=$(json_get "$send_resp" "result.message_id")
write_output "message_id" "$message_id"

offset=0
latest_resp=$(telegram_get "getUpdates?limit=1&timeout=0&allowed_updates=%5B%22callback_query%22%5D")
if latest_update_id=$(json_get "$latest_resp" "result[0].update_id" 2>/dev/null); then
	offset=$((latest_update_id + 1))
fi

decision="no"
status="timed_out"

for ((i = 1; i <= TIMEOUT; i++)); do
	updates_resp=$(telegram_get "getUpdates?offset=${offset}&timeout=1&allowed_updates=%5B%22callback_query%22%5D")

	mapfile -t parsed_rows < <(
		python3 - <<'PY' <<<"$updates_resp"
import json

payload = json.load(__import__('sys').stdin)
rows = []
for item in payload.get("result", []):
		update_id = item.get("update_id", "")
		cb = item.get("callback_query", {})
		data = cb.get("data", "")
		mid = cb.get("message", {}).get("message_id", "")
		rows.append(f"{update_id}\t{mid}\t{data}")
print("\n".join(rows))
PY
	)

	for row in "${parsed_rows[@]}"; do
		[[ -z "$row" ]] && continue
		IFS=$'\t' read -r upd_id upd_msg_id upd_data <<<"$row"
		if [[ -n "$upd_id" ]]; then
			offset=$((upd_id + 1))
		fi

		if [[ "$upd_msg_id" == "$message_id" ]]; then
			if [[ "$upd_data" == "$YES_TOKEN" ]]; then
				decision="yes"
				status="approved"
				break 2
			fi
			if [[ "$upd_data" == "$NO_TOKEN" ]]; then
				decision="no"
				status="declined"
				break 2
			fi
		fi
	done
done

if [[ "$status" == "timed_out" ]]; then
	final_text="Request timed out after ${TIMEOUT}s. Default decision: no."
elif [[ "$decision" == "yes" ]]; then
	final_text="Approval received. Uploading file now."
else
	final_text="Request declined. No file uploaded."
fi

# Replace old keyboard message so users do not click stale buttons later.
telegram_post "editMessageText" \
	--data-urlencode "chat_id=${CHAT_ID}" \
	--data-urlencode "message_id=${message_id}" \
	--data-urlencode "text=${final_text}" >/dev/null || true

if [[ "$decision" == "yes" ]]; then
	upload_resp=$(telegram_post "sendDocument" \
		-F "chat_id=${CHAT_ID}" \
		-F "document=@${FILE_PATH}" \
		-F "caption=Uploaded by GitHub Actions")

	upload_ok="false"
	if upload_ok_val=$(json_get "$upload_resp" "ok" 2>/dev/null); then
		upload_ok="$upload_ok_val"
	fi

	if [[ "$upload_ok" == "true" ]]; then
		status="uploaded"
	else
		status="upload_failed"
		echo "File upload failed." >&2
		echo "$upload_resp" >&2
	fi
fi

write_output "decision" "$decision"
write_output "status" "$status"

if [[ "$FAIL_ON_NO" == "true" && "$decision" != "yes" ]]; then
	echo "Action marked as failed because decision is '$decision'." >&2
	exit 1
fi

if [[ "$status" == "upload_failed" ]]; then
	exit 1
fi

