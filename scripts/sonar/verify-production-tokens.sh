#!/usr/bin/env bash
# Read-only credential diagnostics; never submit an analysis or publication.
set -euo pipefail
set +x
umask 077
[[ $# -eq 1 && "$1" =~ ^marten-(testing|configuration)$ ]] || exit 2
project=$1
for name in ACTIONS_ID_TOKEN_REQUEST_TOKEN ACTIONS_ID_TOKEN_REQUEST_URL NUGET_API_KEY NUGET_SYMBOL_API_KEY NUGET_AUTH_TOKEN; do
  [[ -z "${!name:-}" ]] || { echo 'Unexpected publication credential channel' >&2; exit 1; }
done
for name in SONAR_SCAN_TOKEN SONAR_VERIFY_TOKEN; do
  [[ "${!name:-}" =~ ^squ_[a-f0-9]{40}$ ]] || { echo 'Missing or unexpected scoped user token' >&2; exit 1; }
done
[[ "$SONAR_SCAN_TOKEN" != "$SONAR_VERIFY_TOKEN" ]] || exit 1
workspace=$(mktemp -d)
trap 'rm -rf -- "$workspace"' EXIT
base=https://sonar.andregoepel.dev
request() {
  local token=$1 endpoint=$2 status
  # Feed the bearer header over stdin, never argv, logs or a config file.
  status=$(printf 'header = "Authorization: Bearer %s"\n' "$token" |
    curl --config - --silent --show-error --proto '=https' --tlsv1.2 \
      --connect-timeout 10 --max-time 30 --max-filesize 1048576 \
      --request GET --output "$workspace/response.json" --write-out '%{http_code}' \
      "$base/api/$endpoint") || { echo 'Sonar transport failed' >&2; return 1; }
  [[ "$status" =~ ^[0-9]{3}$ ]] || return 1
  printf '%s' "$status"
}
check_identity() {
  local token=$1 role=$2 status
  status=$(request "$token" authentication/validate)
  [[ "$status" == 200 ]] || { echo 'Authentication check failed' >&2; exit 1; }
  jq -e '.valid == true' "$workspace/response.json" > /dev/null 2>&1
  status=$(request "$token" users/current)
  [[ "$status" == 200 ]] || { echo 'Identity check failed' >&2; exit 1; }
  jq -e --arg login "$project-$role" '
    .isLoggedIn == true and .login == $login and
    (.permissions.global | type == "array" and length == 0) and
    (.groups | type == "array" and length == 1 and .[0] == "sonar-users")
  ' "$workspace/response.json" > /dev/null 2>&1
}
check_identity "$SONAR_SCAN_TOKEN" scanner
check_identity "$SONAR_VERIFY_TOKEN" verifier
status=$(request "$SONAR_VERIFY_TOKEN" "components/show?component=$project")
[[ "$status" == 200 ]] || { echo 'Project read check failed' >&2; exit 1; }
jq -e --arg project "$project" \
  '.component.key == $project and .component.qualifier == "TRK"' "$workspace/response.json" > /dev/null 2>&1
for other in app-foundation core marten-testing marten-configuration; do
  # The scanner has Execute Analysis only, without Browse on any private project.
  status=$(request "$SONAR_SCAN_TOKEN" "components/show?component=$other")
  [[ "$status" == 403 || "$status" == 404 ]] || { echo 'Unexpected scanner read access or service response' >&2; exit 1; }
  if [[ "$other" != "$project" ]]; then
    status=$(request "$SONAR_VERIFY_TOKEN" "components/show?component=$other")
    [[ "$status" == 403 || "$status" == 404 ]] || { echo 'Unexpected verifier cross-project access or service response' >&2; exit 1; }
  fi
done
printf 'PASS scoped scanner/verifier identity and private-project read boundaries: %s\n' "$project"
printf 'Read-only diagnostics only; analysis submission and NuGet OIDC/upload were not exercised.\n'
