# Sonar and NuGet gate preparation

Tracking: [38](https://github.com/andregoepel/marten-testing/issues/38), [rollout epic](https://github.com/andregoepel/app-foundation/issues/238).

## Current boundary

The private central project uses the frozen Marten Library 1.0.0 gate/profiles.
SONAR_MAIN_ENABLED=true; central analysis requires operator approval in the
main-only sonar-main environment. Self-approval is allowed and administrator
bypass is disabled. Both scoped credentials have been verified from the hosted
runner. The explicitly approved SPECIFIC_ANALYSIS baseline is recorded in
main-policy.json and in the acceptance record below.

The real NuGet publisher remains unconditionally disabled. The three no-upload
test jobs require a separate repository switch, which is off until approved
execution. The existing v* tag publisher remains active and outside Sonar
enforcement until its separately reviewed retirement. Use only the strictly
scoped non-release acceptance tags after authorization; never use v* test tags.
Baseline approval does not activate publishing or complete the migration.

One production library and one PostgreSQL-backed test project (5 tests).

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

## Central operating checks

1. Keep the project private and retain separate project-analysis and Browse-only
   verification identities, plus operator Browse/See Source Code. Preserve the
   exact frozen profile inventory, gate thresholds, disabled small-change exemption
   and complete authored source/test inventory in main-policy.json.
2. Keep sonar-main restricted to main, with required operator review, self-approval
   allowed and no administrator bypass. Only SONAR_SCAN_TOKEN and
   SONAR_VERIFY_TOKEN belong there; do not add fallback secrets or inheritance.
3. Verify the registered Sonar workflow identity, exact CI file hash, pinned shared
   CI identity where applicable, mandatory job names and every required step.
   The Sonar readiness ID is bound in publication-target.json. NuGet preparation
   is bound to its registered ID and exact workflow hash in nuget-policy.json.
4. Preserve the accepted baseline ID below. Before approving any full analysis,
   require successful fresh CI for the exact current main commit, an empty central
   queue, healthy services and the reviewed resource headroom. Run planned scans
   sequentially across repositories.
5. The accepted baseline binding has passed two fresh exact-main CI/Sonar sets.
   Verify task, analysis, commit/run/attempt, full tests/coverage, gate/profile policy
   and the accepted comparison period. Retain meaningful new-code coverage and
   scoped failed-gate/recovery evidence. Do not reset baselines or weaken the gate
   to make readiness pass. A baseline analysis cannot issue readiness for itself.

The completed shared capacity measurement supports conservative sequential use,
not arbitrary database workloads or concurrency. Before each planned scan require
an empty active queue and the reviewed health/headroom checks. Existing concurrency
is scoped to a repository, so it does not guarantee global serialization. Keep
operator approval for scans; review central admission/queueing or concurrent-load
evidence before expanding to unattended overlapping triggers. Database tests run
on the CI runner, not in the Sonar service.

## NuGet preparation and migration

See [the bundled no-upload procedure and migration proposal](nuget-acceptance.md).
The registered preparation/readiness IDs and exact preparation hash are bound.
Rehearsal, acceptance-tag preparation and the no-upload consumer require the
repository test switch, which remains off until explicit execution approval.
The real publisher retains its unconditional false job guard and uses official
NuGet/login plus native dotnet nuget push only after a later approved activation.

The existing `ci.yml` tag publisher remains unchanged and can bypass Sonar.
No-upload acceptance, exclusive package policy, production environments, tag
protection and reviewed legacy-publisher retirement must precede activation.
No tag, credential transfer, policy migration or release is authorized by this
preparation. Keep one bundled review PR per repository where dependencies permit.

## Rollback and evidence

Keep the real NuGet publisher disabled and existing routes intact until their separately
approved migration. If central analysis needs rollback, suspend new gate jobs and
retain evidence while proposing a coordinated rollback through a PR. Do not restore
a bypass publisher as an automatic fallback, revive revoked tokens, change accepted
baselines or retry an uncertain
upload. Preserve intent/outcome artifacts and verify NuGet package/symbol status
before any separately authorized recovery.

The CI SDK-selection edits keep existing build/publish jobs aligned with global.json;
they do not change tag triggers, package scope, credentials or upload behavior.
No dedicated E2E host exists in this repository; PostgreSQL integration tests are
mandatory and were included in the complete first central analysis. Baseline
approval, two readiness sets and nonempty new-code checks are complete; production policy
migration and publishing acceptance remain open.

## Accepted initial baseline

André explicitly approved this analysis on 2026-10-25. The project's main branch
now uses SPECIFIC_ANALYSIS with the exact ID below; independent server readback
matches the policy. Baseline acceptance is not whole-wave or publication acceptance.

| Evidence | Accepted value |
| --- | --- |
| Analysis ID | e28d64b2-de9e-4bdf-b5c3-2bc47b15411b |
| Main commit analyzed | f43dd018c36611b7dca0d5bff08693f5fbaeb343 |
| Main CI | [40167668116, attempt 2](https://github.com/andregoepel/marten-testing/actions/runs/40167668116/attempts/2) — success |
| Central Sonar run | [40167941826, attempt 1](https://github.com/andregoepel/marten-testing/actions/runs/40167941826/attempts/1) |
| Tests discovered / passed | 4 / 4, including PostgreSQL tests |
| Imported source coverage | 100% |
| Findings / security hotspots | 0 / 0 |
| Scanner / processing / gate | Exit 0 / SUCCESS with zero warnings / OK |

Every authored production/test project was analyzed. An independent export of the
exact committed source matched the hosted source fingerprint. The six-condition
gate, all 27 frozen profile revisions (including 121 C# rules), source coverage
scope and disabled small-change exemption were verified. Publication was skipped.
The two first Marten analyses ran sequentially.

The historical Sonar run remains red because its only failed step ended with:

> Full analysis retained; a reviewed SPECIFIC_ANALYSIS baseline is still required.

The baseline was still null during that execution. Its summary was preserved,
but no readiness artifact was issued and releaseEligible=false. Selecting the
baseline does not retroactively create readiness or prove new-code conditions.
The policy binding must reach main before the subsequent analyses can verify it.

Two successful exact-main CI/Sonar readiness sets are recorded in the tracking
issue. Those first sets had zero new production lines. Subsequent main verification
now proves nonempty new-code coverage; the linked no-upload runbook records it
and the remaining local-versus-hosted failure/recovery boundary.

Resource observations found no sampled health, restart, OOM or headroom incident.
They do not establish peak or concurrent capacity: both processing tasks lasted
less than one second, and the retained cooldown stream has a 17.87-second gap
after processing. Do not infer continuous health through that gap. Raw host
snapshots, analysis summaries, checksums and selection evidence remain in ignored
local records. Service configuration, other consumer baselines/profiles and
global defaults were unchanged; no other repository or Action was edited.

## New-code and failure/recovery acceptance

See [the acceptance procedure](sonar-acceptance.md). It combines covered production
argument/lifecycle guards with a reproducible local clean/failure/recovery drill.
The drill uses the pinned shared runner and an isolated source snapshot; no Action,
central policy, baseline or publication setting changes. The production/test changes
are merged and their central nonempty new-code coverage is verified in the tracking
issue. Operator acceptance and NuGet enforcement remain separate.
