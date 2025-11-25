--Opis firmy:
--Mała firma produkująca obuwie damskie na zamówienie (obsługuje tylko klientów B2B). Posiada dwóch handlowców, 6 szewców, 6 cholewkarzy, 2 osoby do pakowania + 2 osoby do pomocy przy przygotowaniu (np. profilowanie materiałów).
--Szewce i cholewkarze są zatrudnieni w oparciu o umowe B2B i mają płacone od wykonanej pary (akord).
--Tabela Pracownicy zawiera podstawowe informacje o pracownikach wraz z ich stanem konta jeśli ich wynagrodzenie jest płacone na akord (wyliczane na podstawie tabel 'Produkty' i 'PrzydzialProdukcji').

--Tabela Pracownicy zawiera informacje o pracownikach:
CREATE TABLE Pracownicy (
	PracownikID INT IDENTITY(1,1) PRIMARY KEY,
	Imie NVARCHAR(50) NOT NULL,
	Nazwisko NVARCHAR(50) NOT NULL,
	Stanowisko NVARCHAR(50) NOT NULL, --Szewc, Cholewkarz, Pakowanie, Handlowiec
	DataZatrudnienia DATE DEFAULT GETDATE(),
	Zatrudniony NVARCHAR(6), --Tak/Nie
	RodzajUmowy NVARCHAR(20) NOT NULL, --UoP/Zlecenie/B2B
	StanKonta DECIMAL(10,2), --Wyliczany automatycznie dla szewców i cholewkarzy na podstawie tabeli PrzydzialProdukcji
	CONSTRAINT CHK_Pracownicy_Zatrudniony CHECK (Zatrudniony IN ('Tak', 'Nie')),
	CONSTRAINT CHK_Pracownicy_RodzajUmowy CHECK (RodzajUmowy IN ('UoP', 'B2B', 'Zlecenie')),
	CONSTRAINT CHK_Pracownicy_Stanowisko CHECK (Stanowisko IN ('Cholewkarz', 'Szewc', 'Pomocnik', 'Handlowiec'))
);

--Firma obsługuje tylko pracowników B2B. Tabela zawiera informacje o firmach/klientach:

CREATE TABLE BazaFirm (
	FirmaID INT IDENTITY(1,1) PRIMARY KEY,
	NazwaFirmy NVARCHAR(50) NOT NULL,
	AdresFirmy NVARCHAR(100) NOT NULL,
	NIP NVARCHAR(10) NOT NULL
);

--Głowne kategorie produktów (np. Botki, Kozaki, Czółenka):

CREATE TABLE KategorieProduktow (
	KategoriaID INT IDENTITY(1,1) PRIMARY KEY,
	NazwaKategorii NVARCHAR(40) NOT NULL
);

--Tabela zawiera informacje o podkategoriach produktów (np. Trapery, Sztyblety, Na szpilce, Na słupku):

CREATE TABLE PodkategorieProduktow (
	PodkategoriaID INT IDENTITY(1,1) PRIMARY KEY,
	NazwaPodkategorii NVARCHAR(40) NOT NULL,
	KategoriaID INT NOT NULL,
	CONSTRAINT FK_Podkategorie_Kategorie FOREIGN KEY(KategoriaID) REFERENCES KategorieProduktow(KategoriaID)
);

--Tabela Materialy zawiera informacje o półproduktach potrzebnych do wykonania butów (produktów):

CREATE TABLE Materialy (
	MaterialID INT IDENTITY(1,1) PRIMARY KEY,
	NazwaMaterialu NVARCHAR(50) NOT NULL,
	KategoriaMaterialu NVARCHAR(50) NOT NULL, --np. Obcas, Zamek, Brandzel
	Kolor NVARCHAR(50),
	StanMagazynowy DECIMAL(10,2)
);

--Tabela HistoriaMagazynu zawiera historię kiedy pobrano i ile półproduktów z magazynu (rekordy tworzą sie poprzez Trigger):

CREATE TABLE HistoriaMagazynu (
    HistoriaMagazynuID INT IDENTITY(1,1) PRIMARY KEY,
    MaterialID INT,
    Ilosc DECIMAL(16,2),
    TypRuchu NVARCHAR(15),
    Data DATE DEFAULT GETDATE(),
    CONSTRAINT FK_HistoriaMagazynu_Materialy FOREIGN KEY(MaterialID) REFERENCES Materialy(MaterialID)
)

--Tabela Produkty zawiera bazę produktów (gotowych butów) które oferuje firma:

CREATE TABLE Produkty (
	ProduktID INT IDENTITY(1,1) PRIMARY KEY,
	NazwaProduktu NVARCHAR(50) NOT NULL,
	PodkategoriaID INT NOT NULL,
	KosztCholewkarza DECIMAL(6,1),
	KosztSzewca DECIMAL(6,1),
	Cena DECIMAL(8,2),
	ZdjecieURL NVARCHAR(255), --Linki do zdjęcia produktu
	CONSTRAINT FK_Produkty_Kategoria FOREIGN KEY(PodkategoriaID) REFERENCES PodkategorieProduktow(PodkategoriaID),
	CONSTRAINT CHK_Produkty_Cena CHECK (Cena > 0),
	CONSTRAINT CHK_Produkty_KosztCholewkarza CHECK (Cena > 0),
	CONSTRAINT CHK_Produkty_KosztSzewca CHECK (Cena > 0)
);

--Tabela ProduktyMaterialy zawiera informacje, czego potrzebuje dany produkt aby go wyprodukować. Informacje szczegółowe o materiałach znajdują się w tabeli Materiały. :

