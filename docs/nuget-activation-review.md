# Aktivierungsentwurf: geschützter NuGet-Ablauf

Tracking: [Issue #38](https://github.com/andregoepel/marten-testing/issues/38). Stand: 30. Oktober 2026.

## Nachweise auf dem bisherigen Hauptbranch

Commit: a56e7f5a058b19f7c3ec722335562308c980c4a8. Alle folgenden Läufe sind Original-Attempt 1.

| Prüfung | Ergebnis |
| --- | --- |
| Produktions-Token in nuget-publish | [erfolgreich](https://github.com/andregoepel/marten-testing/actions/runs/41099766189) |
| Produktions-Token in sonar-nuget-prepare | [erfolgreich](https://github.com/andregoepel/marten-testing/actions/runs/41099863471) |
| CI mit Build, Tests und Vulnerability scan | [erfolgreich](https://github.com/andregoepel/marten-testing/actions/runs/41099602189) |
| Sonar main readiness | [erfolgreich](https://github.com/andregoepel/marten-testing/actions/runs/41099747521) |

Die Token-Probe bestätigt Authentifizierung, Servicekonto-Identitäten und private
Projekt-Lesegrenzen. Sie reicht keine Analyse ein und beweist keine vollständige
Execute-Analysis-Rechtematrix. Die bestehenden Tokens wurden nicht widerrufen.
Die zusätzlichen main-Regeln wurden nach den Preparation-Token-Prüfungen entfernt;
dauerhaft gilt wieder ausschließlich Tag v*. Reviewer und Admin-Bypass blieben erhalten.

Die beiden Main-Analysen wurden sequenziell freigegeben. Der heruntergeladene
Readiness-Nachweis stimmt mit Repository, Commit und bisheriger Baseline überein:
analysisReady=true, releaseEligible=false. Seine Gültigkeit beträgt 60 Minuten;
dies ist ein historischer Prüfbeleg und keine künftige Release-Freigabe.
Der Sonar-Dienst meldete GREEN und eine leere Analyse-Warteschlange.
Hostweite Speicherreserven wurden nicht gemessen.

## Änderung dieses Entwurfs

Die unbedingten false-Sperren in nuget-prepare.yml und nuget-publish.yml entfallen.
Der LF-normalisierte SHA-256 der Preparation wird in nuget-policy.json nachgeführt.
Repository-, Event-, Version-, Commit-, Attempt-, Frische- und Handoff-Prüfungen
sowie die geschützten Environments bleiben erhalten. Ein Merge erlaubt künftig
passende Release-Tag-Ereignisse; er erzeugt selbst keinen Release-Tag.

## Vor einem Merge offen

- Live-Kontrollen und NuGet-Policy unmittelbar vor Aktivierung erneut prüfen.
- Effektiven NUGET_USER für das Besitzerkonto andre.goepel sicher bestätigen.
  Das vorhandene Secret ist nicht auslesbar; keinen Wert in Logs ausgeben.
- Betreiberabnahme festhalten. Der lokale Coverage-Fehler-/Recovery-Drill ersetzt
  keinen geschützten Main-Drill. Gehostete NuGet-OIDC-, Upload- und entfernte
  Paket-/Symbol-Abnahme sind weiterhin offen und benötigen eine separate Freigabe.
- Nach Merge neue CI-/Sonar-Nachweise für den neuen exakten Main-Commit prüfen.
  Die oben verlinkten Nachweise gelten ausschließlich für den bisherigen Commit.

Dieser PR bleibt deshalb ein Entwurf. Keine Pakete wurden veröffentlicht, keine
Release-Tags angelegt und keine NuGet-Anmeldung ausgeführt. Ein erster Release
braucht eine gesonderte Freigabe von Version, Commit und Tag. Das Tracking-Issue
bleibt bis zur vollständigen Abnahme offen.
