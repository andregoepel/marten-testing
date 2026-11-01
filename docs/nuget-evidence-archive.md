# Lokales unabhängiges Belegarchiv

Tracking: [Issue #38](https://github.com/andregoepel/marten-testing/issues/38). Stand: 1. November 2026.

Das ausdrücklich gewählte lokale Archiv liegt im Repos-Verzeichnis unter
.sonar-evidence/2026-11-01T095735Z. Der Einstieg ist index.json, die vollständige
Dateiliste steht in manifest.json. Manifest-SHA-256:
27fbb2187bad0f65836003602d9ba40fec904d8365441d8f529c1e37327296c2.

Für beide Repositories zusammen wurden 24 Lauf-Metadaten mit den jeweiligen
Attempt-/Job-/Schrittdaten, 18 originale GitHub-Artefakt-ZIPs und 97
gehashte Belegdateien gesichert. Jeder ZIP-Hash stimmt mit dem ursprünglichen
GitHub-Artefakt-Digest überein. Alle lokalen Dateihashes wurden unabhängig erneut
gelesen. Kopiert wurden außerdem die sanitisierten Identitäts-/Betreiberprotokolle.
Workflow-Konsolenlogs, private SSH-Schlüssel und Zugriffstokens wurden nicht gesammelt.
Die originalen credential-freien Rehearsal-ZIPs enthalten ihre damaligen Fixture-Logs;
sie wurden unverändert bewahrt. 37 Text-Einträge wurden zusätzlich auf übliche
GitHub-/Sonar-Tokenpräfixe und Private-Key-Header geprüft, ohne Treffer. Das ist kein
universeller Geheimnisdetektor; maßgeblich bleibt die reviewte sanitiserte Ausgabe.

## Explizite historische Lücken

Die ursprünglichen Batch-/Origin-ZIPs von Preparation-Lauf 40185013636 und der
ursprüngliche Readiness-ZIP von Lauf 40184021316 sind in GitHub nicht mehr gelistet.
Die damalige Aufbewahrung betrug nur einen Tag. Verbliebene Analyse-, Rehearsal-,
Intent- und Outcome-Belege wurden gesichert; die vollständigen aktuellen
Clean-/Coverage-Fehler-/Recovery-Belege vom 31. Oktober ebenfalls.

Es wurden keine fehlenden Originalbytes rekonstruiert und kein abgelaufener Handoff
als neue Abnahme ausgeführt. Die früher dokumentierte unabhängige Inspektion vor
Ablauf bleibt historischer Befund; dieses Archiv erlaubt keine erneute vollständige
Byte-Prüfung der verlorenen damaligen Preparation/Readiness-Archive. Die Lücke bleibt
in beiden repository-index.json und in der versionierten Archivaufzeichnung sichtbar.
Der erste abgebrochene lokale Capture ist ausdrücklich als INCOMPLETE gekennzeichnet;
latest-verified.json verweist ausschließlich auf den vollständig erneut geprüften Capture.

## Künftige Aufbewahrung und Ablauf

Dieser Aktivierungsreview hält Batch und Origin künftig 90 Tage vor, passend zu
Intent und Outcomes. Der LF-normalisierte Preparation-Hash wird neu gebunden.
[workflows PR #38](https://github.com/andregoepel/workflows/pull/38) bewahrt auch die
sanitisierten Sonar-Diagnose- und Readiness-ZIPs 90 Tage auf. Er muss zuerst per
Merge-Commit reviewt/übernommen werden. Der Consumer bindet dafür den unveränderlichen
Producer-/Tool-Pin 2bcbb5b97c3e6a3f28ab5f054d6bbbcea8026f7a. Der bestehende
Veröffentlichungs-Verifier-Pin bleibt unverändert; sein C#-Code ist identisch.

Die Speicherdauer ändert keine Receipt-Gültigkeit, CI-Altersgrenze, Baseline, Gates,
Quelle, Attempts oder Release-Berechtigung. Historische ZIPs/Manifeste autorisieren
keinen Upload. Lokal manuell archiviert bedeutet keine automatische Erfassung
künftiger Läufe und kein Offsite-Backup.

Nach jedem künftig separat genehmigten Release-/Abnahmelauf müssen die Original-
ZIPs rechtzeitig außerhalb Actions gesichert, ihre API-Digests verglichen und die
lokalen Hashes erneut gelesen werden. Fehlende Originale bleiben ein Fehler/Lücke;
niemals durch Rebuild, Rerun oder neue Ablaufzeiten des alten Nachweises ersetzen.
Der ursprüngliche Stand vom 31. Oktober bleibt im damaligen Betreiberprotokoll.
Die neue [Archivaufzeichnung](../scripts/sonar/publication/production-controls/archive-evidence-2026-11-01.json)
hält Ziel, Manifest-Hash, Grenzen und die getrennte Producer-/Verifier-Bindung fest.

Keine Pakete veröffentlicht, keine Tags erzeugt und keine Aktivierungs-PRs gemergt.
Echte Paket-/Symbol-Annahme und gehostete annotierte Release-Tag-Abnahme bleiben
separat freizugebende Punkte. Das Rollout-Issue bleibt offen.