CREATE TABLE ProduktyMaterialy (
	ProduktyMaterialyID INT IDENTITY(1,1) PRIMARY KEY,
	ProduktID INT NOT NULL,
	MaterialID INT NOT NULL,
	Ilosc DECIMAL(6,2) NOT NULL,
	CONSTRAINT FK_ProduktyMaterialy_Produkty FOREIGN KEY(ProduktID) REFERENCES Produkty(ProduktID),
	CONSTRAINT FK_ProduktyMaterialy_Materialy FOREIGN KEY(MaterialID) REFERENCES Materialy(MaterialID)
);

--Tabela Zamowienia zawiera informacje o zamówieniach, jakie zebrał handlowiec bądź szef (jest to mała firma) i wprowadził je do systemu:

CREATE TABLE Zamowienia (
	ZamowienieID INT IDENTITY(1,1) PRIMARY KEY,
	HandlowiecID INT NOT NULL,
	DataZamowienia DATE DEFAULT GETDATE(),
	TerminMaksymalny DATE,
	KlientID INT NOT NULL,
	WartoscZamowienia DECIMAL(10,2),
	Status NVARCHAR(20),
	CONSTRAINT FK_Zamowienia_Pracownicy FOREIGN KEY(HandlowiecID) REFERENCES Pracownicy(PracownikID),
	CONSTRAINT FK_Zamowienia_Klienci FOREIGN KEY(KlientID) REFERENCES BazaFirm(FirmaID)
);

--Tabela SzczegolyZamowienia zawiera informacje o szczegółach zamówienia, jak np. ilość czy cena za jednostkę (Tabela wymagana, gdy klient zamówi kilka pozycji do jednego zamówienia):

CREATE TABLE SzczegolyZamowienia (
	SzczegolyZamowieniaID INT IDENTITY(1,1) PRIMARY KEY,
	ZamowienieID INT NOT NULL,
	ProduktID INT NOT NULL,
	Ilosc INT NOT NULL,
	CenaJednostki DECIMAL(6,2) NOT NULL, --Cenę wpisuje Handlowiec. Powodem może być fakt, że stosuje różne ceny dla różnych klientów.
	IloscDoWykonania INT, --Obliczane automatycznie za pomocą triggerów. Pozwala to pobierać informacje czy zlecenie jest wykonane, czy nie.
	CONSTRAINT FK_SzczegolyZamowienia_Zamowienia FOREIGN KEY(ZamowienieID) REFERENCES Zamowienia(ZamowienieID),
	CONSTRAINT FK_SzczegolyZamowienia_Produkty FOREIGN KEY(ProduktID) REFERENCES Produkty(ProduktID)
);

--Tabela PrzydzialProdukcji zawiera informacje o tym, kto będzie odpowiedzialny za dane zamówienie (w przypadku naszej firmy szewc, cholewkarz). Określa też, ile par (jednostek) wykona dany pracownik, co jest niezbędne do wyliczenia, czy zamówienie zostało już wyprodukowane.

CREATE TABLE PrzydzialProdukcji (
	PrzydzialProdukcjiID INT IDENTITY(1,1) PRIMARY KEY,
    SzczegolyZamowieniaID INT NOT NULL,
	ProduktID INT NOT NULL,
    CholewkarzID INT NOT NULL,
	SzewcID INT NOT NULL,
    IloscPrzydzielona INT NOT NULL, --IlośćPrzydzielona obliczana automatycznie za pomocą Triggera.
    DataPrzydzielenia DATE DEFAULT GETDATE(), 
    CONSTRAINT FK_PrzydzialProdukcji_SzczegolyZamowienia FOREIGN KEY(SzczegolyZamowieniaID) REFERENCES SzczegolyZamowienia(SzczegolyZamowieniaID),
	CONSTRAINT FK_PrzydzialProdukcji_CholewkarzID FOREIGN KEY(CholewkarzID) REFERENCES Pracownicy(PracownikID),
	CONSTRAINT FK_PrzydzialProdukcji_PracownikID_Szewc FOREIGN KEY(SzewcID) REFERENCES Pracownicy(PracownikID),
	CONSTRAINT FK_PrzydzialProdukcji_Produkty FOREIGN KEY(ProduktID) REFERENCES Produkty(ProduktID)
);

--Tabela UsunieteZamowienia przedstawia zamówienia, które zostały usunięte. Rekordy w tej tabeli tworzą się automatycznie - są wywoływane przez trigger:

CREATE TABLE UsunieteZamowienia (
	ZamowienieID INT NOT NULL,
	HandlowiecID INT NOT NULL,
	DataZamowienia DATE,
	DataUsuniecia DATE DEFAULT GETDATE(),
	TerminMaksymalny DATE,
	KlientID INT NOT NULL,
	WartoscZamowienia DECIMAL(10,2)
);
GO

--Tabela UsunieteSzczegolyZamowienia przedstawia usunięte szczegóły zamówienia. Rekordy w tej tabeli tworzą się automatycznie (trigger) po usunięciu rekordu w SzczegolyZamowienia (działa razem lub osobno (w zależności od sytuacji) z tabelą opisaną powyżej):

CREATE TABLE UsunieteSzczegolyZamowienia (
	SzczegolyZamowieniaID INT NOT NULL,
	ZamowienieID INT NOT NULL,
	ProduktID INT NOT NULL,
	Ilosc INT NOT NULL,
	CenaJednostki DECIMAL(6,2) NOT NULL,
	IloscDoWykonania INT,
	DataUsuniecia DATE DEFAULT GETDATE(),
	PowodUsuniecia NVARCHAR(50)
);
GO

--Tabela UsunietePrzydzialProdukcji przedstawia usunięte rekordy w tabeli PrzydzialProdukcji (nie może się usuwać automatycznie z powyższymi, bo to walidowałoby z wypłatami pracowników i ich poprawnym obliczaniem i nie miałoby to logicznego sensu):

