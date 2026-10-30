#!/usr/bin/env bash
# Exercise the shipped no-upload guard and receipt with offline GitHub fixtures.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
workspace=$(mktemp -d)
trap 'rm -rf -- "$workspace"' EXIT
mkdir "$workspace/bin"
export PATH="$workspace/bin:$PATH"
workflow="$root/.github/workflows/nuget-publish.yml"
extract() {
  awk -v name="$1" '
    $0 == "      - name: " name { inside = 1; next }
    inside && /^        run: \|$/ { code = 1; found = 1; next }
    code && /^          / { print substr($0, 11); next }
    code { exit }
    END { if (!found) exit 1 }
  ' "$workflow" > "$2"
}
extract 'Verify no-upload identity context' "$workspace/context.sh"
extract 'Record no-upload identity result' "$workspace/receipt.sh"
cat > "$workspace/bin/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 4 && "$1" == api && "$2" == "repos/$GITHUB_REPOSITORY/git/ref/heads/main" && "$3" == --jq && "$4" == .object.sha ]] || exit 90
printf '%s\n' "$FIXTURE_MAIN"
GH
chmod +x "$workspace/bin/gh"
repository="andregoepel/$(basename -- "$root")"
[[ "$repository" =~ ^andregoepel/marten-(testing|configuration)$ ]]
export GITHUB_REPOSITORY="$repository" GITHUB_EVENT_NAME=workflow_dispatch GITHUB_REF=refs/heads/main GITHUB_RUN_ATTEMPT=1
export GITHUB_SHA="$(printf 'a%.0s' {1..40})" GITHUB_RUN_ID=123
export GITHUB_WORKFLOW_SHA="$GITHUB_SHA" FIXTURE_MAIN="$GITHUB_SHA"
export GITHUB_WORKFLOW_REF="$repository/.github/workflows/nuget-publish.yml@refs/heads/main"
export GITHUB_STEP_SUMMARY="$workspace/summary" NUGET_USER=andre.goepel TEMPORARY_KEY=offline-key-must-never-be-recorded
run_case() {
  local name=$1 expected=$2 code=0
  shift 2
  "$@" > "$workspace/output" 2>&1 || code=$?
  if [[ "$expected" == pass && $code -ne 0 ]] || [[ "$expected" == reject && $code -eq 0 ]]; then
    printf 'FAIL %s (exit %s)\n' "$name" "$code" >&2; exit 1
  fi
  if grep -Fq -- "$TEMPORARY_KEY" "$workspace/output" "$GITHUB_STEP_SUMMARY" 2>/dev/null; then
    echo 'FAIL credential disclosure' >&2; exit 1
  fi
  printf 'PASS %s\n' "$name"
}
run_case original-main-context pass bash "$workspace/context.sh"
run_case wrong-username reject env NUGET_USER=unrelated bash "$workspace/context.sh"
run_case absent-username reject env -u NUGET_USER bash "$workspace/context.sh"
run_case wrong-repository reject env GITHUB_REPOSITORY=andregoepel/unrelated bash "$workspace/context.sh"
run_case production-event reject env GITHUB_EVENT_NAME=workflow_run bash "$workspace/context.sh"
run_case branch-context reject env GITHUB_REF=refs/heads/feature/probe bash "$workspace/context.sh"
run_case repeated-attempt reject env GITHUB_RUN_ATTEMPT=2 bash "$workspace/context.sh"
run_case changed-workflow reject env GITHUB_WORKFLOW_SHA="$(printf 'b%.0s' {1..40})" bash "$workspace/context.sh"
run_case wrong-workflow-path reject env GITHUB_WORKFLOW_REF="$repository/.github/workflows/ci.yml@refs/heads/main" bash "$workspace/context.sh"
run_case main-advanced-before-login reject env FIXTURE_MAIN="$(printf 'b%.0s' {1..40})" bash "$workspace/context.sh"
run_case original-receipt pass bash "$workspace/receipt.sh"
run_case no-issued-key reject env TEMPORARY_KEY= bash "$workspace/receipt.sh"
run_case main-advanced-after-login reject env FIXTURE_MAIN="$(printf 'b%.0s' {1..40})" bash "$workspace/receipt.sh"
grep -Fq -- "$GITHUB_SHA" "$GITHUB_STEP_SUMMARY"
