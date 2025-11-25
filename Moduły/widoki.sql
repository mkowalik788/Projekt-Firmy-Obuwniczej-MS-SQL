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