CREATE TABLE UsunietePrzydzialProdukcji (
	PrzydzialProdukcjiID INT,
    SzczegolyZamowieniaID INT NOT NULL,
	ProduktID INT NOT NULL,
    CholewkarzID INT NOT NULL,
	SzewcID INT NOT NULL,
    IloscPrzydzielona INT NOT NULL,
    DataPrzydzielenia DATE,
	DataUsuniecia DATE DEFAULT GETDATE(),
	PowodUsuniecia NVARCHAR(50)
);
GO

--Tabela HistoriaKonta przedstawia historię z wypłat pracowników. Rekordy w niej tworzą się automatycznie po użyciu procedur. W przyszłości będzie zawierać więcej informacji, np. podczas stworzenia zamówień (przychodzące ja i wychodzące):

CREATE TABLE HistoriaKonta (
	HistoriaKontaID INT IDENTITY(1,1) PRIMARY KEY,
	KwotaWyplaty DECIMAL(10,2),
	PowodWyplaty NVARCHAR(50),
	DataWyplaty DATE DEFAULT GETDATE()
);
GO

--///////////// TRIGGERY \\\\\\\\\\\\\--

--Trigger dla wyliczania Zamowienia.WartoscZamowienia po insert:

CREATE Trigger trg_Wyliczanie_WartoscZamowienia_Zamowienia_insert
ON SzczegolyZamowienia
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE Zamowienia
	SET WartoscZamowienia = (
		SELECT SUM(Ilosc * CenaJednostki)
		FROM SzczegolyZamowienia
		WHERE SzczegolyZamowienia.ZamowienieID = Zamowienia.ZamowienieID AND ZamowienieID IN (SELECT DISTINCT ZamowienieID FROM inserted)
	)
	WHERE ZamowienieID IN (SELECT DISTINCT ZamowienieID FROM inserted);
END;
GO

--Trigger dla wyliczania Zamowienia.WartoscZamowienia po update:

CREATE Trigger trg_Wyliczanie_WartoscZamowienia_Zamowienia_update
ON SzczegolyZamowienia
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE Zamowienia
	SET WartoscZamowienia = (
		SELECT SUM(Ilosc * CenaJednostki)
		FROM SzczegolyZamowienia
		WHERE SzczegolyZamowienia.ZamowienieID = Zamowienia.ZamowienieID ) 
	WHERE ZamowienieID IN (
		SELECT DISTINCT ZamowienieID FROM inserted
		UNION
		SELECT DISTINCT ZamowienieID FROM deleted
		);

END;
GO

--Trigger dla wyliczania Zamowienia.WartoscZamowienia po delete:

CREATE Trigger trg_Wyliczanie_WartoscZamowienia_Zamowienia_delete
ON SzczegolyZamowienia
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE Zamowienia
	SET WartoscZamowienia = (
		SELECT SUM(Ilosc * CenaJednostki)
		FROM SzczegolyZamowienia
		WHERE SzczegolyZamowienia.ZamowienieID = Zamowienia.ZamowienieID AND ZamowienieID IN (SELECT DISTINCT ZamowienieID FROM deleted)
	)
	WHERE ZamowienieID IN (SELECT DISTINCT ZamowienieID FROM deleted);
END;
GO

--Trigger przydzielający automatycznie IloscDoWykonania podczas tworzenia rekordów w tabeli SzczegolyZamowienia

CREATE Trigger trg_SzczegolyZamowienia_IloscDoWykonania
ON SzczegolyZamowienia
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE s
	SET IloscDoWykonania = i.Ilosc
	FROM SzczegolyZamowienia s
	INNER JOIN inserted i ON s.SzczegolyZamowieniaID = i.SzczegolyZamowieniaID;
END;
GO

--Trigger wyliczający ile jeszcze zostało do wyprodukowania obuwia. Aktualizuje pole 'IloscDoWykonania' w SzczegolyZamowienia. AKtualizuje także status w Zamowienia, jeśli wykonano wszystkie SzczegolyZamowienia (IloscDoWykonania=0), gdzie ich jest powiązane z Zamowienia.

CREATE TRIGGER trg_PrzydzialProdukcji_IloscDoWykonania_insert_SzczegolyZamowienia
ON PrzydzialProdukcji
AFTER INSERT
AS
BEGIN

	UPDATE s
	SET IloscDoWykonania = s.IloscDoWykonania - i.IloscPrzydzielona
	FROM SzczegolyZamowienia s
	INNER JOIN inserted i ON s.SzczegolyZamowieniaID=i.SzczegolyZamowieniaID;

	UPDATE z
	SET Status = 'W trakcie produkcji'
	FROM zamowienia z
	INNER JOIN SzczegolyZamowienia s ON z.ZamowienieID=s.ZamowienieID
	INNER JOIN inserted i ON i.SzczegolyZamowieniaID=s.SzczegolyZamowieniaID;

	UPDATE z
	SET Status = 'Ukończono' 
	FROM zamowienia z
	INNER JOIN SzczegolyZamowienia s ON s.ZamowienieID=z.ZamowienieID
	INNER JOIN inserted i ON i.SzczegolyZamowieniaID=s.SzczegolyZamowieniaID
	WHERE NOT EXISTS (
		SELECT 1
		FROM SzczegolyZamowienia sz
		WHERE sz.IloscDoWykonania > 0 AND sz.ZamowienieID=z.ZamowienieID);

END;
GO

--Trigger wyliczający poprawną wartość IlośćDoWykonania w tabeli SzczegolyZamowienia po aktualizacji. Sprawdza także, czy zmiana wartości nie kończy zamówienia (tj. czy wyprodukowano wszystkie buty). Jeśli kończy, ustawia jego status na 'Ukończono'.

