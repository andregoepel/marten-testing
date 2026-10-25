# Sonar and NuGet gate preparation

Tracking: [38](https://github.com/andregoepel/marten-testing/issues/38), [rollout epic](https://github.com/andregoepel/app-foundation/issues/238).

## Current boundary

The private central project and frozen Marten Library 1.0.0 gate/profiles are
configured. This follow-up binds the exact profile inventory and registered Sonar
workflow ID, and removes only the Sonar job's standby guard. Analysis still needs
SONAR_MAIN_ENABLED=true and operator approval in the main-only sonar-main
environment. Self-approval is allowed; administrator bypass is disabled. The opt-in
remains false during preparation, so merging alone does not start an analysis.

All four NuGet preparation/publication/rehearsal/acceptance jobs remain
unconditionally disabled. The existing tag publisher remains active and outside
Sonar enforcement until its separately reviewed retirement. Do not create a tag
as a test: the existing publisher would execute. No baseline has been selected and
no production publishing migration or activation is included in this change.

One production library and one PostgreSQL-backed test project (4 tests).

The SDK is selected exactly by global.json (10.0.402); CSharpier 1.3.0 remains the
formatting authority. Existing test projects already use Microsoft.Testing.Platform.
SonarScanner 12.0.0 and dotnet-coverage 18.12.0 are pinned. The shared analysis and
publication verifier use immutable revision
752a04b788fd1cdb41e810ab62c184fe141d240a. Their existing test discovery, full-project
coverage merge, policy/provenance checks and official tools are reused; this repo
adds no Sonar/GitHub client or upload adapter.

The packable fixture project explicitly sets SonarQubeTestProject=false. Its xUnit
dependency is part of the shipped fixture API; classifying it as tests would hide
production coverage. The actual test project remains test code.

## Local verification

Use .NET SDK 10.0.402, PowerShell 7, Git and Docker with Linux containers. The test
fixtures create their own pinned PostgreSQL containers and clean them up through
Testcontainers. Docker must also be available to child test processes during the
coverage run; a passing unit-only run does not cover the integration project.
On Linux, the runner needs its normal Docker access. Do not disable the resource
reaper, skip database tests, substitute mocked storage or add coverage exclusions.

```powershell
dotnet tool restore
dotnet csharpier format .
dotnet restore --locked-mode
dotnet build --no-restore -c Release
dotnet test --no-build -c Release
dotnet list package --vulnerable --include-transitive
./scripts/sonar/analyze.ps1 -ServerId '<local server ID>' -RunName 'review-01'
```

The final command requires the separate Sonar prototype at http://127.0.0.1:9000,
a private marten-testing-local project, the reviewed Marten Library 1.0.0 gate/profiles,
and WORKFLOWS_SONAR_TOKEN / WORKFLOWS_SONAR_VERIFY_TOKEN supplied through protected
process environment variables. Never paste values into shell commands, docs or
artifacts. The wrapper refuses the central server identity and non-loopback URLs,
fetches/builds the immutable runner before restoring credentials, and does not
change the central project. Inspect every required test project and imported
coverage in artifacts/sonar/<run>/publish/summary.json. Private scanner reports
stay ignored. A unique run name preserves earlier evidence.

## Central setup after review

1. Create a separate private marten-testing project with least-privilege analysis and
   Browse-only verification identities. Retain operator Browse/See Source Code.
   The reviewed frozen profiles/gate were copied to Marten Library 1.0.0 without
   editing any existing consumer. Disable the small-change exemption and keep the complete
   authored source/test inventory. The actual profile names, counts and update
   times are bound in main-policy.json; retain and verify this exact inventory.
2. Configure sonar-main with required operator review, self-approval allowed,
   administrator bypass disabled and main only. Store only the two named Sonar
   secrets there. Do not add repository-level fallback secrets or inheritance.
3. Confirm the registered workflow identities and bind their real IDs. Zero IDs in
   publication-target.json / nuget-policy.json and the templates mean unregistered,
   never wildcard or an ID borrowed from Core. Verify CI file hash, pinned shared
   CI identity where applicable, mandatory job names and every required step.
4. Only after those checks, review removal of the Sonar standby guard and set the
   opt-in switch. Coordinate this first full exact-main analysis with other users
   of the shared server, measure its representative resource usage, and retain
   the result as a proposed baseline. A null baseline is deliberate: the shared
   tool retains a full analysis but refuses readiness until a separately accepted
   prior SPECIFIC_ANALYSIS baseline is bound.
5. After baseline approval, obtain two sequential fresh exact-main CI/Sonar sets.
   Verify tasks, commit/run/attempt, full test/coverage inventory, baseline and gate
   policy. Retain meaningful new-code coverage and scoped failed-gate/recovery
   evidence. Never reset a baseline or weaken a gate to make onboarding pass.

The completed shared capacity measurement supports conservative sequential use,
not arbitrary database workloads or concurrency. Before each planned scan require
an empty active queue and the reviewed health/headroom checks. Existing concurrency
is scoped to a repository, so it does not guarantee global serialization. Keep
operator approval for scans; review central admission/queueing or concurrent-load
evidence before expanding to unattended overlapping triggers. Database tests run
on the CI runner, not in the Sonar service.

## NuGet preparation and migration

The complete production templates and no-upload rehearsal/acceptance templates
are adapted from the accepted Core gate. Package inventory is exactly AndreGoepel.Marten.Testing,
with both .nupkg and .snupkg. Publication uses official NuGet/login and native
dotnet nuget push only after verified preparation, fresh exact-main readiness,
matching package/source hashes and a preserved immutable publication intent.
Packages and symbols are pushed separately; ambiguous outcomes never authorize
an automatic retry. The completed Core symbol-recovery entry point is not copied.

Before enabling anything:

1. Register/bind the real preparation and readiness workflow IDs, refresh the
   SHA-256 of the exact preparation workflow in nuget-policy.json, and review the
   complete exact-commit policy. Recalculate that hash after every preparation
   workflow edit, including later trigger/guard changes.
2. Audit package owners, Trusted Publisher policies and alternative API-key scopes
   read-only. The current ci.yml route remains authoritative and can bypass Sonar;
   these standby files alone do not enforce publication.
3. Run the protected no-upload rehearsal on fresh main evidence. Use temporary
   restricted test environments and non-release tags only in a separately reviewed
   tag-test scope. The current preparation trigger admits v* only, so the test
   trigger needs a reviewed adjustment before any tag drill. Never allow the real
   publisher to handle a test tag. Verify missing/failed/pending/stale/wrong-SHA or
   wrong-policy evidence, changed manifests/packages, intent and one-shot rules.
4. Review legacy-publisher removal and the concrete package-to-policy migration
   together. Configure sonar-nuget-prepare (v* tags) and nuget-publish (main) with
   required review, self-approval and no administrator bypass. Use scoped secrets
   and an exclusive policy for this repository's nuget-publish.yml/environment.
   Review alternative keys/routes and test tag immutability before applying it.
   The supplied ruleset JSON is disabled and is a proposal, not an applied rule.
5. Activate preparation/publication only with separate operator approval. Obtain
   fresh CI/Sonar for the exact release commit, then seek explicit version/tag/release
   approval. A skipped standby run, local scan or no-upload result is not proof of
   a production publication. App-foundation and other repositories are unaffected.

Keep one review PR per repository for this preparation. Consolidate post-merge
registration, accepted baseline binding and migration changes where dependencies
permit. A second repository does not need a release of the first just to onboard
Sonar. Keep the issues open through verified central and migration acceptance.

## Rollback and evidence

Before analysis activation, leave the opt-in false and all NuGet standby guards
and existing routes intact. After a reviewed activation, suspend new gate jobs and
retain evidence while proposing a
coordinated rollback through a PR. Do not restore a bypass publisher as an automatic
fallback, revive revoked tokens, change accepted baselines or retry an uncertain
upload. Preserve intent/outcome artifacts and verify NuGet package/symbol status
before any separately authorized recovery.

The CI SDK-selection edits keep existing build/publish jobs aligned with global.json;
they do not change tag triggers, package scope, credentials or upload behavior.
No dedicated E2E host exists in this repository; PostgreSQL integration tests are
mandatory and are included in the complete analysis. Central analysis/baseline
acceptance, production policy migration and actual publishing remain pending
after this review PR.

## Initial baseline review sequence

Central setup was verified on 2026-10-25. The project remains private; the admin
account has Browse and See Source Code. Separate project analysis and Browse-only
verification identities passed allowed-access and cross-project denial checks.
The 27 frozen profiles match the reviewed source rule counts, including 121 C#
rules. The six gate thresholds and disabled small-change exemption are unchanged.

The registered Sonar readiness workflow ID is 395675689, now recorded in
publication-target.json. NuGet preparation identity/guard registration is still
pending and must be reviewed together before any no-upload or production activation.

Main CI [40166592872](https://github.com/andregoepel/marten-testing/actions/runs/40166592872)
passed on commit 7d05c746751c3a9a13d2ea4b0e8f9844f38c08c7, with publication skipped. This verifies the merged
preparation only; it is not evidence for a later activation commit or a baseline.

1. Merge the reviewed Sonar setup change, then verify CI on that exact new main
   commit. Keep every NuGet guard and the existing publication route unchanged.
2. Enable only SONAR_MAIN_ENABLED. Use an existing fresh matching CI completion or
   request one recorded CI rerun if needed. Require an empty central queue, healthy
   services and reviewed resource headroom before approving the protected analysis.
   Run the two Marten projects sequentially and retain representative resource data.
3. Verify the full source/test inventory, PostgreSQL test execution, imported
   coverage, task/analysis/commit/run/attempt identity, gate conditions and unchanged
   profiles. Retain the first successful upload as a baseline candidate. The runner
   must refuse readiness while baselineAnalysisId is null; an expected baseline
   guard failure does not prove a scanner failure or authorize a release.
4. Present the actual analysis ID and results for explicit operator approval. Do
   not select a baseline merely to make readiness green. Only after approval set
   SPECIFIC_ANALYSIS on this project and bind the same ID in the reviewed policy.
5. After that policy is merged, verify two fresh exact-main readiness sets against
   the selected baseline. Retain the new-code and capacity limits for acceptance.

The current baseline candidate is **pending**: no central analysis has run yet.
Local prototype results cannot substitute for central evidence. No standby workflow
is bypassed, no GitHub execution context is simulated, and no baseline is silently
accepted by this setup change.
