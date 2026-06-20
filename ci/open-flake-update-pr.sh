#!/usr/bin/env bash
set -euo pipefail

: "${CODEBERG_TOKEN:?CODEBERG_TOKEN is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${UPDATE_BRANCH:=ci/flake-lock-update}"
: "${REPORT_FILE:=.ci/flake-update-report.md}"

api="https://codeberg.org/api/v1"
title="Update flake.lock"

owner="${GITHUB_REPOSITORY%%/*}"
repo="${GITHUB_REPOSITORY#*/}"

if [ -s "$REPORT_FILE" ]; then
  body="$(cat "$REPORT_FILE")"
else
  body="Nightly flake input update. The CI job built normal NixOS host closures and found package closure changes."
fi

existing="$(
  curl -fsS \
    -H "Authorization: token ${CODEBERG_TOKEN}" \
    -H "Accept: application/json" \
    "${api}/repos/${owner}/${repo}/pulls?state=open" \
    | jq -r --arg branch "$UPDATE_BRANCH" '.[] | select(.head.ref == $branch) | .number' \
    | head -n 1
)"

if [ -n "$existing" ]; then
  action="updated"
  response="$(
    curl -fsS \
    -X PATCH \
    -H "Authorization: token ${CODEBERG_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -cn --arg title "$title" --arg body "$body" '{title: $title, body: $body}')" \
    "${api}/repos/${owner}/${repo}/pulls/${existing}"
  )"
else
  action="created"
  response="$(
    curl -fsS \
    -X POST \
    -H "Authorization: token ${CODEBERG_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -cn --arg title "$title" --arg head "$UPDATE_BRANCH" --arg base "main" --arg body "$body" '{title: $title, head: $head, base: $base, body: $body}')" \
    "${api}/repos/${owner}/${repo}/pulls"
  )"
fi

pr_number="$(jq -r '.number // empty' <<< "$response")"
pr_url="$(jq -r '.html_url // .url // empty' <<< "$response")"

echo "Pull request $action: ${pr_url:-#${pr_number}}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "pr_number=$pr_number" >> "$GITHUB_OUTPUT"
  echo "pr_url=$pr_url" >> "$GITHUB_OUTPUT"
  echo "pr_action=$action" >> "$GITHUB_OUTPUT"
fi

if [ -n "${HOME_ASSISTANT_WEBHOOK_URL:-}" ]; then
  curl -fsS \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$(
      jq -cn \
        --arg action "$action" \
        --arg repo "$GITHUB_REPOSITORY" \
        --arg title "$title" \
        --arg branch "$UPDATE_BRANCH" \
        --arg number "$pr_number" \
        --arg url "$pr_url" \
        '{
          event: "flake_update_pr",
          action: $action,
          repository: $repo,
          title: $title,
          branch: $branch,
          number: $number,
          url: $url
        }'
    )" \
    "$HOME_ASSISTANT_WEBHOOK_URL" \
    >/dev/null
else
  echo "HOME_ASSISTANT_WEBHOOK_URL is not set; skipping Home Assistant notification" >&2
fi