CREATE TRIGGER trg_PrzydzialProdukcji_IloscDoWykonania_update_SzczegolyZamowienia
ON PrzydzialProdukcji
AFTER UPDATE
AS
BEGIN
	WITH Zmiany AS (
        SELECT 
            d.SzczegolyZamowieniaID,
            SUM(d.IloscPrzydzielona) as StaraIlosc,
            SUM(i.IloscPrzydzielona) as NowaIlosc
        FROM deleted d
        INNER JOIN inserted i ON d.PrzydzialProdukcjiID = i.PrzydzialProdukcjiID
        GROUP BY d.SzczegolyZamowieniaID
    )
    
    UPDATE s
    SET IloscDoWykonania = s.IloscDoWykonania + z.StaraIlosc - z.NowaIlosc
    FROM SzczegolyZamowienia s
    INNER JOIN Zmiany z ON s.SzczegolyZamowieniaID = z.SzczegolyZamowieniaID;

	UPDATE z
	SET Status = 'Ukończono' 
	FROM zamowienia z
	INNER JOIN SzczegolyZamowienia s ON s.ZamowienieID=z.ZamowienieID
	INNER JOIN inserted i ON i.SzczegolyZamowieniaID=s.SzczegolyZamowieniaID
	WHERE NOT EXISTS (
		SELECT 1
		FROM SzczegolyZamowienia sz
		WHERE sz.IloscDoWykonania > 0 AND sz.ZamowienieID=z.ZamowienieID)


END;
GO

--Trigger obliczający IloscDoWykonania w tabeli SzczegolyZamowienia. Uruchamia się po usunięciu rekordu w PrzydzialProdukcji:

CREATE TRIGGER trg_PrzydzialProdukcji_IloscDoWykonania_delete_SzczegolyZamowienia
ON PrzydzialProdukcji
AFTER DELETE
AS
BEGIN
	UPDATE s
	SET IloscDoWykonania = s.IloscDoWykonania + d.IloscPrzydzielona
	FROM SzczegolyZamowienia s
	INNER JOIN deleted d on s.SzczegolyZamowieniaID=d.SzczegolyZamowieniaID;
END;
GO

--Trigger sprawdzający, czy ilość wydawanego towaru do produkcji nie jest większa niż ilość w zamówieniu:

CREATE TRIGGER trg_PrzydzialProdukcji_PrzekroczenieIlosci
ON PrzydzialProdukcji
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (
		SELECT 1
		FROM (
			SELECT 
				i.SzczegolyZamowieniaID,
				SUM(i.IloscPrzydzielona) as NowePrzydzialy
			FROM inserted i
			GROUP BY i.SzczegolyZamowieniaID
		) as nowe
		INNER JOIN (
			SELECT 
				pp.SzczegolyZamowieniaID,
				SUM(pp.IloscPrzydzielona) as IstniejacePrzydzialy
			FROM PrzydzialProdukcji pp
			WHERE pp.SzczegolyZamowieniaID IN (SELECT SzczegolyZamowieniaID FROM inserted)
				AND pp.PrzydzialProdukcjiID NOT IN (SELECT PrzydzialProdukcjiID FROM inserted)
			GROUP BY pp.SzczegolyZamowieniaID
		) as istniejace ON istniejace.SzczegolyZamowieniaID = nowe.SzczegolyZamowieniaID
		INNER JOIN SzczegolyZamowienia s ON s.SzczegolyZamowieniaID = nowe.SzczegolyZamowieniaID
		WHERE (ISNULL(istniejace.IstniejacePrzydzialy, 0) + nowe.NowePrzydzialy) > s.IloscDoWykonania
	)
	BEGIN
		THROW 50001, 'Błąd. Wydano do produkcji więcej, niż jest w zamówieniu.', 1;
		RETURN;
	END
END;
GO

--Trigger wylicza wypłatę dla pracownika (produkcja) który jest Szewcem lub Cholewkarzem. Aktywuje sie po wydaniu do produkcji (PrzydzialProdukcji), co równa sie z rozpoczęciem przez niego pracy:

CREATE TRIGGER trg_PrzydzialProdukcji_Wyplata_INSERT
ON PrzydzialProdukcji
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

	UPDATE pr
	SET	pr.StanKonta = pr.StanKonta + (i.IloscPrzydzielona * p.KosztSzewca)
	FROM Pracownicy pr
	INNER JOIN inserted i ON i.SzewcID=pr.PracownikID
	INNER JOIN Produkty p ON i.ProduktID=p.ProduktID;

	UPDATE pr
	SET	pr.StanKonta = pr.StanKonta + (i.IloscPrzydzielona * p.KosztCholewkarza)
	FROM Pracownicy pr
	INNER JOIN inserted i ON i.CholewkarzID=pr.PracownikID
	INNER JOIN Produkty p ON i.ProduktID=p.ProduktID
END;
GO

--Trigger zmienia StanKonta pracownika (wylicza wypłatę) gdy dojdzie do zmian przydziale produkcji (gdy zmieni się np. wykonawca zlecenia):

CREATE TRIGGER trg_PrzydzialProdukcji_IloscDoWykonania_update_Wyplata
ON PrzydzialProdukcji
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

	UPDATE pr
	SET pr.StanKonta = pr.StanKonta - (d.IloscPrzydzielona * p.KosztCholewkarza)
	FROM deleted d
	INNER JOIN Produkty p ON d.ProduktID=p.ProduktID
	INNER JOIN Pracownicy pr ON pr.PracownikID=d.CholewkarzID;

	UPDATE pr
	SET pr.StanKonta = pr.StanKonta - (d.IloscPrzydzielona * p.KosztSzewca)
	FROM deleted d
	INNER JOIN Produkty p ON d.ProduktID=p.ProduktID
	INNER JOIN Pracownicy pr ON pr.PracownikID=d.SzewcID;

	UPDATE pr
	SET	pr.StanKonta = pr.StanKonta + (i.IloscPrzydzielona * p.KosztCholewkarza)
	FROM Pracownicy pr
	INNER JOIN inserted i ON i.CholewkarzID=pr.PracownikID
	INNER JOIN Produkty p ON i.ProduktID=p.ProduktID
	
	UPDATE pr
	SET	pr.StanKonta = pr.StanKonta + (i.IloscPrzydzielona * p.KosztSzewca)
	FROM Pracownicy pr
	INNER JOIN inserted i ON i.SzewcID=pr.PracownikID
	INNER JOIN Produkty p ON i.ProduktID=p.ProduktID

