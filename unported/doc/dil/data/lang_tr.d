/++
  Author: Aziz Köksal
  License: GPL3
+/

string lang_code = "tr";

string[] messages = [
  // Lexer messages:
  "illegal karakter bulundu: '{0}'",
//   "geçersiz Unikod karakteri.",
  "geçersiz UTF-8 serisi: '{0}'",
  // ''
  "kapanmamış karakter sabiti.",
  "boş karakter sabiti.",
  // #line
  "'#' karakter'den sonra 'line' beklendi.",
  "'#line''den sonra rakam beklendi.",
//   `filespec dizgisi beklendi (e.g. "yol\dosya".)`,
  "kapanmamış filespec dizgisi.",
  "özel belirtici'den (special token) sonra yeni bir satır beklendi.",
  // ""
  "kapanmamış çift tırnak dizgisi.",
  // x""
  "heks sayı olmayan karakter '{0}' heks dizgisi içinde bulundu.",
  "heks dizginin içindeki sayılar çifter çifter olmalıdır.",
  "kapanmamış heks dizgisi.",
  // /* */ /+ +/
  "kapanmamış blok açıklaması (/* */).",
  "kapanmamış iç içe koyulabilen açıklaması (/+ +/).",
  // `` r""
  "kapanmamış çiğ dizgisi.",
  "kapanmamış ters tırnak dizgisi.",
  // \x \u \U
  "tanımlanmamış çıkış serisi '{0}' bulundu.",
  "geçersiz Unikod çıkış serisi '{0}' bulundu.",
  "heksadesimal çıkış serisi sayıları yeterli değil: '{0}'",
  // \&[a-zA-Z][a-zA-Z0-9]+;
  "tanımlanmamış HTML varlık '{0}'",
  "kapanmamış HTML varlık '{0}'.",
  "HTML varlık bir harf ile başlamalı.",
  // integer overflows
  "desimal rakamın bit işareti taşdı.",
  "desimal rakam taşması.",
  "heksadesimal rakam taşması.",
  "binari rakam taşması.",
  "oktal rakam taşması.",
  "float rakam taşması.",
  "8 ve 9 sayılar oktal rakamlar'da geçersizdir.",
  "geçersiz heks rakam; minimum bir heks sayı gereklidir.",
  "geçersiz binari rakam; minimum bir binari sayı gereklidir.",
  "bir heksadesimal float rakamın üsü gereklidir.",
  "heksadesimal float üsler desimal sayı ile başlamalı.",
  "üsler desimal sayı ile başlamalı.",

  // Parser messages
  "'{0}' beklendi, ama '{1}' bulundu.",
  "'{0}' lüzumsuz.",
  "şablon tuple parametre son sırada olmalı.",
  "fonksiyonun 'in' kontratı daha önceden ayrıştırılmış.",
  "fonksiyonun 'out' kontratı daha önceden ayrıştırılmış.",
  "bağlantı tüp (linkage type) belirtilmedi.",
  "bilinmeyen bağlantı tüpü (linkage type) '{0}'; geçerli olanlar C, C++, D, Windows, Pascal ve System.",
  "expected one or more base classes, not '{0}'.", // TODO: translate
  "base classes are not allowed in forward declarations.", // TODO: translate

  // Help messages:
  `dil v{0}
Copyright (c) 2007-2008, Aziz Köksal. Lisans GPL3.

Komutlar:
{1}
Belirli komut'a yardım edinmek için 'dil help <komut>' yazınız.

Bu yazılım {2} v{3} ile {4} tarihinde derletilmiş.`,

  `Bir D kaynak kodundan XML veya HTML dosyası oluştur.
Kullanım:
  dil gen dosya.d [Seçenekler]

Seçenekler:
  --syntax         : söz dizimi için etiketler yazdır
  --xml            : XML biçimi kullan (varsayılır)
  --html           : HTML biçimi kullan

Örnek:
  dil gen Parser.d --html --syntax > Parser.html`,

  ``,
];
