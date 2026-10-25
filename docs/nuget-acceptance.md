# Protected NuGet no-upload acceptance

Preparation for [issue #38](https://github.com/andregoepel/marten-testing/issues/38). This bundles registered workflow bindings, the protected rehearsal, the tagged artifact handoff and their offline regression tests. It does not activate publication, retire the legacy publisher, provision environments, transfer secrets or authorize a tag/release.

## Workflow state

| Workflow | Registered ID | Role and guard |
| --- | --- | --- |
| Sonar main readiness | 395675689 | Existing main analysis, unchanged |
| NuGet preparation | 395675685 | Acceptance tags only; test switch required |
| NuGet no-upload rehearsal | 395675688 | Manual main-only dispatch; test switch required |
| NuGet acceptance | 395675683 | Exact successful preparation; test switch required |
| NuGet verified publication | 395675687 | Unconditional false job guard retained |

All three test jobs require repository variable `SONAR_NUGET_ACCEPTANCE_ENABLED=true`. It was absent during preparation; missing/false skips them. No switch is set by this change. The publisher's only changes bind the registered preparation ID and its header; its disabled job and upload implementation remain unchanged.

The preparation trigger accepts only `sonar-poc/nuget/*/v*`, with strict runtime validation of `sonar-poc/nuget/<32 lowercase hex characters>/vX.Y.Z`. Release tags beginning `v` cannot enter this test path. The existing `ci.yml` tag trigger matches `v*` only, so an acceptance tag does not invoke its publisher. Never use a release tag for a test.

`nuget-policy.json` binds preparation ID 395675685 and the SHA-256 of its exact LF-normalized workflow bytes. Recalculate this hash after any subsequent preparation edit, including production trigger/guard changes. The existing publication target pins shared tooling to `752a04b788fd1cdb41e810ab62c184fe141d240a` and the repository's actual readiness ID.

Test jobs have only contents/actions read permissions and no OIDC access, NuGet login action or NuGet upload command. The acceptance job's fixed protocol step names mention login/push, but their implementations reject publication credentials, hash package bytes and read/discard them locally. GitHub evidence artifacts are not NuGet uploads.

## Offline validation

Run on Linux with Bash, jq, GNU coreutils, awk and a local temporary directory:

```bash
bash scripts/sonar/publication/tests/tagged-handoff.sh
bash scripts/sonar/publication/tests/outcomes.sh
bash scripts/sonar/publication/tests/outcomes.sh .github/workflows/nuget-acceptance.yml acceptance-outcomes
```

These tests execute the actual shipped event-check/recorder shell blocks with synthetic inputs and a stub GitHub CLI. They cover original lightweight/annotated tag events, changed/deleted/forced tags, wrong repository/workflow/revision, failed producers, reruns, stale main, production-context rejection, accidental credential channels and recorder failures. No network, Docker socket, credentials, real tags or service mutations are needed. The protected rehearsal also runs the pinned shared verifier's 1,086 offline tests.

## Protected runner procedure after review and merge

1. Obtain separate authorization for test environments, project-token copies, the test switch, the one non-release tag and cleanup. Do not infer authorization to copy tokens from the earlier `sonar-main` setup approval.
2. Verify exact merged-main CI/Sonar and live baseline/gate/profiles. Preserve and independently verify source/policy/contract/run/attempt/artifact fingerprints. Complete all tests within the 60-minute readiness and 120-minute CI/preparation windows. Record IDs before any refresh; request at most one CI rerun to produce fresh readiness when needed. Do not duplicate analyses.
3. Run repositories sequentially. Use the existing protected main-only `sonar-main` environment for the manual rehearsal without changing its protections or secrets. Temporarily create `sonar-nuget-prepare` with tag-only `sonar-poc/nuget/*/v*` access and `sonar-nuget-acceptance` with branch-only `main` access. Require `andregoepel` review, allow self-review for the sole operator and disable administrator bypass. Verify protection readback before tests. Copy only this project's existing scan/verification tokens to explicitly approved destinations; add no NuGet credential.
4. Enable the test switch only after the protections are verified. Dispatch the rehearsal once on exact main. Require all verifier/recorder/trigger tests, four expected pre-preparation rejections, real PostgreSQL tests and one verified `AndreGoepel.Marten.Testing.0.0.0.nupkg`/`.snupkg` batch. This is no-tag/no-upload evidence, not hosted handoff proof.
5. Before the tagged test, ensure there is **no previous acceptance workflow run for this exact SHA**, including skipped/failed runs. Both producer and consumer require attempt 1; stored intent requires exactly one consumer run. Never delete run history, rerun a consumer or weaken the invariant to get a green result.
6. Create one fresh lightweight acceptance tag on verified current main, with a random 32-character lowercase hex identifier and version `0.0.0`. Record the tag object and exact source before pushing. Approve only its matching protected preparation and resulting acceptance deployment. Do not create a GitHub Release or change tag/branch rules.
7. Require preparation's original event digest, verified source/tests/packages, authenticated origin and immutable batch. Require consumer rejection of a changed manifest and changed package, then successful verification of the original copies. Require the five stored-intent negatives: production context, rerun, changed content hash, changed archive digest and production-verifier invocation. Expected policy exit code 1 and the named boundary are required; crashes/timeouts are not successful negative evidence.
8. Require stored `acceptance-intent` before simulated login, fresh revalidation before every file, both successful local byte reads and retained `acceptance-outcomes`. Both artifacts must explicitly mark `acceptanceOnly=true`, `authorizesRetry=false` and no verified remote publication. `cli-success` denotes simulation only.
9. Before expiry, download origin/batch/intent/outcomes, verify archive IDs/digests and invoke the pinned verifier's `--nuget-inspect-acceptance` with the exact candidate, tag/object, preparation/consumer attempts and intent identities. Require `outcomesAvailable=true`, two successful simulated observations and false release/retry/remote-acceptance flags. Retain private evidence and a sanitized result.
10. Disable the test switch, remove only the recorded test tag and the two temporary environments/token copies under cleanup authorization, and verify no NuGet upload occurred. Preserve `sonar-main`. If expiry, source movement or any failure occurs, stop and retain evidence; a fresh scan cannot retroactively validate an old handoff. Seek a reviewed recovery plan instead of automatic retry.

This procedure does not claim a hosted annotated-tag test, central fault injection or a real publication. Offline cases cover those boundaries only within their stated scope.

## Package-to-policy migration proposal

| Field | Future exclusive publisher |
| --- | --- |
| Exact package | `AndreGoepel.Marten.Testing` |
| NuGet owner | `andre.goepel` |
| GitHub owner / repository | `andregoepel` / `marten-testing` |
| Workflow | `nuget-publish.yml` |
| Environment | `nuget-publish` |
| Scope | Push only new package versions, this exact package only |

The current `ci.yml` route remains unchanged and can publish without Sonar enforcement. Its retirement and the NuGet policy change require a separately reviewed migration; successful no-upload tests do not close that bypass. Keep raw private account audit evidence outside Git.

After no-upload acceptance, bundle legacy `pack-and-publish` removal, the production `v*` preparation trigger and updated policy hash in one standby PR where practical. Keep the real publisher disabled. Separately authorize the exact package policy move to the table above, exclusive route audit, production environments and tag-protection drill. Do not broaden package scopes or touch other repositories' policies.

Production `sonar-nuget-prepare` must admit `v*` tags only; production `nuget-publish` must admit `main` only. Both require operator review, self-approval allowed and no admin bypass. Test update/deletion rejection on disposable non-release tags before applying the reviewed `v*` immutability rule. The existing ruleset file is a disabled proposal, not a live control.

Only after those controls pass should a separate approved activation change remove the production guards and bind the new preparation hash. Any real release still needs explicit version/commit/tag authorization and fresh CI/Sonar. Do not reuse the old publisher as fallback or retry an ambiguous package/symbol result. External evidence storage remains deferred; GitHub artifact retention is finite.

## Sonar acceptance already verified

[Main CI 40180725243](https://github.com/andregoepel/marten-testing/actions/runs/40180725243/attempts/1) and [Sonar 40180784517](https://github.com/andregoepel/marten-testing/actions/runs/40180784517/attempts/1) passed after the covered-guard PR: 5/5 required tests, 100% overall coverage, zero findings/hotspots and **100% new-code coverage (2/2 executable lines)** against the unchanged accepted baseline. Sonar reports zero new conditions to cover; do not claim a measured branch-coverage percentage.

The local coverage-gate failure and exact-source recovery are verified separately. A protected-main gate rejection/recovery has not been exercised. Operator rollout acceptance remains open; historical readiness is not standing release authorization.
