# Review der geschützten NuGet-Aktivierung

Tracking: [Issue #38](https://github.com/andregoepel/marten-testing/issues/38). Stand: 31. Oktober 2026.
Dieser PR bleibt ein Entwurf; die Produktionsjobs auf main sind weiterhin gesperrt.

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
externe Archivierung sowie
separat freizugebende echte Paket-/Symbol-Annahme und annotierte Release-Tag-Abnahme.
Keine dieser Grenzen wird durch eine erfolgreiche PR-CI oder die historischen
Readiness-Dateien aufgehoben. Vor Aktivierung Live-Kontrollen erneut lesen; nach
einem separat genehmigten Merge neue CI-/Sonar-Nachweise für den neuen exakten main
verlangen. Kein Upload, kein Release-Tag, kein Baseline-Reset und keine Token-Widerrufe.

Der autorisierte Ressourcencheck ist als unauffällige Momentaufnahme nach den Scans
abgeschlossen; Details und Grenzen stehen im Betreiberprotokoll. Ein dedizierter
Kapazitäts-/Lastspitzentest wird dadurch nicht behauptet. Der neue Notebook-SSH-Zugang
wurde mit erhaltenen bestehenden Server-Schlüsseln separat verifiziert.
