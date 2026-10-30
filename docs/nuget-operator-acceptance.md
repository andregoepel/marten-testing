# Betreiberabnahme ohne Paketveröffentlichung

Tracking: [#38](https://github.com/andregoepel/marten-testing/issues/38). Stand: 30. Oktober 2026.

## Erledigte Live-Prüfungen

- NuGet-Kontositzung und beide exakten Paket-Policies bestätigen Besitzer andre.goepel.
  Diese Policy verwendet ausschließlich Repository andregoepel/marten-testing,
  nuget-publish.yml und Environment nuget-publish, Push nur neuer Versionen.
  Die vollständige angezeigte Policy-Liste enthielt keine weitere passende Zuordnung;
  die API-Key-Verwaltung meldete keine Schlüssel. Andere Konten/Owners wurden nicht geprüft.
- Nach ausdrücklicher Zustimmung wurde das bestehende Repository-Secret NUGET_USER
  am 2026-10-30T18:45:01Z auf den bestätigten Benutzernamen gesetzt. GitHub bestätigte
  die Speicherung; der bisherige unbekannte Secret-Wert wurde nicht gelesen.
  Das Publisher-Environment enthält nur die beiden SONAR-Secrets und überschreibt
  den Benutzernamen deshalb nicht. Eine erfolgreiche Speicherung beweist noch keinen OIDC-Austausch.
- Beide Produktions-Environments verlangen Reviewer andregoepel (22834588), erlauben
  Selbstfreigabe und sperren Admin-Bypass. Preparation erlaubt nur Tag v*, Publisher
  nur Branch main. Keine temporäre main-Regel ist vorhanden.
- Ruleset 26220297 ist aktiv, schützt genau refs/tags/v*, verbietet Updates/Löschung
  und hat keine Bypass-Akteure. Kein Release-Tag wurde zum Prüfen angelegt.
- Die zuvor erfolgreichen Main-Readiness-Artefakte stimmen mit Commit, Repository und
  unveränderter akzeptierter Baseline überein. Sie melden analysisReady=true,
  releaseEligible=false. Historische Nachweise ersetzen keine frische Release-Prüfung.
- Live-Sonar: Gesamt-Coverage 100 %, 20 ausführbare Zeilen; neuer Code 100 %
  bei 2 ausführbaren neuen Zeilen, null neue unbedeckte Zeilen, null neue
  Conditions, null Findings und null Hotspots. Zeilentreffer der neuen Guards:
  MartenFixture.cs:76,78, jeweils mindestens ein Treffer. Mangels neuer Conditions ist dies
  kein separat gemessener Nachweis beider Zweige. Die erforderlichen positiven und
  negativen Guard-Tests sind in der erfolgreichen CI enthalten.

## Geschützter NuGet-Anmeldetest

Dieser Review fügt ausschließlich einen manuellen identity-check-Job in die bereits
zugeordnete nuget-publish.yml ein. Der echte publish-Job bleibt unbedingt gesperrt.

Nach einem separat reviewten Merge:

1. Erfolgreiche CI für den exakten neuen main-Commit prüfen. Nicht die Aktivierungs-PRs mergen.
2. Workflow NuGet verified publication auf main manuell starten, nur Original-Attempt 1.
3. Freigabe im unverändert geschützten Environment nuget-publish durchführen.
4. Der Job prüft Repository, main, Workflow-Revision, Attempt und effektiven Benutzernamen
   vor dem offiziellen, unverändert gepinnten NuGet/login. Anschließend prüft er erneut
   den aktuellen Hauptbranch und lediglich das Vorhandensein des ausgegebenen Schlüssels.
5. Ergebnis, Commit, Attempt und geschützten Job festhalten; zuerst testing, dann configuration.

Kein Checkout, Pack, Paket-Download, Push oder Artefakt-Upload ist Teil dieses Jobs.
Die Anmeldung tauscht OIDC gegen einen kurzlebigen NuGet-Schlüssel; der Schlüssel
wird weder ausgegeben noch gespeichert oder zum Upload verwendet. Das entspricht
[der offiziellen Aktionsbeschreibung](https://github.com/NuGet/login/blob/8d196754b4036150537f80ac539e15c2f1028841/README.md).
Ein erfolgreicher Test beweist die tatsächliche Vertrauensbindung dieses Workflows,
aber keine Paket-/Symbol-Annahme. Die bestehenden No-Upload-Simulationen bleiben getrennt.

## Gehosteter Coverage-Fehler und Recovery

Dieser Abnahmepunkt erfordert eine gesondert reviewte, ausdrücklich genehmigte
Fehlerrevision auf main. Keine Gates, Baselines, Token-Rechte oder Publish-Sperren ändern.
Kein Release-Tag während des Drills. Repositories sequenziell abarbeiten:

1. Sauberen Ausgangscommit und frischen erfolgreichen CI-/Sonar-Nachweis festhalten.
2. Eine isolierte zusätzliche Produktionsdatei SonarCoverageFailureProbe.cs reviewen.
   Sie enthält eine nicht aufgerufene interne Methode mit mindestens 64 unbedeckten
   Anweisungen; aktuelle Gesamtzeilen plus 32 bestimmen bei Bedarf die größere Größe.
   Bestehende Tests und öffentliche API bleiben unverändert. Entfernung ist die exakte Recovery.
3. Erst nach ausdrücklicher Merge-Autorisierung diese Fehlerrevision mergen.
   CI einschließlich aller Tests muss erfolgreich sein. Sonar anschließend auf genau
   diesem main-Commit im geschützten Environment sequenziell freigeben.
4. Erfolgreiche Analyseverarbeitung und Gate ERROR speziell für coverage < 80 fordern.
   Die Probe muss als unbedeckte Produktionsquelle importiert sein. Ein Netzwerk-,
   Test-, Build- oder beliebiger Workflowfehler ist kein erfolgreicher Negativnachweis.
   Kein positiver Readiness-Nachweis für diese Revision darf ausgegeben werden.
5. Den vorher reviewten exakten Rücknahmecommit per Recovery-PR mergen. Neue CI und
   neue geschützte Analyse verlangen; Gate OK, unveränderte Baseline und gültigen
   Readiness-Nachweis an exakt diesen Recovery-main-Commit binden.
6. Fehler- und Recovery-Task-/Analysis-IDs, Coverage, Receipts und Quellfingerprints
   aufbewahren. Erst danach zum zweiten Repository wechseln.

Eine tatsächliche NuGet-Upload-Blockade wird durch einen Test ohne Release-Tag nicht
gehostet bewiesen; dafür bleiben die Offline-Negativtests und der separate erste
freigegebene Release maßgeblich. Es gibt keinen Baseline-Reset zum Wiederherstellen.

## Weiter offen und ausdrücklich nicht ausgeführt

- Geschützter OIDC-Test: erfolgreich auf dem Diagnose-main in Original-Attempt 1;
  [Run 41110911910](https://github.com/andregoepel/marten-testing/actions/runs/41110911910).
  Der echte publish-Job war skipped, Artefaktanzahl null. Die sanitisierte
  Aufzeichnung liegt unter production-controls/identity-acceptance-2026-10-30.json.
- Tatsächlicher roter Main-/Recovery-Drill: benötigt Review der Fehlerrevision und
  ausdrückliche Merge-Autorisierung; bisher nicht ausgeführt.
- Gehostetes Verhalten annotierter Release-Tags und Remote-Paket-/Symbol-Annahme:
  unter dem geltenden Veröffentlichungsverbot nicht abgenommen. Kein echter Tag oder Upload.
- Hostweite Speicherreserve und externe Archivierung: nicht geprüft/umgesetzt.
- Aktivierung bleibt ein eigener Review. Nach jedem weiteren Merge verfallen die
  bisherigen Commit-Bezüge; vor Release müssen neue frische Nachweise vorliegen.

Das Tracking-Issue bleibt offen. Keine vorhandenen Tokens wurden widerrufen und
keine Pakete veröffentlicht. Ein fehlgeschlagener Login wird untersucht, nicht
blind wiederholt; eine fehlgeschlagene Main-Analyse wird durch den Review-Recovery
behoben und niemals durch eine gelockerte Policy.

Die nachfolgende [Status-Konsistenzkorrektur](sonar-status-consistency.md) hält die
unerwartet fehlgeschlagenen positiven Main-Läufe und den neuen exakt geprüften
Verifier-Pin fest. Der Coverage-/Recovery-Drill ist deshalb noch nicht ausgeführt.
