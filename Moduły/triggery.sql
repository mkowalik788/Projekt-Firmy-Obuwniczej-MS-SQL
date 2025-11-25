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