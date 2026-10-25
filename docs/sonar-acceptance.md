# New-code coverage and failure/recovery acceptance

Tracking: [#38](https://github.com/andregoepel/marten-testing/issues/38).

## Review scope

`MartenFixture.ResetAsync` now reports an `InvalidOperationException` naming the
required initialization step when called before initialization. The regression
test exercises that path; the existing PostgreSQL reset test exercises the
initialized path. This provides executable new production lines and both sides
of the guard, without adding a permanent synthetic probe to the package.

The test inventory is five tests. The analysis contract retains the complete
production/test inventory and coverage anchor. The accepted central baseline,
gate, frozen profiles, exclusions, Actions and publishing settings are unchanged.

## Isolated local drill

Use the existing private `marten-testing-local` project on the separate loopback
prototype, with the reviewed gate/profiles and small-change exemption disabled.
Supply its analysis and verification tokens through the protected process
environment, as described in [the local runbook](sonar.md#local-verification).
Do not use central credentials. No new client or scanner is introduced.

```powershell
./scripts/sonar/test-acceptance.ps1 -ServerId '<local server ID>' -RunName 'acceptance-review-01'
```

The script copies the non-ignored repository inventory, including review edits,
into a uniquely named short temporary directory to avoid Windows path limits.
It retains source hashes and evidence below `artifacts/sonar/acceptance/<run>`,
then removes its temporary source copy. It runs the pinned analysis wrapper
three times, sequentially:

1. **Clean:** all required tests pass, coverage is imported, the gate is OK and
   there are no findings or hotspots.
2. **Coverage failure:** only the isolated copy gains an unexecuted production
   probe. Its size is derived from the clean coverage denominator. All normal
   tests must still pass, the probe must appear as mapped but uncovered source,
   and the unchanged `coverage < 80` condition must reject the analysis. A missing
   report, failed build/test, network error or arbitrary nonzero exit is not a pass.
3. **Recovery:** the script removes its exact probe and repeats the full scan.
   It requires a fresh analysis/task, gate OK, no findings, the original source
   fingerprint and the same contract and comparison period.

Logs, the three sanitized summaries and the final `verified.json` stay in the
ignored directory. Existing evidence is never overwritten. Interrupted or failed
execution has no final success record: inspect the logs and local project state
before starting another run. The original checkout is never given the probe.
No tag, package, upload, GitHub dispatch, central scan or baseline change occurs.

This proves local coverage-gate rejection and recovery. It does not issue or
validate a protected main readiness receipt, and does not prove a hosted rejected
receipt or NuGet publication block. The baseline used by the local project is
independent of the accepted central baseline.

## After operator review and merge

1. Verify successful existing CI for the exact merged main commit. Reuse the
   corresponding Sonar trigger and approve it only with fresh CI, an empty
   central queue and the documented service headroom. Keep Marten runs sequential.
2. Preserve the accepted `SPECIFIC_ANALYSIS` ID. Require a fresh successful task,
   the exact commit/run/attempt, all five tests, imported coverage and an intact
   readiness receipt with `analysisReady=true` and `releaseEligible=false`.
3. Inspect the live new-code measures and source-level coverage for the new guard.
   Require `new_lines_to_cover > 0`, `new_coverage >= 80`, and no new uncovered
   lines. Verify both guard outcomes in the imported coverage; where Sonar reports
   new conditions, require none uncovered. Zero-denominator acceptance does not
   satisfy this step. Check all other gate conditions and frozen policy bindings.
4. Record the local rejection/recovery evidence separately from the central
   positive new-code/readiness result. Keep a hosted failure/recovery acceptance
   item open if it requires an actual red main readiness run: this PR does not
   authorize introducing failing code on main, merging, changing Actions or
   moving a baseline. Such a drill needs a separately approved failing revision
   and exact recovery revision through review, with explicit merge authorization.
5. Retain the covered guard as useful behavior; no cleanup PR is needed for it.
   Do not close the rollout issue or claim NuGet enforcement from this check.
   Registration, protected no-upload tests, policy migration and activation remain
   separate decisions. Existing tag publishing can still bypass Sonar; create no
   release or test tag during this acceptance step.
