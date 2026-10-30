# Geschützte Prüfung der neuen Produktions-Tokens

Der Workflow `Sonar production token check` prüft die beiden Sonar-Secrets eines
gezielt gewählten Environments. Er erzeugt keine Pakete, Analysen, Tags oder
NuGet-Tokens und lädt weder Pakete noch Artefakte hoch. GitHub-Berechtigung:
ausschließlich `contents: read`, kein OIDC. Die Produktionsjobs bleiben gesperrt.

## Was geprüft wird

- Beide Secrets sind vorhanden, verschieden und haben den erwarteten User-Token-Typ.
- Die Sonar-Authentifizierung ist gültig; die Konten heißen exakt
  `marten-testing-scanner` und `marten-testing-verifier`.
- Beide Konten haben keine globalen Berechtigungen und nur die Gruppe `sonar-users`.
- Der Verifier kann das eigene private Projekt lesen, nicht die anderen drei.
- Der Scanner kann keine privaten Projektinhalte lesen; seine gesonderte
  Execute-Analysis-Zuweisung wurde bei der Token-Erstellung geprüft.

Das ist ein Credential-/Leserechte-Test. Er beweist weder erfolgreichen
Scanner-Upload noch Paket-/Symbol-Ingestion, NuGet-OIDC oder vollständige
Release-Readiness. Eine zusätzliche Analyseberechtigung auf einem fremden Projekt
lässt sich durch die Browse-Negativtests allein nicht ausschließen; dafür gilt die
bereits getrennt geprüfte Projektberechtigungsmatrix.

`curl` verwendet ausschließlich GET, die feste zentrale HTTPS-Adresse,
begrenzte Zeit-/Antwortgrößen und keine Redirects. Bearer-Header werden per stdin
übergeben. Antworten bleiben in einem temporären, nach dem Lauf gelöschten
Verzeichnis; Diagnoseausgaben enthalten keine Tokens oder rohen Antworten.
Unbekannte Identitäten, globale Rechte, falsche Projekte, HTTP-/Transport-Fehler
und unerwartete Veröffentlichungs-Credentials führen zum Fehler.

## Voraussetzungen

Der Workflow muss zuerst über diesen Review-PR auf `main` gelangen. Vorher gibt
es keinen Workflow, der die neuen Environments sicher verwendet. Der bereits
vorhandene `NuGet no-upload rehearsal` benutzt `sonar-main` und würde die alten
Tokens prüfen. Eine Änderung an `sonar-main` ist kein Ersatz.

Die neuen User-Tokens der vier vorhandenen, eingeschränkten Projektkonten sind
in beiden Produktions-Environments hinterlegt. Erstellung: 30. Oktober 2026;
Ablauf: **29. November 2026**. Die alten Tokens und `sonar-main` wurden nicht
verändert. Aktuelle Secret-Metadaten vor dem Lauf prüfen; keine Werte ausgeben.

## Sequenzieller Betriebsplan nach dem Merge

Je Repository zuerst `nuget-publish`, anschließend `sonar-nuget-prepare` prüfen;
erst danach zum nächsten Repository wechseln. Keine parallelen Prüfläufe.

1. Exakten gemergten `main`-Commit und erfolgreiche CI bestätigen. Die bestehenden
   Sonar-Readiness-Läufe und ihre Operator-Freigaben bleiben ein separater Nachweis.
2. Workflow `sonar-token-check.yml` auf `main` mit Input
   `target_environment=nuget-publish` starten. Geschütztes Environment freigeben.
   Nur der erste Run-Attempt ist erlaubt. Checkout, Workflow-Revision und live
   gelesener Hauptbranch müssen vor und nach den HTTP-Prüfungen übereinstimmen.
3. Erfolgreichen Job `verify`, Run-ID, Attempt, SHA, Zielenvironment und sanitisierte
   Zusammenfassung festhalten. Ein allein erfolgreicher `contracts`-Job genügt nicht.