END;
GO

--Trigger zmieniający stan konta po usunięciu PrzydzialuProdukcji:

CREATE TRIGGER trg_PrzydzialProdukcji_WyplataPracownika_delete
ON PrzydzialProdukcji
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE pr
	SET pr.StanKonta = pr.StanKonta - (d.IloscPrzydzielona * p.KosztCholewkarza)
	FROM deleted d
	INNER JOIN Produkty p ON d.ProduktID=p.ProduktID
	INNER JOIN Pracownicy pr ON pr.PracownikID=d.CholewkarzID;

	UPDATE pr
	SET pr.StanKonta = pr.StanKonta - (d.IloscPrzydzielona * p.KosztSzewca)
	FROM deleted d
	INNER JOIN Produkty p ON d.ProduktID=p.ProduktID
	INNER JOIN Pracownicy pr ON pr.PracownikID=d.SzewcID;
END;
GO

--Trigger ustawiający status zamówienia dla nowych zamówień:

CREATE TRIGGER trg_Zamowienia_insert_UstawStatus_UstawDate
ON Zamowienia
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE z
	SET Status = 'Nowe'
	FROM Inserted i
	INNER JOIN Zamowienia z ON z.ZamowienieID=i.ZamowienieID;

END;
GO

--Trigger pobierający produkty z magazynu (Materialy) podczas przydzielenia produkcji (PrzydzialProdukcji) oraz zapisujący zmiany w HistoriaMagazynu:

CREATE TRIGGER trg_PrzydzialProdukcji_insert_Materialy
ON PrzydzialProdukcji
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE m
	SET StanMagazynowy = StanMagazynowy - (i.IloscPrzydzielona * pm.Ilosc)
	FROM inserted i
	INNER JOIN ProduktyMaterialy pm ON i.ProduktID = pm.ProduktID
	INNER JOIN Materialy m ON pm.MaterialID = m.MaterialID;

	INSERT INTO HistoriaMagazynu (MaterialID, Ilosc, TypRuchu, Data)
	SELECT 
		m.MaterialID,
		i.IloscPrzydzielona*pm.Ilosc,
		'Produkcja',
		getdate()
	FROM inserted i
	INNER JOIN ProduktyMaterialy pm ON i.ProduktID = pm.ProduktID
	INNER JOIN Materialy m ON pm.MaterialID = m.MaterialID;
 END;
GO

--Trigger pobierający i zwracający produkty z magazynu (Materialy) podczas przydzielenia produkcji (PrzydzialProdukcji) oraz zapisujący zmiany w HistoriaMagazynu:

CREATE TRIGGER trg_PrzydzialProdukcji_update_Materialy
ON PrzydzialProdukcji
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE m
	SET StanMagazynowy = StanMagazynowy + (d.IloscPrzydzielona * pm.Ilosc)
	FROM deleted d 
	INNER JOIN ProduktyMaterialy pm ON d.ProduktID = pm.ProduktID
	INNER JOIN Materialy m ON pm.MaterialID = m.MaterialID;

	INSERT INTO HistoriaMagazynu (MaterialID, Ilosc, TypRuchu, Data)
	SELECT 
		m.MaterialID,
		d.IloscPrzydzielona*pm.Ilosc,
		'Zwrocono',
		getdate()
	FROM deleted d 
	INNER JOIN ProduktyMaterialy pm ON d.ProduktID = pm.ProduktID
	INNER JOIN Materialy m ON pm.MaterialID = m.MaterialID;

	UPDATE m
	SET StanMagazynowy = StanMagazynowy - (i.IloscPrzydzielona * pm.Ilosc)
	FROM inserted i 
	INNER JOIN ProduktyMaterialy pm ON i.ProduktID = pm.ProduktID
	INNER JOIN Materialy m ON pm.MaterialID = m.MaterialID;

	INSERT INTO HistoriaMagazynu (MaterialID, Ilosc, TypRuchu, Data)
	SELECT 
		m.MaterialID,
		i.IloscPrzydzielona*pm.Ilosc,
		'Produkcja',
		getdate()
	FROM inserted i 
	INNER JOIN ProduktyMaterialy pm ON i.ProduktID = pm.ProduktID
	INNER JOIN Materialy m ON pm.MaterialID = m.MaterialID;

 END;
GO

--Trigger zwracający produkty do magazynu w przypadku usunięcia rekordu w PrzydzialProdukcji:

CREATE TRIGGER trg_PrzydzialProdukcji_delete_Materialy
ON PrzydzialProdukcji
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE m
	SET StanMagazynowy = StanMagazynowy + (d.IloscPrzydzielona * pm.Ilosc)
	FROM deleted d
	INNER JOIN ProduktyMaterialy pm ON pm.ProduktID=d.ProduktID
	INNER JOIN Materialy m ON m.MaterialID=pm.MaterialID;

	INSERT INTO HistoriaMagazynu (MaterialID, Ilosc, TypRuchu, Data)
	SELECT 
		m.MaterialID,
		d.IloscPrzydzielona*pm.Ilosc,
		'Zwrocono',
		getdate()
	FROM deleted d
	INNER JOIN ProduktyMaterialy pm ON pm.ProduktID=d.ProduktID
	INNER JOIN Materialy m ON m.MaterialID=pm.MaterialID;

END;
GO

--Trigger blokujący stworzenie PrzydzialProdukcji (zablokowanie wydania zamówienia do produkcji) w przypadku brakujących półproduktów (ProduktyMateriały) w magazynie:

