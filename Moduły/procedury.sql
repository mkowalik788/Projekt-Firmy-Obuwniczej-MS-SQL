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