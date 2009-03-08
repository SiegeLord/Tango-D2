/++
  Author: Jari-Matti Mäkelä <jmjm@iki.fi>
  License: GPL3
+/

string lang_code = "fi";

string[] messages = [
  // Lexer messages:
  "virheellinen merkki: '{0}'",
//   "virheellinen Unicode-merkki.",
  "virheellinen UTF-8-merkkijono: '{0}'",
  // ''
  "päättämätön merkkiliteraali.",
  "tyhjä merkkiliteraali.",
  // #line
  "odotettiin rivinumeroa '#':n jälkeen.",
  "odotettiin kokonaislukua #line:n jälkeen",
//   `odotettiin tiedostomäärittelyn merkkijonoa (esim. "polku\tiedostoon")`,
  "päättämätön tiedostomäärittely.",
  "odotettiin päättävää rivinvaihtoa erikoismerkin jälkeen.",
  // ""
  "päättämätön merkkijonoliteraali.",
  // x""
  "ei-heksamerkki '{0}' heksajonossa.",
  "pariton määrä heksanumeroita heksajonossa.",
  "päättämätön heksajono.",
  // /* */ /+ +/
  "päättämätön lohkokommentti (/* */).",
  "päättämätön sisäkkäinen kommentti (/+ +/).",
  // `` r""
  "päättämätön raakamerkkijono.",
  "päättämätön gravisaksenttimerkkijono.",
  // \x \u \U
  "määrittelemätön escape-sekvenssi {0}.",
  "virheellinen Unicode escape-merkki '{0}'.",
  "riittämätön määrä heksanumeroita escape-sekvenssissä: '{0}'",
  // \&[a-zA-Z][a-zA-Z0-9]+;
  "määrittelemätön HTML-entiteetti '{0}'",
  "päättämätön HTML-entiteetti {0}.",
  "HTML-entiteettien tulee alkaa kirjaimella.",
  // integer overflows
  "desimaaliluku ylivuotaa etumerkin.",
  "desimaaliluvun ylivuoto.",
  "heksadesimaaliluvun ylivuoto.",
  "binääriluvun ylivuoto.",
  "oktaaliluvun ylivuoto.",
  "liukuluvun ylivuoto.",
  "numerot 8 ja 9 eivät ole sallittuja oktaaliluvuissa.",
  "virheellinen heksaluku; odotettiin vähintään yhtä heksanumeroa.",
  "virheellinen binääriluku; odotettiin vähintään yhtä binäärinumeroa.",
  "heksadesimaalisen liukuluvun eksponentti vaaditaan.",
  "heksadesimaalisen liukuluvun eksponentin tulee alkaa numerolla.",
  "eksponenttien tulee alkaa numerolla.",

  // Parser messages
  "odotettiin '{0}':a, mutta luettiin '{1}'.",
  "'{0}' on redundantti.",
  "tupla voi esiintyä ainoastaan mallin viimeisenä parametrina.",
  "funktion alkuehto jäsennettiin jo.",
  "funktion loppuehto jäsennettiin jo.",
  "linkitystyyppiä ei määritelty.",
  "tunnistamaton linkitystyyppi '{0}'; sallittuja tyyppejä ovat C, C++, D, Windows, Pascal ja System.",
  "odotettiin yhtä tai useampaa luokkaa, ei '{0}':ta.",
  "kantaluokat eivät ole sallittuja etukäteismäärittelyissä.",

  // Help messages:
  `dil v{0}
Copyright (c) 2007-2008, Aziz Köksal. GPL3-lisensöity.

Alikomennot:
{1}
Lisäohjeita tietystä alitoiminnosta saa kirjoittamalla 'dil help <toiminto>'.

Käännetty {2}:n versiolla {3} {4}.`,

  `Luo XML- tai HTML-dokumentti D-lähdekoodista.

Käyttö:
  dil gen tiedosto.d [Valinnat]

Valinnat:
  --syntax         : luo elementtejä syntaksipuun mukaisesti
  --xml            : käytä XML-muotoa (oletus)
  --html           : käytä HTML-muotoa

Esimerkki:
  dil gen Parser.d --html --syntax > Parser.html`,

  ``,
];
