--1
CREATE DATABASE firma; 

--2
CREATE SCHEMA ksiegowosc;

--3
CREATE TABLE ksiegowosc.pracownicy (
	id_pracownika INT PRIMARY KEY,
	imie VARCHAR(20),
	nazwisko VARCHAR(40),
	adres VARCHAR(100),
	telefon VARCHAR(15)
);


CREATE TABLE ksiegowosc.godziny (
	id_godziny INT PRIMARY KEY,
	data DATE,
	liczba_godzin TINYINT,
	id_pracownika INT
);

CREATE TABLE ksiegowosc.pensja (
	id_pensji INT PRIMARY KEY,
	stanowisko VARCHAR(20),
	kwota DECIMAL(10,2)
);

CREATE TABLE ksiegowosc.premia (
	id_premii INT PRIMARY KEY,
	rodzaj VARCHAR(20),
	kwota DECIMAL(10,2)
)

CREATE TABLE ksiegowosc.wynagrodzenie (
	id_wynagrodzenia INT PRIMARY KEY,
	data DATE,
	id_pracownika INT FOREIGN KEY REFERENCES ksiegowosc.pracownicy(id_pracownika),
	id_godziny INT FOREIGN KEY REFERENCES ksiegowosc.godziny(id_godziny),
	id_pensji INT FOREIGN KEY REFERENCES ksiegowosc.pensja(id_pensji),
	id_premii INT NULL FOREIGN KEY REFERENCES ksiegowosc.premia(id_premii)
);

--4
INSERT INTO ksiegowosc.pracownicy (id_pracownika, imie, nazwisko, adres, telefon ) 
VALUES (1, 'Jan', 'Kowalski', 'Ul. Kwiatowa 12, Warszawa', '123456789'),
(2, 'Anna', 'Nowak', 'Ul. S?oneczna 5, Kraków', '234567890'),
(3, 'Tomasz', 'Wi?niewski', 'Ul. Le?na 3, Wroc?aw', '345678901'),
(4, 'Katarzyna', 'Wojciechowska', 'Ul. Radosna 10, Pozna?', '456789012'),
(5, 'Piotr', 'Zieli?ski', 'Ul. G?ówna 7, ?ód?', '567890123'),
(6, 'Marta', 'Kaczmarek', 'Ul. Wysoka 4, Gda?sk', '678901234'),
(7, 'Jakub', 'Jankowski', 'Ul. Cicha 9, Lublin', '789012345'),
(8, 'Julia', 'W?odarczyk', 'Ul. Morska 8, Szczecin', '890123456'),
(9, 'Sebastian', 'Nowicki', 'Ul. Zielona 6, Katowice', '901234567'),
(10, 'Emilia', 'Kowalczyk', 'Ul. Orzechowa 1, Rzeszów', '012345678');

INSERT INTO ksiegowosc.godziny (id_godziny, data, liczba_godzin, id_pracownika)
VALUES 
(1, '2024-10-01', 160,1), 
(2, '2024-10-01', 170,2),
(3, '2024-10-01', 165,3),  
(4, '2024-10-01', 172,4), 
(5, '2024-10-01', 180,5),  
(6, '2024-10-01', 150,6), 
(7, '2024-10-01', 175,7), 
(8, '2024-10-01', 160,8),  
(9, '2024-10-01', 168,9),  
(10, '2024-10-01', 155,10);  

INSERT INTO ksiegowosc.pensja (id_pensji, stanowisko, kwota)
VALUES 
(1, 'Programista', 7000.00),
(2, 'Tester', 5500.00),
(3, 'Project Manager', 9000.00),
(4, 'Analityk', 6000.00),
(5, 'Grafik', 5000.00),
(6, 'Administrator', 6500.00),
(7, 'Ksi?gowy', 4800.00),
(8, 'HR Manager', 7500.00),
(9, 'Specjalista IT', 7200.00),
(10, 'Web Developer', 6800.00);

INSERT INTO ksiegowosc.premia (id_premii, rodzaj, kwota)
VALUES 
(1, 'Roczna premia', 1500.00),
(2, 'Premia za wyniki', 2000.00),
(3, 'Premia ?wi?teczna', 1000.00),
(4, 'Premia za projekt', 1200.00),
(5, 'Premia motywacyjna', 800.00),
(6, 'Premia lojalno?ciowa', 900.00),
(7, 'Premia zespo?owa', 1100.00);

INSERT INTO ksiegowosc.wynagrodzenie (id_wynagrodzenia, data, id_pracownika, id_godziny, id_pensji, id_premii)
VALUES 
(1, '2024-10-18', 1, 1, 1, 1),
(2, '2024-10-18', 2, 4, 2, 2),
(3, '2024-10-18', 3, 3, 3, NULL),
(4, '2024-10-18', 4, 2, 4, 3),
(5, '2024-10-18', 5, 5, 5, NULL),
(6, '2024-10-18', 6, 6, 6, 4),
(7, '2024-10-18', 7, 7, 10, 5),
(8, '2024-10-18', 8, 8, 8, 6),
(9, '2024-10-18', 9, 9, 9, 7),
(10, '2024-10-18', 10, 10, 7, NULL);

--5

--a
SELECT id_pracownika, nazwisko
FROM ksiegowosc.pracownicy

