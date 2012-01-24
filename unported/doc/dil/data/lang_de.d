/++
  Author: Aziz Köksal
  License: GPL3
+/

string lang_code = "de";

string[] messages = [
  // Lexer messages:
  "illegales Zeichen gefunden: '{0}'",
//   "ungültiges Unicodezeichen.",
  "ungültige UTF-8-Sequenz: '{0}'",
  // ''
  "unterminiertes Zeichenliteral.",
  "leeres Zeichenliteral.",
  // #line
  "erwartete 'line' nach '#'.",
  "Ganzzahl nach #line erwartet.",
//   `erwartete Dateispezifikation (z.B. "pfad\zur\datei".)`,
  "unterminierte Dateispezifikation (filespec.)",
  "ein Special Token muss mit einem Zeilenumbruch abgeschlossen werden.",
  // ""
  "unterminiertes Zeichenkettenliteral.",
  // x""
  "Nicht-Hexzeichen '{0}' in Hexzeichenkette gefunden.",
  "ungerade Anzahl von Hexziffern in Hexzeichenkette.",
  "unterminierte Hexzeichenkette.",
  // /* */ /+ +/
  "unterminierter Blockkommentar (/* */).",
  "unterminierter verschachtelter Kommentar (/+ +/).",
  // `` r""
  "unterminierte rohe Zeichenkette.",
  "unterminierte Backquote-Zeichenkette.",
  // \x \u \U
  "undefinierte Escapesequenz '{0}' gefunden.",
  "ungültige Unicode-Escapesequenz '{0}' gefunden.",
  "unzureichende Anzahl von Hexziffern in Escapesequenz: '{0}'",
  // \&[a-zA-Z][a-zA-Z0-9]+;
  "undefinierte HTML-Entität '{0}'",
  "unterminierte HTML-Entität '{0}'.",
  "HTML-Entitäten müssen mit einem Buchstaben beginnen.",
  // integer overflows
  "Dezimalzahl überläuft im Vorzeichenbit.",
  "Überlauf in Dezimalzahl.",
  "Überlauf in Hexadezimalzahl.",
  "Überlauf in Binärzahl.",
  "Überlauf in Oktalzahl.",
  "Überlauf in Fließkommazahl.",
  "die Ziffern 8 und 9 sind in Oktalzahlen unzulässig.",
  "ungültige Hexzahl; mindestens eine Hexziffer erforderlich.",
  "ungültige Binärzahl; mindestens eine Binärziffer erforderlich.",
  "der Exponent einer hexadezimalen Fließkommazahl ist erforderlich.",
  "Hexadezimal-Exponenten müssen mit einer Dezimalziffer anfangen.",
  "Exponenten müssen mit einer Dezimalziffer anfangen.",

  // Parser messages:
  "erwartete '{0}', fand aber '{1}'.",
  "'{0}' ist redundant.",
  "Template-Tupel-Parameter dürfen nur am Ende auftreten.",
  "der 'in'-Vertrag der Funktion wurde bereits geparsed.",
  "der 'out'-Vertrag der Funktion wurde bereits geparsed.",
  "es wurde kein Verbindungstyp angegeben.",
  "unbekannter Verbindungstyp '{0}'; gültig sind C, C++, D, Windows, Pascal und System.",
  "erwartete eine oder mehrere Basisklassen, nicht '{0}'.",
  "Basisklassen sind in Vorwärtsdeklarationen nicht erlaubt.",

  // Help messages:
  `dil v{0}
Copyright (c) 2007-2008, Aziz Köksal. Lizensiert unter der GPL3.

Befehle:
{1}
Geben Sie 'dil help <Befehl>' ein, um mehr Hilfe zu einem bestimmten Befehl zu
erhalten.

Kompiliert mit {2} v{3} am {4}.`,

  `Generiere ein XML- oder HTML-Dokument aus einer D-Quelltextdatei.
Verwendung:
  dil gen datei.d [Optionen]

Optionen:
  --syntax         : generiere Elemente für den Syntaxbaum
  --xml            : verwende XML-Format (voreingestellt)
  --html           : verwende HTML-Format

Beispiel:
  dil gen Parser.d --html --syntax > Parser.html`,

  ``,
];
