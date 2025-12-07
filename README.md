
<a href="https://github.com/mkowalik788/ProjektCV_v2">Nowy projekt (napisany zupełnie od nowa, z możliwością szerszej rozbudowy względem tego) jest już dostępny. Kliknij.</a>

# Projekt Firmy Obuwniczej
Projekt bazy danych Microsoft SQL Server dla małej firmy produkującej obuwie na zamówienie. Firma zatrudnia cholewkarzy, szewców, handlowców oraz personel pomocniczy (pakowanie, przygotowanie materiałów).


Projekt zawiera kompletną strukturę bazy danych (tabele), procedury składowane, triggery oraz widoki dla raportów i analiz biznesowych. Dokumentacja techniczna znajduje się bezpośrednio w kodzie jako komentarze, oraz w dole aktualnie przeglądanego pliku.

## Instalacja

Opcja 1: Nowa baza danych
- Plik `baza.sql` - czysta struktura bazy bez danych.
- Plik `uzupelnionabaza.sql` - baza z przykładowymi danymi testowymi

Opcja 2: Przywracanie z backupu  
- Plik `uzupelnionabaza.bak` - gotowa baza danych do przywrócenia

Opcja 3: Modułowa instalacja
Pliki zostały rozbite na moduły dla lepszej czytelności:
- `tabele.sql` - struktura tabel (należy ją uruchomić jako pierwszą)
- `triggery.sql` - automatyzacja procesów
- `procedury.sql` - procedury składowane
- `widoki.sql` - widoki raportowe
- `inserty.sql` - dane testowe

## Funkcjonalności
1. ŚLEDZENIE PRODUKCJI
- Przydział zadań - który szewc i cholewkarz robi które zamówienie,
- Postęp produkcji - ile par już wykonano, ile zostało (IloscDoWykonania),
- Statusy zamówień - "Nowe", "W trakcie produkcji", "Ukończono",
- Śledzenie materiałów - jakie materiały zostały pobrane z magazynu do produkcji.
2. ANALIZY I RAPORTY
- Raport miesięczny - liczba zamówień, wartość sprzedaży, ilość sprzedanych par,
- Analiza sprzedaży produktów - który produkt sprzedaje się najlepiej,
- Wydajność pracowników - ile zarobił każdy szewc i cholewkarz w danym miesiącu,
- Analiza klientów - ilu unikalnych klientów obsłużono w miesiącu,
- Stan magazynu - na ile par wystarczy materiałów.
3. ZARZĄDZANIE FINANSAMI
- Rozliczenia akordowe - automatyczne naliczanie wynagrodzeń szewcom i cholewkarzom,
- Wypłaty - procedury do wypłacania zarobków pracownikom,
- Wartość zamówień - automatyczne obliczanie wartości każdego zamówienia.
4. KONTROLA MAGAZYNU
- Śledzenie stanów - historia pobrań i dostaw materiałów,
- Alerty braków - sprawdzanie czy starczy materiałów przed uruchomieniem produkcji,
- Automatyczne pobieranie - materiały automatycznie pobierane przy przydziale produkcji.
5. ZARZĄDZANIE ZAMÓWIENIAMI
- Szczegóły zamówień - możliwość zamówienia wielu produktów w jednym zamówieniu,
- Edycja zamówień - zmiana ilości, produktów, cen,
- Archiwizacja - przechowywanie historii usuniętych zamówień.
6. BEZPIECZEŃSTWO DANYCH
- Automatyczne kopie zapasowe - archiwizacja usuniętych danych,
- Walidacja danych - sprawdzanie poprawności przed zapisem,
- Spójność danych - triggery pilnujące poprawnych relacji.

## Spis tabel, procedur, triggerów i widoków

