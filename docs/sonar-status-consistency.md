# Konsistenter Workflow-Status vor zentraler Sonar-Analyse

Tracking: [#38](https://github.com/andregoepel/marten-testing/issues/38);
[gemeinsame Korrektur](https://github.com/andregoepel/workflows/pull/36).

Der positive [Ausgangslauf 41110842287](https://github.com/andregoepel/marten-testing/actions/runs/41110842287)
nach dem Diagnose-Merge brach in Original-Attempt 1 vor jeder Analyse ab:
Unexpected readiness workflow identity or attempt. Keine Analyse- oder
Readiness-Artefakte entstanden; dies ist kein Coverage-Negativnachweis.

Die später gelesenen Repository-, Commit-, Event-, Workflow- und Attempt-Werte
entsprachen der Policy. Die Testing-API meldete noch waiting, während die Logs
bereits eine Ausführung zeigten. Das spricht für verzögerte Run-Status-Propagation;
die exakte HTTP-Antwort der fehlgeschlagenen Verifier-Anfrage wurde nicht erhalten.

Dieser Review bindet den Sonar-Aufruf, die main-policy toolRevision und die
publication-target verifierRevision an den vollständig geprüften Commit
ebc566218aaa60684d23483c63f974e222d8f7f2. Dieser Commit muss zuerst durch workflows PR #36 reviewt und
per Merge-Commit in den gemeinsamen main aufgenommen werden. CI-Workflow-Pin,
CI-Fingerprints, Preparation-Hash, Baselines, Gates und Produktionssperren ändern
sich nicht. Der aktualisierte Verifier ist damit bis in den Handoff gebunden.

Der gemeinsame Fix prüft Identität, Attempt und Runner-Pin vor jeder Warteentscheidung.
Nur die initiale, bereits begrenzte Warteschleife darf bei queued/waiting mit
null conclusion erneut lesen. Sie liefert bis in_progress keine Evidenz. Nach
höchstens den bestehenden 60 Polls mit 10 Sekunden Abstand schlägt sie weiter fehl.
Jeder Poll prüft den aktuellen main und alle Vertrauensbindungen erneut. Die
normalen Revalidierungsgrenzen und abgeschlossenen Producer bleiben strikt.
Ein anderer Commit, Attempt oder Pin, terminaler Status oder API-Fehler wird
weiter zurückgewiesen. Gate und Coverage werden dadurch nicht übersprungen.

## Bereits erledigte Betreiberabnahme

Der [geschützte NuGet-Anmeldetest 41110911910](https://github.com/andregoepel/marten-testing/actions/runs/41110911910)
war erfolgreich; effektiver NUGET_USER ist andre.goepel. Der echte Publisher wurde
übersprungen, es entstanden keine Artefakte. Die Live-Policy/Environment/Tag- und
positiven New-Code-Prüfungen stehen im Betreiberprotokoll. Kein Paket wurde hochgeladen.

## Nach dem Merge

1. Review und Merge der gemeinsamen Korrektur vor diesem Consumer-Review bestätigen.
2. Neue erfolgreiche CI und geschützte Main-Sonar-Analyse für den exakten gemergten
   Consumer-Commit prüfen; Marten-Scans sequenziell. Alte Fehlerläufe nicht rerunnen
   oder als Coverage-Drill umdeuten. Frische positive Readiness ist Voraussetzung.
3. Die bereits ausdrücklich genehmigten Fehler-/Recovery-Reviews auf diesen neuen
   main abgleichen und ihre exakten Rücknahmen erneut prüfen. Dann Testing komplett
   einschließlich Recovery, anschließend Configuration durchführen.
4. Gehostete Paket-/Symbol-Abnahme bleibt unter dem Veröffentlichungsverbot offen.
   Aktivierungs-PRs bleiben Entwürfe; das Rollout-Issue bleibt offen.

Lokale gemeinsame Validierung mit SDK 10.0.402: 1.098 Offline-Tests, Build ohne
Warnungen, Formatcheck, 31 Kapazitäts-Vertragsfälle und vollständiger Vulnerability-
Audit ohne bekannte Befunde erfolgreich. Die Consumer-PR-CI prüft die neue Pin-Bindung;
eine erfolgreiche PR-CI ist noch kein neuer geschützter Main-Nachweis.
