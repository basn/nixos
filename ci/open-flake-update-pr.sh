#!/usr/bin/env bash
set -euo pipefail

: "${CODEBERG_TOKEN:?CODEBERG_TOKEN is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${UPDATE_BRANCH:=ci/flake-lock-update}"

api="https://codeberg.org/api/v1"
title="Update flake.lock"
body="Nightly flake input update. The CI job built normal NixOS host closures and found package closure changes."

owner="${GITHUB_REPOSITORY%%/*}"
repo="${GITHUB_REPOSITORY#*/}"

existing="$(
  curl -fsS \
    -H "Authorization: token ${CODEBERG_TOKEN}" \
    -H "Accept: application/json" \
    "${api}/repos/${owner}/${repo}/pulls?state=open" \
    | jq -r --arg branch "$UPDATE_BRANCH" '.[] | select(.head.ref == $branch) | .number' \
    | head -n 1
)"

if [ -n "$existing" ]; then
  curl -fsS \
    -X PATCH \
    -H "Authorization: token ${CODEBERG_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -cn --arg title "$title" --arg body "$body" '{title: $title, body: $body}')" \
    "${api}/repos/${owner}/${repo}/pulls/${existing}" \
    >/dev/null
else
  curl -fsS \
    -X POST \
    -H "Authorization: token ${CODEBERG_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -cn --arg title "$title" --arg head "$UPDATE_BRANCH" --arg base "main" --arg body "$body" '{title: $title, head: $head, base: $base, body: $body}')" \
    "${api}/repos/${owner}/${repo}/pulls" \
    >/dev/null
fi
