# NuGet standby migration and no-upload acceptance

Tracking: [issue #38](https://github.com/andregoepel/marten-testing/issues/38). This revision removes the legacy CI publisher and prepares production tag handling without activating preparation or publishing.

## Standby behavior

| Workflow | Registered ID | State |
| --- | --- | --- |
| Sonar main readiness | 395675689 | Existing protected main analysis, unchanged |
| NuGet preparation | 395675685 | Production `v*` trigger; unconditional false job guard |
| NuGet no-upload rehearsal | 395675688 | Unchanged; absent test switch keeps it inactive |
| NuGet acceptance | 395675683 | Unchanged; absent test switch; nonrelease test tags only |
| NuGet verified publication | 395675687 | Unchanged; unconditional false job guard |

The `pack-and-publish` job is removed from `ci.yml`. Its existing build/test/audit path and triggers are unchanged. A future `v*` tag still runs CI, but this revision cannot prepare or publish packages. Merging this standby change deliberately pauses releases until separately approved activation. Do not create a release tag to test this state.

Preparation's future path accepts only strict stable `vX.Y.Z` tags, with no leading zeroes and at most five digits per component. Its event checks preserve original lightweight/annotated push evidence and reject updates, deletion, forced pushes, reruns, a different repository/workflow revision, branch/manual events and a commit that is no longer main. The reviewed verifier still requires fresh successful CI/Sonar and validates the tag object and package handoff.

`nuget-policy.json` binds preparation ID 395675685 and the SHA-256 of its exact LF-normalized workflow. `main-policy.json` updates only the CI file fingerprint required by legacy-job removal; mandatory CI steps, shared runner pin, accepted baseline and gate/profile policy remain unchanged. Recalculate the preparation hash again whenever its guard or contents change.

Preparation has contents/actions read permissions and no OIDC or NuGet credential. The unchanged real publisher uses official NuGet/login and native dotnet nuget push only after later activation. The no-upload consumer's login/push step names describe a simulation: it rejects publication credentials, hashes bytes and reads/discards files.

## Completed protected no-upload evidence

These original-attempt runs verified main `083395da7bf748d237bd6eb179610d7cb5eaaa51` before this standby change:

| Check | Successful run |
| --- | --- |
| Main CI | [40183957342, attempt 1](https://github.com/andregoepel/marten-testing/actions/runs/40183957342/attempts/1) |
| Sonar readiness | [40184021316, attempt 1](https://github.com/andregoepel/marten-testing/actions/runs/40184021316/attempts/1) |
| Protected rehearsal | [40184705200, attempt 1](https://github.com/andregoepel/marten-testing/actions/runs/40184705200/attempts/1) |
| Tagged preparation | [40185013636, attempt 1](https://github.com/andregoepel/marten-testing/actions/runs/40185013636/attempts/1) |
| Protected no-upload consumer | [40185155595, attempt 1](https://github.com/andregoepel/marten-testing/actions/runs/40185155595/attempts/1) |

Main Sonar passed all 5 required tests, including PostgreSQL tests, with 100% overall coverage, zero findings/hotspots and gate OK. New-code coverage was 100% (2/2 executable lines) against the unchanged accepted baseline. Zero new conditions to cover is not a measured branch-coverage percentage.

The rehearsal passed 1,086 pinned verifier tests, 49 workflow/event/credential/recorder cases and four expected pre-preparation rejections. The tagged consumer rejected changed manifest/package bytes, production context, a repeated attempt, changed intent content, changed archive digest and production-verifier invocation. The original evidence passed subsequent positive revalidation.

Origin, batch, intent and outcomes were retained privately and their GitHub archive digests verified. Independent inspection completed before readiness expiry and verified one `AndreGoepel.Marten.Testing.0.0.0.nupkg` and one `.snupkg` simulation: `acceptanceOnly=true`, `outcomesAvailable=true`, `releaseEligible=false`, `authorizesRetry=false`, `remoteAcceptanceVerified=false`. No upload or release occurred; the real publisher was skipped.

Temporary test environments, their approved token copies, the nonrelease test tag and repository switch were removed. Existing protections and package versions were unchanged. The historical test used a lightweight tag and does not prove hosted annotated-tag behavior, NuGet OIDC or remote package/symbol ingestion.

The old procedure is complete and is not executable on this standby revision: preparation no longer accepts `sonar-poc/nuget/*/v*`, and the retained acceptance consumer rejects production tags. Do not re-enable the test switch or recreate temporary environments to bypass this separation. A future hosted test requires its own reviewed plan; a fresh scan cannot retroactively validate an expired handoff.

## Offline verification of this revision

Run with Bash, jq, GNU coreutils and awk:

```bash
bash scripts/sonar/publication/tests/tagged-handoff.sh
bash scripts/sonar/publication/tests/outcomes.sh
bash scripts/sonar/publication/tests/outcomes.sh .github/workflows/nuget-acceptance.yml acceptance-outcomes
```

These tests extract the actual shipped workflow event-check/recorder blocks and execute them against synthetic events with a stub GitHub CLI. The updated event tests distinguish production producer/publisher tags from acceptance-consumer tags and cover invalid versions, original tag events, source/provenance, reruns and accidental publication credentials. They never run NuGet/login or a push command. No network, Docker socket, credentials, real tag or service mutation is needed.

Local Sonar analyzes the review branch on the separate prototype. The unchanged central workflow can verify the new CI/policy binding only after merge on exact main. Historical no-upload evidence is not standing release authorization.

## Remaining production migration

| Field | Proposed exclusive publisher |
| --- | --- |
| Exact package | `AndreGoepel.Marten.Testing` |
| NuGet owner | `andre.goepel` |
| GitHub owner / repository | `andregoepel` / `marten-testing` |
| Workflow | `nuget-publish.yml` |
| Environment | `nuget-publish` |
| Scope | Push new versions of this exact package only |

The previous read-only audit is retained privately. The existing NuGet policy still names `ci.yml`; this PR does not change it, credentials, live environments or tag rules. Removing the job from this revision does not revoke trust in historical workflow revisions or close every alternate publishing route. Complete the exclusive-route audit and policy migration before activation.

After review and merge:

1. Verify exact-main CI/Sonar against the unchanged accepted baseline and new CI file hash. Keep preparation and publishing disabled.
2. Separately authorize the exact package policy move above, remove obsolete/overlapping routes and recheck API-key alternatives. Preserve other packages and repositories.
3. Separately authorize production environments: `sonar-nuget-prepare` admits `v*` tags only; `nuget-publish` admits `main` only. Require operator review, allow sole-operator self-approval and disable administrator bypass. Credential placement needs explicit destination approval.
4. Prove update/deletion rejection on disposable nonrelease tags before applying reviewed `v*` tag protection. The ruleset file remains a disabled proposal.
5. Prepare a separate activation PR only after those controls pass. Remove the approved production guards and bind the changed preparation hash. A real release still requires explicit version/commit/tag approval and fresh CI/Sonar.

Keep both production jobs disabled if migration or validation fails. Do not restore the old publisher as fallback or retry an ambiguous package/symbol result. Preserve intent/outcome evidence for separately authorized recovery. External evidence storage remains deferred and GitHub artifact retention is finite.

Operator rollout acceptance remains open. Local coverage-gate failure/recovery passed separately; protected-main rejection/recovery has not been exercised. This standby change does not close the tracking issue.
