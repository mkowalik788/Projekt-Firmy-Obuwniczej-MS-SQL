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