4. `sonar-nuget-prepare` erlaubt dauerhaft nur Tags `v*`. Für den main-gebundenen
   Prüflauf ist deshalb eine **temporäre zusätzliche Branch-Regel `main`** nötig.
   Vor dem Anlegen vollständige Ref-Regeln lesen und exakt die vorhandene
   Tag-Regel bestätigen. Reviewer, erlaubte Selbstfreigabe und gesperrten
   Admin-Bypass erhalten; keine anderen Branches, Tags oder Reviewer freigeben.
5. Nur diese zusätzliche Regel über
   `repos/andregoepel/marten-testing/environments/sonar-nuget-prepare/deployment-branch-policies`
   mit Body `{ "name": "main", "type": "branch" }` anlegen und ihre ID festhalten.
   Dann denselben Workflow mit `target_environment=sonar-nuget-prepare` starten und
   dessen Environment-Freigabe durchführen. Keinen Test- oder Release-Tag erzeugen.
6. Die zusätzliche Regel im abschließenden Aufräumschritt anhand ihrer exakten ID,
   des Namens `main` und Typs `branch` wieder entfernen, auch wenn der Workflow
   fehlschlägt oder abgebrochen wird. Abschluss-Readback: ausschließlich Tag `v*`,
   unveränderter Reviewer und kein Admin-Bypass. Fehlt der Aufräumnachweis, keine
   Aktivierung und keinen erfolgreichen Abschluss melden.

Die temporäre `main`-Regel wird durch diesen PR nicht angelegt. Sie erweitert
vorübergehend die Ref-Zulassung auf bereits reviewten Hauptbranch-Code und gehört
zum konkret zu prüfenden Betriebsplan. Ohne diese Regel muss GitHub den
Preparation-Environment-Lauf zurückhalten. Die Schutzregeln werden nicht umgangen.

Bei Fehlern die Identität, Rechte, Ablaufdaten und Secret-Ziele prüfen. Bestehende
Tokens nicht widerrufen, keine Secrets in Logs ausgeben und keine automatische
Wiederholung starten. Beide Produktions-Publisher bleiben unverändert deaktiviert.

## Lokale Vertragsprüfung

`bash scripts/sonar/tests/production-tokens.sh` führt die tatsächliche Probe mit
isolierten HTTP-Fixtures aus. Positive Fälle für beide Projekte und negative Fälle
für Authentifizierung, Identitäten, globale Rechte, Gruppen, Projektgrenzen,
Transport/Redirect/JSON und Credential-Kanäle sind enthalten. Es erfolgen keine
externen Netzwerkzugriffe. Derselbe Vertrag läuft ohne Secrets bei Pull Requests.

**Status dieses PRs:** lokal geprüft; geschützte Produktions-Token-Läufe noch
nicht ausgeführt. Die tatsächlichen Ergebnisse können erst nach Merge und
Environment-Freigabe ergänzt werden. Dieser PR aktiviert keine Veröffentlichung.

## Erster Dispatch und Korrektur des Context-Guards

Der erste [geschützte Lauf in marten-testing](https://github.com/andregoepel/marten-testing/actions/runs/41097885045)
ist vor Checkout und Credential-Prüfung fehlgeschlagen: Die Workflow-Vorlage hatte
GITHUB_REPOSITORY bei der Repository-Ersetzung beschädigt. Das ist kein negativer
Token-Nachweis. Weitere Läufe wurden angehalten; es wurde noch keine temporäre
main-Regel angelegt und kein Upload ausgeführt. Der historische Fehlerlauf bleibt
unverändert; kein Rerun wurde ausgelöst.

Die Korrektur erhält die Standardvariable unverändert und prüft zusätzlich
Repository, Event und Ref ausdrücklich. Die Vertragsprüfung führt jetzt die
tatsächlich ausgelieferten Dispatch- und Summary-Blöcke aus, einschließlich
Original-Attempt, Workflow-/Main-Identität und Negativfällen. Ein erfolgreicher
Fixture-Test ersetzt weiterhin nicht die echten Token-Läufe. Erst nach Merge
der Korrektur einen neuen Lauf auf dem dann aktuellen main-Commit starten.
