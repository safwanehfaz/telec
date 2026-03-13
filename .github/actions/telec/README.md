# Telegram Approval Upload Action

This composite action asks for Telegram approval with inline buttons (`Yes`/`No`).
It waits up to `timeout` seconds and defaults to `no` if no response arrives.

If decision is `yes`, it uploads `file_path` using `sendDocument`.

## Inputs

- `bot_token` (required): Telegram bot token.
- `chat_id` (required): Target chat ID.
- `file_path` (required): File path to upload when approved.
- `timeout` (optional, default: `15`): Wait duration in seconds.
- `request_text` (optional): Text shown in approval request.
- `fail_on_no` (optional, default: `false`): If `true`, action exits with failure when decision is not `yes`.

## Outputs

- `decision`: `yes` or `no`.
- `status`: `uploaded`, `declined`, `timed_out`, or `upload_failed`.
- `message_id`: Telegram message ID for the approval prompt.

## Example Workflow Usage

```yaml
name: Upload With Telegram Approval

on:
  workflow_dispatch:

jobs:
  upload:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create example artifact
        run: echo "hello" > build.txt

      - name: Ask Telegram and upload
        id: telec
        uses: ./.github/actions/telec
        with:
          bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
          file_path: build.txt
          timeout: "15"
          request_text: "Upload build.txt?"
          fail_on_no: "false"

      - name: Print result
        run: |
          echo "decision=${{ steps.telec.outputs.decision }}"
          echo "status=${{ steps.telec.outputs.status }}"
```
