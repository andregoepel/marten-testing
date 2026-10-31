# Produktionskontrollen und verbleibende NuGet-Aktivierung

Tracking: [Issue #38](https://github.com/andregoepel/marten-testing/issues/38).
Stand: 30. Oktober 2026. Diese Dokumentation hält installierte Kontrollen fest;
auf main bleiben Vorbereitung und Veröffentlichung bis zum separaten Aktivierungs-Merge deaktiviert.

## Abgenommener Hauptbranch

[PR #45](https://github.com/andregoepel/marten-testing/pull/45) hat den alten CI-Publisher
entfernt und den Produktionsablauf im Standby vorbereitet. Hauptbranch:
`5eeabe2b35f9b546fbb58db744c7a1b2facfc01c`. Die dazugehörigen [CI](https://github.com/andregoepel/marten-testing/actions/runs/40195779319)
und [Sonar](https://github.com/andregoepel/marten-testing/actions/runs/40195844743) waren erfolgreich.
Diese historischen Läufe sind kein aktueller Release-Freigabenachweis.

## Installierte GitHub-Kontrollen

| Environment | Einzige Deployment-Regel | Secrets im letzten Readback |
| --- | --- | --- |
| `sonar-nuget-prepare` | Tag `v*` | `SONAR_SCAN_TOKEN`, `SONAR_VERIFY_TOKEN` |
| `nuget-publish` | Branch `main` | `SONAR_SCAN_TOKEN`, `SONAR_VERIFY_TOKEN` |

Beide Environments verlangen Reviewer `andregoepel` (GitHub-ID 22834588), erlauben
Selbstfreigabe und sperren Administrator-Bypass. Es gibt keine weiteren
Branch-/Tag-Regeln. Die bestehende Umgebung `sonar-main` bleibt unverändert.

Das aktive Ruleset **26220297** schützt genau `refs/tags/v*`: keine Ausnahmen,
keine Bypass-Akteure, Updates und Löschungen verboten. Die versionierte
Ruleset-Vorlage bleibt deaktiviert; ihr Vorhandensein ist keine Live-Aktivierung.

Der Schutz wurde zuerst isoliert unter `sonar-control-check/<nonce>/` geprüft:
Git-Push von Update und Löschung meldete jeweils `GH013`, danach wurde das
unveränderte Tag-Ziel zurückgelesen. Temporäres Ruleset und Test-Tag wurden
entfernt. Die Abschlussabfrage fand keine Test-Tags mehr. Kein Release-Tag wurde
angelegt. Dies beweist keine gehostete Veröffentlichung mit annotierten Tags.

Die passenden JSON-Payloads und die sanitisierte Abnahme stehen unter
[`scripts/sonar/publication/production-controls`](../scripts/sonar/publication/production-controls/).
`verification.json` ist eine historische Operator-Aufzeichnung; vor Aktivierung
müssen die Live-Einstellungen erneut geprüft werden. Die Datei ist kein von der
Veröffentlichungslogik akzeptierter Berechtigungsnachweis.

## Gespeicherte NuGet-Zuordnung

| Feld | Verifizierter Wert |
| --- | --- |
| Paket | `AndreGoepel.Marten.Testing` |
| Paketbesitzer | `andre.goepel` |
| GitHub-Owner / Repository | `andregoepel` / `marten-testing` |
| Workflow | `nuget-publish.yml` |
| Environment | `nuget-publish` |
| Scope | Nur neue Versionen des exakt genannten vorhandenen Pakets |

Nach ausdrücklicher Operator-Freigabe wurde die vorhandene Policy geändert und
anschließend die gespeicherte Bestandsanzeige geprüft. Die frühere `ci.yml`-
Bindung ohne Environment wurde ersetzt. Repository- und Owner-Identität blieben
unverändert. Keine zusätzliche Policy, Wildcard, Paket-Neuanlage oder Unlist-
Berechtigung wurde hinzugefügt.

Die vollständige angezeigte Policy-Liste enthielt keine überlappende Zuordnung
für dieses Paket. Das Konto meldete ausdrücklich keine API-Schlüssel. Dies ist
der Kontobefund zum Prüfzeitpunkt; vor Aktivierung alternative Routen erneut
prüfen. Es wurde kein Upload ausgeführt und kein NuGet-Token erzeugt.

## Nächste Schritte vor Aktivierung

1. Live-Readback von Environments, Ref-Regeln, Reviewer, Bypass, Ruleset und
   NuGet-Policy gegen die obigen Werte wiederholen. Andere Pakete unverändert lassen.
2. Die genehmigte Credential-Platzierung ist abgeschlossen. Für die Prüfung gelten:
   `SONAR_SCAN_TOKEN` und `SONAR_VERIFY_TOKEN` für dieses Projekt in
   `sonar-nuget-prepare` und `nuget-publish`. Beide Ziele sind inzwischen mit neuen
   User-Tokens der bestehenden, eingeschränkten Servicekonten belegt; Ablauf
   29. November 2026.
   Den effektiven `NUGET_USER`-Wert für den Publisher prüfen; ein Repository-Secret
   dieses Namens existiert bereits, sein Wert wurde nicht gelesen. GitHub gibt
   bestehende Secret-Werte nicht zurück. Keine Werte in Logs oder Dateien ablegen.
3. Betreiberabnahme mit den vorhandenen Evidenzgrenzen festhalten. Der lokale
   Coverage-Fehler-/Recovery-Drill ersetzt keinen geschützten Main-Drill. Gehostete
   NuGet-OIDC-, Upload- und Remote-Paket-/Symbol-Abnahme sind noch nicht erbracht.
4. Erst danach einen eigenen Aktivierungs-PR prüfen: Produktionssperren gezielt
   entfernen und den LF-normalisierten SHA-256 von `nuget-prepare.yml` in
   `nuget-policy.json` aktualisieren. Alle Herkunfts-, Versions-, Commit-, Attempt-,
   Frische- und Handoff-Prüfungen erhalten. Rehearsal und Acceptance bleiben separat.
5. Nach einem separat freigegebenen Merge neue erfolgreiche CI-/Sonar-Nachweise
   für den exakten Hauptbranch prüfen. Scans zwischen Repositories sequenziell
   freigeben. Ein erster Release braucht zusätzlich Version-, Commit- und Tag-
   Freigabe sowie frische Evidenz; dieser Review-PR autorisiert keinen Upload.

Bei fehlenden Kontrollen oder Nachweisen bleiben beide Produktionsjobs gesperrt.
Kein Rückfall auf den alten Publisher, keine Baseline-Resets und keine Wiederholung
unklarer Uploads. Externe Archivierung bleibt ein eigenständiger Folgepunkt.
Das Tracking-Issue bleibt bis zur vollständigen Abnahme offen.

## Validierung des vorangegangenen Kontroll-PRs

Die vorhandenen Offline-Suiten tagged-handoff.sh sowie outcomes.sh für den
Produktions- und Acceptance-Recorder sind erfolgreich. Unter Git Bash lief das
offizielle jq 1.8.2 mit --binary für LF-Ausgabe. JSON-Payloads, unveränderte
CI-/Preparation-Policy-Hashes und beide unbedingten Produktionssperren sind geprüft.
Die Live-Environment- und Tag-Kontrollen wurden erneut zurückgelesen.

CSharpier 1.3.0 lief direkt mit der installierten .NET-10-Laufzeit; das im Projekt
gepinnte SDK 10.0.402 fehlt lokal. Vollständige Build-/PostgreSQL-Tests werden
deshalb durch die bestehende PR-CI geprüft. Der damalige Kontroll-PR änderte keine C#-Quellen,
Workflows, Abhängigkeiten oder Credentials.

## Neue Credential-Prüfläufe

Siehe [den geschützten, schreibfreien Prüfplan](sonar-production-token-check.md).
Die Metadaten sind geprüft; die tatsächlichen Workflow-Prüfungen der neuen Secrets
stehen noch aus. Die Produktionssperren bleiben erhalten.

Der nachfolgende [Aktivierungsentwurf](nuget-activation-review.md) dokumentiert die
neuen geschützten Prüfläufe, die vorbereiteten Änderungen und die offenen Merge-Bedingungen.

## Aktueller Abnahmestand vom 31. Oktober 2026

NuGet-Identität und geschützter OIDC-Anmeldetest ohne Upload sowie der gehostete
Main-Coverage-Fehler-/Recovery-Drill sind inzwischen erfolgreich abgeschlossen.
Die obigen früheren Planungsstände bleiben als Historie erhalten. Maßgeblich für
Ergebnisse, Grenzen und verbleibende Punkte ist das
[aktuelle Betreiberprotokoll](nuget-operator-acceptance.md). Beide Produktionsjobs
bleiben auf main gesperrt; der Aktivierungsreview ist ungemergt. Keine Veröffentlichung.
