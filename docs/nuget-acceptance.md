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

## Production migration status

The legacy publisher was retired in the merged standby change. The production
controls were subsequently installed and verified on 30 October 2026:

- Protected `sonar-nuget-prepare` (`v*` tags only) and `nuget-publish` (`main`
  branch only), operator review, self-approval allowed, administrator bypass off.
- Active immutable `v*` tag ruleset without bypass actors. Actual Git updates and
  deletions were rejected on isolated test tags; temporary resources were removed.
- The existing exact-package NuGet policy now trusts only `nuget-publish.yml`
  with environment `nuget-publish`, for new versions of the existing package.
  The authenticated account inventory showed no alternative API keys or
  overlapping Trusted Publisher policies for this package.

See [the operator migration record](nuget-production-migration.md) and the
sanitized [control snapshot](../scripts/sonar/publication/production-controls/verification.json).
These are historical acceptance records, not live readiness or release authority.

Both production jobs retain their unconditional false guards. The new production
environments contain no secrets. Credential placement, operator rollout acceptance
and a separate activation PR remain outstanding. Recheck effective `NUGET_USER`,
which already exists as a repository secret, without assuming its private value.
Activation requires a new preparation-workflow hash and fresh exact-main CI/Sonar.
No package publication or release tag is authorized by this change.

Protected-main rejection/recovery, hosted annotated-tag behavior, production NuGet
OIDC and remote package/symbol ingestion have not been established by the existing
no-upload tests. External archival remains deferred. Keep the tracking issue open.
If migration or verification fails, keep both production jobs disabled; never
restore the legacy publisher or retry an ambiguous upload without reconciliation.
