# Review der geschützten NuGet-Aktivierung

Tracking: [Issue #38](https://github.com/andregoepel/marten-testing/issues/38). Stand: 1. November 2026.
Dieser PR ist zur Prüfung vorbereitet; die Produktionsjobs auf main sind weiterhin gesperrt.

Die NuGet-Benutzeridentität andre.goepel ist bestätigt, sicher hinterlegt und durch
einen tatsächlichen geschützten OIDC-Anmeldetest ohne Upload geprüft. Die neuen
Sonar-Token wurden in beiden Produktions-Environments erfolgreich diagnostisch
geprüft; zusätzliche main-Regeln sind entfernt. Die Live-Environment-/Tag-Kontrollen
wurden erneut gelesen und passen zum reviewten Schutzmodell.

Der gehostete Main-Drill einschließlich exakter Recovery ist abgeschlossen:

| Phase | Nachweis |
| --- | --- |
| Positiver Ausgang | [Sonar 41196044374](https://github.com/andregoepel/marten-testing/actions/runs/41196044374) |
| Gezielter Coverage-Fehler, alle 5 Tests erfolgreich | [Sonar 41196940753](https://github.com/andregoepel/marten-testing/actions/runs/41196940753) |
| Exakte saubere Recovery, Gate OK | [Sonar 41197257793](https://github.com/andregoepel/marten-testing/actions/runs/41197257793) |

Fehler-Coverage 23.5 % bei unveränderter 80-%-Grenze, kein Readiness-Artefakt.
Recovery-Coverage 100.0 %, neuer Nachweis an main 7fb47734f754054dc1f9c1253bb0e8a2d8e46885 gebunden,
analysisReady=true und releaseEligible=false. Quellfingerprint, Contract und Baseline
entsprechen dem sauberen Ausgang; beide Coverage-Proben sind aus main entfernt.
Testing wurde vollständig wiederhergestellt, bevor Configuration getestet wurde.

Dieser Entwurf ändert die unbedingten false-Guards von nuget-prepare.yml und
nuget-publish.yml und den LF-normalisierten Preparation-Hash in nuget-policy.json.
Alle Herkunfts-, Versions-, Commit-, Attempt-, Frische- und Handoff-Prüfungen sowie
die geschützten Environments bleiben erhalten. Ein Merge erzeugt keinen Release-Tag;
er würde künftige passende Tag-Ereignisse für den Produktionsablauf zulassen.

[Betreiberprotokoll](nuget-operator-acceptance.md) und
[sanitisierte Abnahme](../scripts/sonar/publication/production-controls/operator-acceptance-2026-10-31.json)
enthalten die Commit-/Task-/Analysis-IDs, Grenzen und noch offenen Punkte. Dazu gehören
das inzwischen verifizierte lokale Archiv mit ausdrücklich verbleibenden historischen Lücken sowie
separat freizugebende echte Paket-/Symbol-Annahme und annotierte Release-Tag-Abnahme.
Keine dieser Grenzen wird durch eine erfolgreiche PR-CI oder die historischen
Readiness-Dateien aufgehoben. Vor Aktivierung Live-Kontrollen erneut lesen; nach
einem separat genehmigten Merge neue CI-/Sonar-Nachweise für den neuen exakten main
verlangen. Kein Upload, kein Release-Tag, kein Baseline-Reset und keine Token-Widerrufe.

Der autorisierte Ressourcencheck ist als unauffällige Momentaufnahme nach den Scans
abgeschlossen; Details und Grenzen stehen im Betreiberprotokoll. Ein dedizierter
Kapazitäts-/Lastspitzentest wird dadurch nicht behauptet. Der neue Notebook-SSH-Zugang
wurde mit erhaltenen bestehenden Server-Schlüsseln separat verifiziert.

## Archivierungsfortschritt vom 1. November 2026

Das gewählte lokale unabhängige Archiv der verfügbaren Originalbelege ist erstellt
und über Original-Digests und einen erneut geprüften Hash-Index verifiziert.
Die fehlenden historischen Ein-Tages-Archive bleiben eine ausdrücklich dokumentierte
Lücke. Die separat gemergte Aufbewahrung beträgt inzwischen 90 Tage; Gültigkeit
und Sicherheitsprüfungen bleiben unverändert. Maßgeblich sind
[Archivprotokoll und Grenzen](nuget-evidence-archive.md). Keine Veröffentlichung.

Die getrennten Standby-Aufbewahrungsreviews sind am 1. November 2026 genehmigt
gemergt worden; dieser Aktivierungsentwurf ist auf den neuen main abgeglichen.
Die Publishing-Aktivierung selbst bleibt weiterhin ungemergt.

## Aktualisierte Aktivierungsvorprüfung vom 1. November 2026

Aktueller geprüfter main: 0d9b8dcd55bef791a350a5194d64cac10a649684. [CI 41297046396](https://github.com/andregoepel/marten-testing/actions/runs/41297046396)
und [geschützter Sonar-Lauf 41297116367](https://github.com/andregoepel/marten-testing/actions/runs/41297116367)
sind erfolgreich: 5 Tests, Coverage 100.0 %, Gate OK,
unveränderte Baseline, analysisReady=true und releaseEligible=false. Dies ist ein
commitgebundener Abnahmebeleg; die ursprüngliche Receipt-Ablaufzeit bleibt erhalten.

Produktions-Environments und unveränderliche v*-Regeln wurden erneut lesend geprüft:
Preparation nur Tags v*, Publisher nur main, Reviewer 22834588 und kein Admin-Bypass.
Keine temporäre main-Freigabe ist vorhanden. Die NuGet-Policy-/Kontoinventur bleibt
der historische Nachweis vom 30. Oktober und wurde hier nicht erneut im Konto geprüft.
Die [sanitisierte Vorprüfung](../scripts/sonar/publication/production-controls/activation-preflight-2026-11-01.json)
verknüpft Schutzregeln, aktuelle Main-Nachweise und das erweiterte lokale Archiv.

Nach einem separat freigegebenen Aktivierungs-Merge sind neue CI-/Sonar-Nachweise
für dessen exakten main nötig. Release-Version, Commit, Tag und Upload bleiben
separat freizugeben; echte Paket-/Symbol-Annahme und gehostete annotierte Release-Tag-
Abnahme sind weiterhin offen. Dieser Review-Schritt führt keinen Merge, Tag oder Upload aus.