CREATE TRIGGER trg_PrzydzialProdukcji_insert_ProduktyMaterialy_braki
ON PrzydzialProdukcji
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (
			SELECT	
				i.ProduktID,
				pm.MaterialID,
				i.IloscPrzydzielona,
				pm.Ilosc,
				m.StanMagazynowy
			FROM inserted i
			INNER JOIN Produkty p ON p.ProduktID=i.ProduktID
			INNER JOIN ProduktyMaterialy pm ON pm.ProduktID=p.ProduktID
			INNER JOIN Materialy m ON m.MaterialID=pm.MaterialID
			WHERE m.StanMagazynowy < (pm.Ilosc * i.IloscPrzydzielona)
	)

	BEGIN
		THROW 50001, 'UWAGA! BRAKI MAGAZYNOWE! TOWAR WYDANY DO PRODUKCJI, ALE BRAKUJE PÓŁPRODUKTÓW! ZWERYFIKUJ BRAKUJĄCY STAN MAGAZYNOWY.', 1;
		RETURN;
	END
END;
GO

--Trigger dodający rekord w HistoriaMagazynu po zaktualizowaniu stanu magazynowego półproduktów (Materialy):

CREATE TRIGGER trg_ProduktyMaterialy_update_HistoriaMagazynu
ON Materialy
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	WITH dane AS (
		SELECT 
			i.MaterialID,
			CASE
				WHEN i.StanMagazynowy - d.StanMagazynowy > 0 THEN 'Dostawa'
				ELSE 'Ujęcie ręczne'
			END as TypRuchu,
			i.StanMagazynowy - d.StanMagazynowy as Ilosc
		FROM inserted i
		INNER JOIN deleted d on i.MaterialID=d.MaterialID
	)

	INSERT INTO HistoriaMagazynu (MaterialID, Ilosc, TypRuchu, Data)
		SELECT d.MaterialID, d.Ilosc, d.TypRuchu, GETDATE()
		FROM dane d

END;
GO

--Trigger przenoszący Zamowienia do UsunieteZamowienia oraz SzczegolyZamowienia do UsunieteSzczegolyZamowienia (usunięcie zamówienia = usunięcie wszystkich podległych SzczegółówZamówienia):

CREATE TRIGGER trg_Zamowienia_delete_UsunieteZamowienia_historia
ON Zamowienia
INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO UsunieteSzczegolyZamowienia (SzczegolyZamowieniaID, ZamowienieID, ProduktID, Ilosc, CenaJednostki, IloscDoWykonania, DataUsuniecia, PowodUsuniecia)
		SELECT sz.SzczegolyZamowieniaID, sz.ZamowienieID, sz.ProduktID, sz.Ilosc, sz.CenaJednostki, sz.IloscDoWykonania, GETDATE(), 'Usunięcie Zamówienia'
		FROM SzczegolyZamowienia sz
		WHERE ZamowienieID IN (SELECT ZamowienieID FROM deleted);

	INSERT INTO UsunieteZamowienia (ZamowienieID, HandlowiecID, DataZamowienia, DataUsuniecia, TerminMaksymalny, KlientID, WartoscZamowienia)
		SELECT d.ZamowienieID, d.HandlowiecID, d.DataZamowienia, GETDATE(), d.TerminMaksymalny, d.KlientID, d.WartoscZamowienia
		FROM deleted d;
	
	DELETE FROM SzczegolyZamowienia WHERE ZamowienieID IN (SELECT ZamowienieID from deleted);
	DELETE FROM Zamowienia WHERE ZamowienieID IN (SELECT ZamowienieID FROM deleted);
	
END;
GO

--///////////// WIDOKI \\\\\\\\\\\\\--

--Widok pokazujący zarobki szewców za ostatni miesiąc:
CREATE VIEW vvPracownicy_OstatniMiesiąc_Szewc
AS
	SELECT 
		p.Imie,
		p.Nazwisko,
		p.Stanowisko,
		SUM(pp.IloscPrzydzielona * pr.KosztSzewca) as [Suma Zarobków]
	FROM
		Pracownicy p
	INNER JOIN PrzydzialProdukcji pp ON pp.SzewcID=p.PracownikID
	INNER JOIN Produkty pr ON pr.ProduktID=pp.ProduktID
	WHERE pp.DataPrzydzielenia >= DATEADD(month, -1, GETDATE()) AND p.Stanowisko='Szewc'
	GROUP BY p.imie, p.nazwisko, p.Stanowisko;
GO

--Widok pokazujący zarobki cholewkarzy za ostatni miesiąc:

CREATE VIEW vvPracownicy_OstatniMiesiąc_Cholewkarz
AS
	SELECT 
		p.Imie,
		p.Nazwisko,
		p.Stanowisko,
		SUM(pp.IloscPrzydzielona * pr.KosztCholewkarza) as [Suma Zarobków]
	FROM
		Pracownicy p
	INNER JOIN PrzydzialProdukcji pp ON pp.CholewkarzID=p.PracownikID
	INNER JOIN Produkty pr ON pr.ProduktID=pp.ProduktID
	WHERE pp.DataPrzydzielenia >= DATEADD(month, -1, GETDATE()) AND p.Stanowisko='Cholewkarz'
	GROUP BY p.imie, p.nazwisko, p.Stanowisko;
GO

--Widok pokazujący zarobki handlowców w ostatnim miesiącu:

CREATE VIEW vvPracownicy_OstatniMiesiac_Handlowiec
AS
	SELECT
		p.Imie,
		p.Nazwisko,
		p.Stanowisko,
		SUM(sz.Ilosc * sz.CenaJednostki) as [Suma zamówień]
	FROM
		Pracownicy p
	INNER JOIN Zamowienia z ON z.HandlowiecID=p.PracownikID
	INNER JOIN SzczegolyZamowienia sz ON sz.ZamowienieID=z.ZamowienieID
	WHERE z.DataZamowienia >= DATEADD(month, -1, GETDATE()) AND p.Stanowisko='Handlowiec'
	GROUP BY p.Imie, p.Nazwisko, p.Stanowisko;
