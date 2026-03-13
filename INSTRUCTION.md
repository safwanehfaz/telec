# Telegram Approval Upload Action - Setup Guide

This document provides step-by-step instructions for using the Telegram Approval Upload composite action.

## What This Action Does

1. Sends an approval message to Telegram with `Yes/No` inline buttons
2. Waits up to `timeout` seconds (default: `15`) for user response
3. Automatically defaults to `no` if no response is received within the timeout
4. Uploads the specified file using Telegram's `sendDocument` if approved
5. Updates the original message with the final status

## Prerequisites

- A Telegram Bot Token (from BotFather)
- Target Telegram Chat ID
- A file path to upload (must exist during workflow execution)

## Step 1: Set Up GitHub Secrets

Go to **Repository Settings → Secrets and variables → Actions** and create:

- `TELEGRAM_BOT_TOKEN`: Your bot's API token
- `TELEGRAM_CHAT_ID`: The target chat ID

## Step 2: Configure Action Inputs

The action accepts the following inputs:

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `bot_token` | Yes | - | Telegram bot token |
| `chat_id` | Yes | - | Target chat ID |
| `file_path` | Yes | - | File path to upload if approved |
| `timeout` | No | `15` | Wait timeout in seconds |
| `request_text` | No | `Upload the build artifact?` | Message shown in approval request |
| `fail_on_no` | No | `false` | If `true`, workflow fails when decision is not `yes` |

## Step 3: Understand Action Outputs

The action produces three outputs:

- `decision`: Either `yes` or `no`
- `status`: One of `uploaded`, `declined`, `timed_out`, or `upload_failed`
- `message_id`: The Telegram message ID of the approval prompt

## Step 4: Basic Usage Pattern

1. Create/prepare your artifact or file
2. Use the `./.github/actions/telec` action
3. Pass required secrets and file path
4. Conditionally run subsequent steps based on outputs

## Step 5: Error Handling

| Scenario | Behavior |
|----------|----------|
| File doesn't exist | Action fails immediately |
| Telegram API error | Action fails with error details |
| User clicks `No` | `decision=no`, `status=declined` |
| Timeout expires | `decision=no`, `status=timed_out` |
| Upload fails | `status=upload_failed`, action fails |
| `fail_on_no=true` and decision is `no` | Workflow fails |

## Step 6: Security Best Practices

- ⚠️ Never hardcode bot tokens in your code
- Always use `${{ secrets.TELEGRAM_BOT_TOKEN }}`
- Store tokens in GitHub Secrets (encrypted at rest)
- Ensure the action runs in trusted contexts only

## Step 7: Debugging Tips

```yaml
- name: Debug outputs
  run: |
    echo "Decision: ${{ steps.telec.outputs.decision }}"
    echo "Status: ${{ steps.telec.outputs.status }}"
    echo "Message ID: ${{ steps.telec.outputs.message_id }}"
```

- Increase `timeout` to `30` or `60` seconds for testing
- Check Telegram bot permissions in the target chat
- Verify bot token is valid and not expired
- Ensure chat ID is correct (use `/start` with bot to see it in logs)

## Step 8: Common Use Cases

### Case 1: Gated Deployment
```yaml
- name: Wait for approval
  id: approve
  uses: safwanehfaz/telec@v1
  with:
    bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
    file_path: build.zip

- name: Deploy (only if approved)
  if: steps.approve.outputs.decision == 'yes'
  run: ./deploy.sh
```

### Case 2: Strict Mode (Fail on No)
```yaml
- name: Ask and proceed
  uses: safwanehfaz/telec@v1
  with:
    bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
    file_path: release.tar.gz
    fail_on_no: "true"
```

### Case 3: Long Timeout (Manual Approval Window)
```yaml
- name: Extended approval window
  uses: safwanehfaz/telec@v1
  with:
    bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
    file_path: artifact.zip
    timeout: "120"  # 2 minutes
    request_text: "Deploy to production? You have 2 minutes to respond."
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Action hangs for 15 seconds | Bot token may be invalid; check GitHub Secrets |
| "Failed to send approval message" | Verify chat ID and bot permissions |
| File does not exist | Ensure file is created before calling action |
| Button clicks don't register | Verify offset polling logic; check Telegram API updates |