Lista Tabel:
1. Pracownicy (zawiera dane wszystkich pracowników),
2. BazaFirm (zawiera dane wszystkich kontrahentów),
3. KategorieProduktów (zawiera dane wszystkich kategorii),
4. PodkategorieProduktów (zawiera dane wszystkich podkategorii),
5. Materiały (zawiera dane wszystkich materiałów - półproduktów do produkcji; StanMagazynowy zmienia się automatycznie poprzez triggery lub procedury),
6. HistoriaMagazynu (zawiera dane o ruchach pobieranych półproduktów z tabeli Materialy; inserty następują automatycznie przez triggery),
7. Produkty (zawiera wszystkie produkty, jakie oferuje firma, wraz z wynagrodzeniami szewca/cholewkarza, którzy mają płacone od każdej wyprodukowanej pary - B2B),
8. ProduktyMaterialy (zawiera informacje, jakie materiały są potrzebne do wyprodukowania danego produktu oraz ich ilość),
9. Zamowienia (zawiera informacje podstawowe o zamówieniach),
10. SzczegolyZamowienia (zawiera informacje dodatkowe o zamówieniach, jak np. ilość sprzedanych sztuk czy co zostało sprzedane; wiele rekordów do jednego Zamowienia),
11. PrzydzialProdukcji (tabela służby do wydawania towaru do produkcji; każdy insert/update/delete jakiegokolwiek rekordu wywołuje zmiany w innych tabelach poprzez triggery czy procedury, jak np. zmiana IloscDoWykonania w SzczegolyZamowienia czy pobiera półprodukty z tabeli Materialy),
12. UsunieteZamowienia (tabela uzupełnia się automatycznie poprzez trigger, po usunięciu Zamowienia),
13. UsunieteSzczegolyZamowienia (tabela uzupełnia się automatycznie poprzez trigger po usunięciu Zamowienia (usuwa wiele rekordów na raz przypisanych po ZamowienieID) bądź SzczegolowZamowienia),
14. UsunietePrzydzialProdukcji (tabela uzupełnia się automatycznie po delete PrzydzialuProdukcji (nie usuwa sie w przypadku usunięcia zamówienia, gdyż produkcja mogła już ruszyć a to spowodowałoby błędne rozliczanie z pracownikami),
15. HistoriaKonta (tabela zawiera informacje o ruchach wypłat (w przyszłości także o zakupy np. półproduktów, czy wypłaty dla innych pracowników niebędących na B2B). Inserty w tej tabeli następują automatycznie po uruchomieniu procedury odpowiedzialnej za wypłaty).

Lista procedur:
1. sp_Pracownicy_PokazWyplatyCholewkarzy @Miesiac INT, @Rok INT (Wyświetla wypłaty/zarobki wszystkich cholewkarzy za dany miesiąc i rok),
2. sp_Pracownicy_PokazWyplatySzewcow @Miesiac INT, @Rok INT (Wyświetla wypłaty/zarobki cholewkarzy za dany miesiąć i rok),
3. sp_Zamowienia_PokazSprzedazHandlowca (Wyświetla informacje o kwotach zebranych zamówień od handlowców),
4. sp_Pracownicy_Wyplata @PracownikID INT, @Wyplata DECIMAL(10,2) (Odejmuje stan konta w tabeli Pracownicy od wybranego pracownika, następnie tworzy rekord w HistoriaKonta o danym ruchu),
5. sp_Zamowienia_NoweZamowienie @HandlowiecID INT, @TerminMaksymalny DATE, @FirmaID INT (Tworzy nowe zamowienie w tabeli Zamowienia),
6. sp_SzczegolyZamowienia_NoweZamowienie @ZamowienieID INT, @ProduktID INT, @Ilosc DECIMAL(10,2), @CenaJednostki Decimal(10,2) (Dodaje nowe rekordy w SzczegolyZamowienia),
7. sp_SzczegolyZamowienia_ZmienSzczegolyZamowienia @SzczegolyZamowieniaID INT, @ProduktID INT, @Ilosc INT, @CenaJednostki Decimal(10,2) (Zmienia rekordy w SzczegolyZamowienia),
8. sp_SzczegolyZamowienia_usun @SzczegolyZamowieniaID INT (Usuwa dane SzczegolyZamowienia),
9. sp_Magazyn_SprawdzNaIleWystarczy @ProduktID INT (Sprawdza, na ile par obuwia wystarczy półproduktów w magazynie dla danego produktu);
10. sp_Magazyn_ZwiekszStanMagazynowy @MaterialID INT, @IloscDodawana DECIMAL(16,2) (Zwiększa stan magazynowy półproduktów w magazynie (Materialy));
11. sp_Raporty_RaportMiesieczny @Miesiac INT, @Rok INT (Wyświetla raport miesięczny dla wybranego: miesiąc, rok; zawiera on informacje o liczbie zamówień w miesiącu, łączną wartość zamówień, średnią wartość zamówienia, ilość sprzedanych par butów, ilość obsłużonych klientów i najlepiej sprzedający się produkt);

Lista Triggerów:
1. trg_Wyliczanie_WartoscZamowienia_Zamowienia_insert (Uruchamia się po dodaniu rekordu w SzczegolyZamowienia. Zlicza wartość zamówienia w tabeli Zamowienia);
2. trg_Wyliczanie_WartoscZamowienia_Zamowienia_update (Uruchamia się po zaktualizowaniu rekordu w SzczegolyZamowienia. Zlicza wartość zamówienia w tabeli Zamówienia);
3. trg_Wyliczanie_WartoscZamowienia_Zamowienia_delete (Uruchamia się po usunięciu rekordu w SzczegolyZamowienia. Zlicza wartość zamówienia w tabeli Zamówienia);
4. trg_SzczegolyZamowienia_IloscDoWykonania (Uruchamia się po dodaniu rekordu w SzczegolyZamowienia. Automatycznie uzupełnia IloscDoWykonania na podstawie Ilosc);
5. trg_PrzydzialProdukcji_IloscDoWykonania_insert_SzczegolyZamowienia (Uruchamia się po dodaniu rekordu w PrzydzialProdukcji. Automatycznie odlicza wartość IloscDoWykonania w tabeli SzczegolyZamowienia i ustawia status w tabeli Zamowienia na 'W trakcie produkcji', Jeżeli wykonano wszystkie zamówienia (tj. wartość IlośćDoWykonania we wszystkich SzczegolyZamowienia przypisanym do danego Zamowienia = 0), ustawia status na 'Ukończono');
6. trg_PrzydzialProdukcji_IloscDoWykonania_update_SzczegolyZamowienia (Uruchamia się po zaktualizowaniu rekordu w PrzydzialProdukcji. Przelicza wartość IloscDoWykonania w tabeli SzczegolyZamowienia aby się zgadzała, a następnie sprawdza, czy zamówienie nie zostanie zakończone (tj. czy nie wyprodukowano już wszystkich butów ze SzczegolyZamowienia, które to odpowiadają konkretnemu zamówieniu (Zamowienia). Jeśli tak, ustala 'Status' na 'Ukończone'.);
7. trg_PrzydzialProdukcji_IloscDoWykonania_delete_SzczegolyZamowienia (Uruchamia się po usunięciu rekordu w PrzydzialProdukcji. Przelicza wartość IloscDoWykonania w tabeli SzczegolyZamowienia);
8. trg_PrzydzialProdukcji_PrzekroczenieIlosci (Blokuje i zwraca błąd w przypadku przydzielenia produkcji większej ilości, niż jest zamówione (firma nie wykonuje zamówień na zapas). Wykonuje sie po dodaniu rekordu w PrzydzialProdukcji);
9. trg_PrzydzialProdukcji_Wyplata_INSERT (Uruchamia się po dodaniu rekordu w PrzydzialProdukcji. Przelicza nowy StanKonta (wypłata) cholewkarzy i szewców w tabeli Pracownicy);
10. trg_PrzydzialProdukcji_IloscDoWykonania_update_Wyplata (Uruchamia się po zaktualizowaniu rekordu w PrzydzialProdukcji. Aktualizuje StanKonta (wypłata) cholewkarzy i szewców w tabeli Pracownicy);
11. trg_PrzydzialProdukcji_WyplataPracownika_delete (Uruchamia się po usunięciu rekordu w PrzydzialProdukcji. Odejmuje od StanKonta odpowiednią kwotę (wypłatę) w tabeli Pracownicy);
12. trg_Zamowienia_insert_UstawStatus_UstawDate (Uruchamia się po dodaniu rekordu w Zamowienia. Ustawia status (Status) na 'Nowe');
13. trg_PrzydzialProdukcji_insert_Materialy (Uruchamia się po dodaniu rekordu w PrzydzialProdukcji. Automatycznie aktualizuje StanMagazynowy dla materiałów (półproduktów), które są przypisane do wydawanego produktu do produkcji. Dodatkowo tworzy nowy rekord w tabeli HistoriaMagazynu uzupełniając MaterialID, pobraną ilość, ustawia wartość kolumny TypRuchu na 'Produkcja' oraz ustawia datę);
14. trg_PrzydzialProdukcji_update_Materialy (Uruchamia się po zaktualizowaniu rekordu w PrzydzialProdukcji. Automatycznie aktualizuje StanMagazynowy dla produktów, które są przypisane do wydawanego produktu do produkcji. Dodatkowo tworzy nowe rekordy (odjęcie i przyjęcie) w tabeli HistoriaMagazynu uzupełniając automatycznie wszystkie rekordy);
15. trg_PrzydzialProdukcji_delete_Materialy (Uruchamia się po usunięciu rekordu w PrzydzialProdukcji. Aktualizuje StanMagazynowy dla produków, które są przypisane do produktu, którego produkcję cofnięto. Tworzy nowy rekord w tabeli HistoriaMagazynu, uzupełniając automatycznie wszystkie rekordy);
16. trg_PrzydzialProdukcji_insert_ProduktyMaterialy_braki (Trigger blokujący możliwość wydania towaru do produkcji, jeśli nie ma wystarczająco materiałów (półproduktów) w magazynie);
18. trg_Zamowienia_delete_UsunieteZamowienia_historia (Uruchamia się przed usunięciem zamówienia (INSTEAD OF DELETE). Tworzy rekordy w tabeli UsunieteZamowienia oraz UsunieteSzczegolyZamowienia. Usuwa automatyczniee SzczegolyZamowienia (czyli podległe rekordy do danego zamówienia), a następnie uruchamia usunięcie zamówienia. Nie rusza natomiast podległej tabeli - PrzydzialProdukcji, bo pracownikowi zostałaby automatycznie usunięta wypłata);

Lista widoków:
1. vvPracownicy_OstatniMiesiąc_Szewc (Pokazuje sumę zarobków szewców za ostatnie 30 dni);
2. vvPracownicy_OstatniMiesiąc_Cholewkarz (Pokazuje sumę zarobków dla cholewkarzy za ostatnie 30 dni);
3. vvPracownicy_OstatniMiesiac_Handlowiec (Pokazuje łączną wartość sprzedaży handlowców za ostatnie 30 dni);
4. vvZamowienia_OstatniMiesiac_NajlepszaSprzedazProduktu (Pokazuje produkty z łączną ilością sprzedanych par butów i łączną wartość sprzedaży za ostatnie 30 dni);
5. vv_Materialy_NiskiStanMagazynowy (Pokazuje półprodukty w magazynie, których ilość jest mniejsza niż 50)