GO

--Widok pokazuje produkty z największą ilością sprzedanych par:

CREATE VIEW vvZamowienia_OstatniMiesiac_NajlepszaSprzedazProduktu
AS
	SELECT
		p.ProduktID,
		p.NazwaProduktu,
		SUM(sz.Ilosc) as [Ilość Sprzedanych Par],
		SUM(z.WartoscZamowienia) as [Wartość Zamówień]
	FROM 
		Produkty p
	INNER JOIN SzczegolyZamowienia sz ON sz.ProduktID=p.ProduktID
	INNER JOIN Zamowienia z ON z.ZamowienieID=sz.ZamowienieID
	GROUP BY p.ProduktID, p.NazwaProduktu;
GO

--Widok pokazujący produkty w magazynie, których zaczyna brakować (ilość < 50):

CREATE VIEW vv_Materialy_NiskiStanMagazynowy
AS
	SELECT 
		m.MaterialID,
		m.NazwaMaterialu,
		m.StanMagazynowy
	FROM Materialy m
	WHERE m.StanMagazynowy < 50
GO
--///////////// PROCEDURY \\\\\\\\\\\\\--

--Procedura do wyświetlania wypłat cholewkarzy za dany @Miesiac, @Rok:

CREATE PROCEDURE sp_Pracownicy_PokazWyplatyCholewkarzy @Miesiac INT, @Rok INT
AS
BEGIN
	SELECT 
		p.Imie,
		p.Nazwisko,
		p.Stanowisko,
		SUM(pp.IloscPrzydzielona * pr.KosztCholewkarza) as [Suma Zarobków]
	FROM
		Pracownicy p
	INNER JOIN PrzydzialProdukcji pp ON pp.CholewkarzID=p.PracownikID
	INNER JOIN Produkty pr ON pr.ProduktID=pp.ProduktID
	WHERE MONTH(pp.DataPrzydzielenia) = @Miesiac AND YEAR(pp.DataPrzydzielenia) = @Rok AND p.Stanowisko = 'Cholewkarz'
	GROUP BY p.imie, p.nazwisko, p.Stanowisko
	ORDER BY [Suma Zarobków] DESC;
END;
GO

--Procedura do wyświetlania wypłat szewców za dany @Miesiac, @Rok:

CREATE PROCEDURE sp_Pracownicy_PokazWyplatySzewcow @Miesiac INT, @Rok INT
AS
BEGIN
	SELECT 
		p.Imie,
		p.Nazwisko,
		p.Stanowisko,
		SUM(pp.IloscPrzydzielona * pr.KosztSzewca) as [Suma Zarobków]
	FROM
		Pracownicy p
	INNER JOIN PrzydzialProdukcji pp ON pp.SzewcID=p.PracownikID
	INNER JOIN Produkty pr ON pr.ProduktID=pp.ProduktID
	WHERE MONTH(pp.DataPrzydzielenia) = @Miesiac AND YEAR(pp.DataPrzydzielenia) = @Rok AND p.Stanowisko = 'Szewc'
	GROUP BY p.imie, p.nazwisko, p.Stanowisko
	ORDER BY [Suma Zarobków] DESC;
END;
GO

--Procedura do wyświetlania ile Handlowcy zarobili w danym miesiącu:

CREATE PROCEDURE sp_Zamowienia_PokazSprzedazHandlowca @Miesiac INT, @Rok INT
AS
BEGIN
	SELECT
		p.Imie,
		p.Nazwisko,
		p.Stanowisko,
		SUM(z.WartoscZamowienia) as [Suma Wartości Zamówień]
	FROM Pracownicy p
	INNER JOIN Zamowienia z ON p.PracownikID=z.HandlowiecID
	WHERE MONTH(z.DataZamowienia) = @Miesiac AND YEAR(z.DataZamowienia) = @Rok AND p.Stanowisko = 'Handlowiec'
	GROUP BY p.Imie, p.Nazwisko, p.Stanowisko
	ORDER BY [Suma Wartości Zamówień] DESC;
END;
GO

--Procedura do odejmowania stanu konta (wypłacania należności za pracę) dla pracowników:

CREATE PROCEDURE sp_Pracownicy_Wyplata @PracownikID INT, @Wyplata DECIMAL(10,2)
AS
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM Pracownicy p
		WHERE p.PracownikID = @PracownikID
	)
	BEGIN
		THROW 50001, 'Błąd wykonania. Nie ma pracownika o takim ID.', 1;
		RETURN;
	END

	UPDATE p
	SET p.StanKonta = p.StanKonta - @Wyplata
	FROM Pracownicy p
	WHERE p.PracownikID = @PracownikID;

	INSERT INTO HistoriaKonta (KwotaWyplaty, PowodWyplaty)
	VALUES (@Wyplata, 'Wypłata dla pracownika o ID: ' + CAST(@PracownikID AS NVARCHAR(10)));
END;
GO

--Procedura do dodawania zamówienia:

CREATE PROCEDURE sp_Zamowienia_NoweZamowienie @HandlowiecID INT, @TerminMaksymalny DATE, @FirmaID INT
AS
BEGIN
	INSERT INTO Zamowienia (HandlowiecID, TerminMaksymalny, KlientID)
	VALUES (@HandlowiecID, @TerminMaksymalny, @FirmaID);
END;
GO

--Procedura do dodawania szczegółów do zamówienia:

CREATE PROCEDURE sp_SzczegolyZamowienia_NoweZamowienie @ZamowienieID INT, @ProduktID INT, @Ilosc DECIMAL(10,2), @CenaJednostki Decimal(10,2)
AS
BEGIN
	INSERT INTO SzczegolyZamowienia (ZamowienieID, ProduktID, Ilosc, CenaJednostki)
	VALUES (@ZamowienieID, @ProduktID, @Ilosc, @CenaJednostki);