--b
SELECT W.id_pracownika
FROM ksiegowosc.wynagrodzenie AS W
JOIN ksiegowosc.pensja AS P
ON W.id_pensji=P.id_pensji
WHERE kwota>1000

--c 
SELECT W.id_pracownika
FROM ksiegowosc.wynagrodzenie AS W
JOIN ksiegowosc.pensja AS P
ON W.id_pensji=P.id_pensji
WHERE kwota>2000 AND W.id_premii IS NULL

--d
SELECT id_pracownika, imie, nazwisko, adres, telefon
FROM ksiegowosc.pracownicy
WHERE imie LIKE 'J%'

--e
SELECT id_pracownika, imie, nazwisko, adres, telefon
FROM ksiegowosc.pracownicy
WHERE imie LIKE '%n%a'

--f
SELECT imie, nazwisko, G.liczba_godzin-160
FROM ksiegowosc.pracownicy AS P
JOIN ksiegowosc.godziny AS G
ON P.id_pracownika=G.id_pracownika
WHERE G.liczba_godzin>160

--g
SELECT imie, nazwisko
FROM ksiegowosc.pracownicy AS P
JOIN ksiegowosc.wynagrodzenie AS W
ON P.id_pracownika=W.id_pracownika
JOIN ksiegowosc.pensja AS Pe
ON W.id_pensji=Pe.id_pensji
WHERE Pe.kwota BETWEEN 1500 AND 3000

--h
SELECT imie, nazwisko
FROM ksiegowosc.pracownicy AS P
JOIN ksiegowosc.wynagrodzenie AS W
ON P.id_pracownika=W.id_pracownika
JOIN ksiegowosc.godziny AS G
ON W.id_godziny=G.id_godziny
WHERE G.liczba_godzin>160 AND W.id_premii IS NULL

--i
SELECT P.id_pracownika, imie, nazwisko, Pe.kwota
FROM ksiegowosc.pracownicy AS P
JOIN ksiegowosc.wynagrodzenie AS W
ON P.id_pracownika=W.id_pracownika
JOIN ksiegowosc.pensja AS Pe
ON W.id_pensji=Pe.id_pensji
ORDER BY Pe.kwota

--j
SELECT P.id_pracownika, imie, nazwisko, Pe.kwota AS pensja, Pr.kwota AS premia
FROM ksiegowosc.pracownicy AS P
JOIN ksiegowosc.wynagrodzenie AS W
ON P.id_pracownika=W.id_pracownika
JOIN ksiegowosc.pensja AS Pe
ON W.id_pensji=Pe.id_pensji
JOIN ksiegowosc.premia AS Pr
ON W.id_premii=Pr.id_premii
ORDER BY Pe.kwota DESC, Pr.kwota DESC


UPDATE ksiegowosc.pensja
SET stanowisko='Kierowniczka'
WHERE id_pensji=2

UPDATE ksiegowosc.pensja
SET stanowisko='Programistka'
WHERE id_pensji=1 OR id_pensji=5 OR id_pensji=9

UPDATE ksiegowosc.pensja
SET stanowisko='Analityczka'
WHERE id_pensji=8

--k
SELECT COUNT(id_pensji), stanowisko
FROM ksiegowosc.pensja
GROUP BY stanowisko

--l
SELECT MIN(kwota) AS min_pensja, MAX(kwota) AS max_pensja, AVG(kwota) AS avg_pensja
FROM ksiegowosc.pensja
WHERE stanowisko='Programistka'

--m
SELECT SUM(isnull(Pr.kwota,0)+Pe.kwota) AS suma_wyngarodzen
FROM ksiegowosc.wynagrodzenie AS W
LEFT OUTER JOIN ksiegowosc.premia AS Pr
ON W.id_premii=Pr.id_premii
JOIN ksiegowosc.pensja AS Pe
ON W.id_pensji=Pe.id_pensji

--n...f
SELECT Pe.stanowisko, SUM(isnull(Pr.kwota,0)+Pe.kwota) AS suma_wyngarodzen
FROM ksiegowosc.wynagrodzenie AS W
LEFT OUTER JOIN ksiegowosc.premia AS Pr
ON W.id_premii=Pr.id_premii
JOIN ksiegowosc.pensja AS Pe
ON W.id_pensji=Pe.id_pensji
GROUP BY Pe.stanowisko


--o...g
SELECT Pe.stanowisko, COUNT(Pr.id_premii) AS liczba_premii
FROM ksiegowosc.wynagrodzenie AS W
LEFT OUTER JOIN ksiegowosc.premia AS Pr
ON W.id_premii=Pr.id_premii
JOIN ksiegowosc.pensja AS Pe
ON W.id_pensji=Pe.id_pensji
GROUP BY Pe.stanowisko

--p...h
DELETE FROM ksiegowosc.wynagrodzenie
WHERE id_pracownika IN (
	SELECT P.id_pracownika
	FROM ksiegowosc.pracownicy AS P
	JOIN ksiegowosc.wynagrodzenie AS W 
	ON P.id_pracownika=P.id_pracownika
	JOIN ksiegowosc.pensja AS Pe 
	ON W.id_pensji = Pe.id_pensji
	WHERE Pe.kwota<6000
);

SELECT * FROM ksiegowosc.wynagrodzenie