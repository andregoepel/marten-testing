#!/usr/bin/env bash
# Exercise real credential diagnostics with HTTP fixtures and no external access.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
probe="$root/scripts/sonar/verify-production-tokens.sh"
workspace=$(mktemp -d)
trap 'rm -rf -- "$workspace"' EXIT
mkdir "$workspace/bin"
export PATH="$workspace/bin:$PATH"
export SONAR_SCAN_TOKEN="squ_$(printf 'a%.0s' {1..40})"
export SONAR_VERIFY_TOKEN="squ_$(printf 'b%.0s' {1..40})"
export PROBE_PROJECT=marten-testing
unset ACTIONS_ID_TOKEN_REQUEST_TOKEN ACTIONS_ID_TOKEN_REQUEST_URL NUGET_API_KEY NUGET_SYMBOL_API_KEY NUGET_AUTH_TOKEN
cat > "$workspace/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
config=$(cat)
[[ "$config" == 'header = "Authorization: Bearer '* ]] || exit 90
role=scanner
[[ "$config" != *"$SONAR_VERIFY_TOKEN"* ]] || role=verifier
output='' url='' method=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config|--proto|--tlsv1.2|--connect-timeout|--max-time|--max-filesize|--write-out)
      if [[ "$1" == --tlsv1.2 ]]; then shift; else shift 2; fi ;;
    --request) method=$2; shift 2 ;;
    --output) output=$2; shift 2 ;;
    --silent|--show-error) shift ;;
    https://*) url=$1; shift ;;
    *) exit 91 ;;
  esac
done
[[ "$method" == GET && "$url" == https://sonar.andregoepel.dev/api/* && -n "$output" ]] || exit 92
[[ "${FIXTURE:-pass}" != transport ]] || exit 7
status=200
case "$url" in
  */authentication/validate)
    body='{"valid":true}'
    case "${FIXTURE:-pass}" in
      invalid) body='{"valid":false}' ;;
      auth-http) status=401 ;;
      malformed) body='not-json' ;;
      redirect) status=302 ;;
    esac ;;
  */users/current)
    login="$PROBE_PROJECT-$role"; permissions='[]'; groups='["sonar-users"]'
    case "${FIXTURE:-pass}" in
      identity-http) status=401 ;;
      wrong-identity) login='admin' ;;
      global-permission) permissions='["admin"]' ;;
      admin-group) groups='["sonar-users","sonar-administrators"]' ;;
      anonymous) status=403 ;;
    esac
    body=$(printf '{"isLoggedIn":true,"login":"%s","permissions":{"global":%s},"groups":%s}' "$login" "$permissions" "$groups")
    if [[ "${FIXTURE:-pass}" == missing-global-fields ]]; then body=$(printf '{"isLoggedIn":true,"login":"%s","groups":["sonar-users"]}' "$login"); fi ;;
  */components/show\?component=*)
    target="${url##*=}"
    status=403
    [[ "$role" != verifier || "$target" != "$PROBE_PROJECT" ]] || status=200
    case "${FIXTURE:-pass}" in
      missing-project) [[ "$target" != "$PROBE_PROJECT" ]] || status=404 ;;
      wrong-project-key) target=wrong ;;
      scanner-browse) [[ "$role" != scanner ]] || status=200 ;;
      cross-project) [[ "$role" != verifier ]] || status=200 ;;
      service-error) status=503 ;;
    esac
    body=$(printf '{"component":{"key":"%s","qualifier":"TRK"}}' "$target") ;;
  *) exit 93 ;;
esac
printf '%s' "$body" > "$output"
printf '%s' "$status"
STUB
chmod +x "$workspace/bin/curl"
run_case() {
  local name=$1 expected=$2 code=0
  shift 2
  "$@" > "$workspace/result" 2>&1 || code=$?
  if [[ "$expected" == pass && $code -ne 0 ]] || [[ "$expected" == reject && $code -eq 0 ]]; then
    printf 'FAIL %s (exit %s)\n' "$name" "$code" >&2; exit 1
  fi
  if grep -Fq -e "$SONAR_SCAN_TOKEN" -e "$SONAR_VERIFY_TOKEN" "$workspace/result"; then
    echo 'FAIL credential leaked to diagnostic output' >&2; exit 1
  fi
  printf 'PASS %s\n' "$name"
}
for project in marten-testing marten-configuration; do
  run_case "valid-$project" pass env FIXTURE=pass PROBE_PROJECT="$project" bash "$probe" "$project"
done
for scenario in invalid auth-http malformed redirect transport identity-http wrong-identity global-permission admin-group anonymous missing-project wrong-project-key scanner-browse cross-project service-error missing-global-fields; do
  run_case "$scenario" reject env FIXTURE="$scenario" bash "$probe" marten-testing
done
run_case missing-scanner reject env -u SONAR_SCAN_TOKEN bash "$probe" marten-testing
run_case missing-verifier reject env -u SONAR_VERIFY_TOKEN bash "$probe" marten-testing
run_case same-credential reject env SONAR_VERIFY_TOKEN="$SONAR_SCAN_TOKEN" bash "$probe" marten-testing
run_case unexpected-token-type reject env SONAR_SCAN_TOKEN="sqp_$(printf 'a%.0s' {1..40})" bash "$probe" marten-testing
run_case invalid-project reject bash "$probe" unrelated
for channel in ACTIONS_ID_TOKEN_REQUEST_TOKEN ACTIONS_ID_TOKEN_REQUEST_URL NUGET_API_KEY NUGET_SYMBOL_API_KEY NUGET_AUTH_TOKEN; do
  run_case "$channel" reject env "$channel=forbidden" bash "$probe" marten-testing
done