END;
GO

--Procedura do zmiany Szczegółów Zamówienia:

CREATE PROCEDURE sp_SzczegolyZamowienia_ZmienSzczegolyZamowienia @SzczegolyZamowieniaID INT, @ProduktID INT, @Ilosc INT, @CenaJednostki Decimal(10,2)
AS
BEGIN

	IF NOT EXISTS (
		SELECT 1
		FROM SzczegolyZamowienia sz
		WHERE sz.SzczegolyZamowieniaID = @SzczegolyZamowieniaID
	)
	BEGIN
		THROW 50001, 'Podano błędne ID. Takie zamówienie nie istnieje w bazie danych.', 1;
		RETURN;
	END
	UPDATE sz
	SET ProduktID = @ProduktID, Ilosc = @Ilosc, CenaJednostki = @CenaJednostki
	FROM SzczegolyZamowienia sz
	WHERE sz.SzczegolyZamowieniaID = @SzczegolyZamowieniaID;
END;
GO

--Procedura do usuwania Szczegółów Zamówienia:

CREATE PROCEDURE sp_SzczegolyZamowienia_usun @SzczegolyZamowieniaID INT
AS
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM SzczegolyZamowienia sz
		WHERE sz.SzczegolyZamowieniaID = @SzczegolyZamowieniaID
	)
	BEGIN
	THROW 50001, 'Podano błędne ID. Takie zamówienie nie istnieje w bazie danych.', 1;
	RETURN;
	END

	DELETE FROM SzczegolyZamowienia WHERE SzczegolyZamowieniaID = @SzczegolyZamowieniaID
END;
GO

--Procedura do sprawdzania, na ile par (zamówień) wystarczy półproduktów w magazynie:

CREATE PROCEDURE sp_Magazyn_SprawdzNaIleWystarczy @ProduktID INT
AS
BEGIN
	SELECT
		p.ProduktID,
		p.NazwaProduktu,
		m.NazwaMaterialu,
		pm.Ilosc as [Ilość na sztuke],
		m.StanMagazynowy,
		CONVERT(NVARCHAR(50), FLOOR((m.StanMagazynowy / pm.Ilosc))) + ' par' as [Na ile wystarczy]
	FROM 
		Produkty p
	INNER JOIN ProduktyMaterialy pm ON pm.ProduktID=p.ProduktID
	INNER JOIN Materialy m ON m.MaterialID=pm.MaterialID
	WHERE p.ProduktID = @ProduktID
END;
GO

--Procedura do dodawania stanu magazynowego półproduktów (logowanie zmiany w HistoriaMagazynu następuje poprzez trigger, automatycznie):

CREATE PROCEDURE sp_Magazyn_ZwiekszStanMagazynowy @MaterialID INT, @IloscDodawana DECIMAL(16,2)
AS
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM Materialy m
		WHERE m.MaterialID = @MaterialID
	)
	BEGIN
		THROW 50001, 'Nie znaleziono takiego produktu w magazynie.', 1;
		RETURN;
	END

	UPDATE Materialy
	SET StanMagazynowy = (StanMagazynowy + @IloscDodawana)
	WHERE MaterialID = @MaterialID;

END;
GO

--Procedura do wyświetlania raportu miesięcznego (produkcja per miesiąc; bez średnich, gdyż branża jest stricte sezonowa):

CREATE PROCEDURE sp_Raporty_RaportMiesieczny @Miesiac INT, @Rok INT
AS
BEGIN

	WITH NajlepszyProdukt AS (
    SELECT TOP 1 
        p.NazwaProduktu,
        SUM(sz.Ilosc) as SprzedanePary
    FROM SzczegolyZamowienia sz
    INNER JOIN Zamowienia z ON z.ZamowienieID = sz.ZamowienieID
    INNER JOIN Produkty p ON p.ProduktID = sz.ProduktID
    WHERE MONTH(z.DataZamowienia) = @Miesiac AND YEAR(z.DataZamowienia) = @Rok
    GROUP BY p.NazwaProduktu
    ORDER BY SUM(sz.Ilosc) DESC
	)

	SELECT
		(SELECT COUNT(z.ZamowienieID)
		FROM Zamowienia z
		WHERE MONTH(z.DataZamowienia) = @Miesiac AND YEAR(z.DataZamowienia) = @Rok
		) as [Liczba zamówień w miesiącu],

		(SELECT SUM(z.WartoscZamowienia)
		FROM Zamowienia z
		WHERE MONTH(z.DataZamowienia) = @Miesiac AND YEAR(z.DataZamowienia) = @Rok
		) as [Łączna wartość sprzedaży],

		(SELECT FLOOR(AVG(z.WartoscZamowienia))
		FROM Zamowienia z
		WHERE MONTH(z.DataZamowienia) = @Miesiac AND YEAR(z.DataZamowienia) = @Rok
		) as [Średnia wartość zamówienia],

		(SELECT SUM(sz.Ilosc)
		FROM SzczegolyZamowienia sz
		INNER JOIN Zamowienia z ON z.ZamowienieID = sz.ZamowienieID
		WHERE MONTH(z.DataZamowienia) = @Miesiac AND YEAR(z.DataZamowienia) = @Rok
		) as [Łączna ilość sprzedanych par],

		(SELECT COUNT(DISTINCT bf.FirmaID)
		FROM BazaFirm bf
		INNER JOIN Zamowienia z ON z.KlientID=bf.FirmaID
		WHERE MONTH(z.DataZamowienia) = @Miesiac AND YEAR(z.DataZamowienia) = @Rok
		) as [Ilość obsłużonych klientów],

		(SELECT NazwaProduktu + ' (' + CONVERT(NVARCHAR(30), SprzedanePary) + ' par)' FROM NajlepszyProdukt
		) as [Najlepiej Sprzedający sie produkt]
END;
GO