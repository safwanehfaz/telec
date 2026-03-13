# Example Workflows - Telegram Approval Upload

Copy and paste these workflow examples to quickly get started.

## Example 1: Basic Minimal Setup

A simple workflow that creates a file and asks for approval before uploading.

```yaml
name: Basic Telegram Upload

on:
  workflow_dispatch:

jobs:
  upload:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create artifact
        run: echo "Build timestamp=$(date)" > build-info.txt

      - name: Request approval
        id: approval
        uses: ./.github/actions/telec
        with:
          bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
          file_path: build-info.txt
          timeout: "15"
          request_text: "Upload build-info.txt?"

      - name: Show result
        run: |
          echo "Decision: ${{ steps.approval.outputs.decision }}"
          echo "Status: ${{ steps.approval.outputs.status }}"
```

## Example 2: Conditional Deployment

Proceed with deployment only if user approves via Telegram.

```yaml
name: Deployment with Approval

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build application
        run: |
          mkdir dist
          echo "app-v1.0" > dist/version.txt
          tar -czf release.tar.gz dist/

      - name: Ask for production deployment approval
        id: approval
        uses: ./.github/actions/telec
        with:
          bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
          file_path: release.tar.gz
          timeout: "30"
          request_text: "Deploy release.tar.gz to production?"
          fail_on_no: "false"

      - name: Deploy to production
        if: steps.approval.outputs.decision == 'yes'
        run: |
          echo "Deploying..."
          # ./deploy-prod.sh

      - name: Log rejection
        if: steps.approval.outputs.decision != 'yes'
        run: |
          echo "Deployment rejected or timed out"
          echo "Status was: ${{ steps.approval.outputs.status }}"
```

## Example 3: Strict Mode (Auto-Fail on Rejection)

Workflow fails immediately if user says no.

```yaml
name: Strict Deployment Gate

on:
  push:
    branches:
      - main

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate release notes
        run: echo "Release notes for v2.0" > notes.md

      - name: Require approval (fails if no)
        uses: ./.github/actions/telec
        with:
          bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
          file_path: notes.md
          timeout: "60"
          request_text: "Release v2.0? This action will fail if you say no."
          fail_on_no: "true"

      - name: Publish release
        run: echo "Publishing v2.0..."
```

## Example 4: Extended Timeout for Manual Review

Give users plenty of time to review and respond.

```yaml
name: Manual Review Needed

on:
  workflow_dispatch:

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create audit report
        run: |
          echo "Audit Report $(date)" > audit.log
          echo "Changes: " >> audit.log
          git log --oneline -10 >> audit.log 2>/dev/null || true

      - name: Request manual approval
        id: review
        uses: ./.github/actions/telec
        with:
          bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
          file_path: audit.log
          timeout: "600"  # 10 minutes
          request_text: "Review audit.log and approve? (10 minutes to respond)"

      - name: Process based on decision
        if: steps.review.outputs.decision == 'yes'
        run: echo "Manual review approved - proceeding..."

      - name: Abort on timeout or rejection
        if: steps.review.outputs.decision == 'no'
        run: |
          echo "Manual review was not completed or was rejected"
          exit 1
```

## Example 5: Multiple Files with Sequential Approvals

Ask for approval at multiple gates.

```yaml
name: Multi-Gate Approval

on:
  workflow_dispatch:

jobs:
  multi_approval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create build artifact
        run: |
          echo "Build artifact" > build.zip
          echo "Tests passed" > test-report.txt

      - name: Gate 1: Approve build upload
        id: gate1
        uses: ./.github/actions/telec
        with:
          bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
          file_path: build.zip
          timeout: "20"
          request_text: "[Gate 1/2] Upload build.zip?"

      - name: Gate 2: Approve test report upload
        id: gate2
        if: steps.gate1.outputs.decision == 'yes'
        uses: ./.github/actions/telec
        with:
          bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
          file_path: test-report.txt
          timeout: "20"
          request_text: "[Gate 2/2] Upload test-report.txt?"

      - name: Proceed if both approved
        if: steps.gate1.outputs.decision == 'yes' && steps.gate2.outputs.decision == 'yes'
        run: echo "Both gates approved!"
```

## Example 6: Quick Approval (Short Timeout)

For fast approval cycles.

```yaml
name: Quick Deploy

on:
  workflow_dispatch:

jobs:
  quick:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: echo "quick-build" > app.jar

      - name: 10-second approval
        uses: ./.github/actions/telec
        with:
          bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
          file_path: app.jar
          timeout: "10"
          request_text: "Quick deploy? (10 seconds)"
          fail_on_no: "true"

      - name: Deploy
        run: echo "Deploying..."
```

## Example 7: Custom Message Text

Personalize the approval request.

```yaml
name: Custom Messages

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Package
        run: tar -czf release.tar.gz *.md LICENSE

      - name: Ask approval with context
        uses: ./.github/actions/telec
        with:
          bot_token: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          chat_id: ${{ secrets.TELEGRAM_CHAT_ID }}
          file_path: release.tar.gz
          timeout: "30"
          request_text: |
            🚀 Ready to deploy release v1.5.0?
            ✅ All tests passed
            ✅ Security scan passed
            Click Yes to upload and deploy

      - name: Deploy
        run: echo "Deploying release.tar.gz..."
```

---

**Quick Copy-Paste Checklist:**

1. ✅ Create secrets: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`
2. ✅ Copy example code into `.github/workflows/your-workflow.yml`
3. ✅ Update `request_text` if needed
4. ✅ Adjust `timeout` as needed
5. ✅ Trigger workflow via `workflow_dispatch`
6. ✅ Check Telegram for the approval message
7. ✅ Click Yes/No and watch the workflow respond
