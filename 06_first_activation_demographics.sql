/*
===============================================================================
First-activation demographics
===============================================================================
Project: AMD-STITCH Healthcare Data Analytics
Author: Sofia Rubini
Database: PostgreSQL

Public portfolio note:
- The confidential healthcare dataset is not included.
- Schema and table names reflect the original research environment.
- Queries are presented for portfolio and documentation purposes.
===============================================================================
*/

/*
Q29: Age distribution at first activation
Original appendix title: Distribuzione per età alla prima attivazione (18–110): numerosità e % sul totale

Purpose:
- Age distribution at first activation.
*/
SELECT
 b.fascia_eta,
 COUNT(*) AS n_pazienti,
 ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_sul_totale

FROM (
 SELECT DISTINCT
   a.idcentro, a.idana,
   CASE
     WHEN (pe.first_year - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
     WHEN (pe.first_year - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
     WHEN (pe.first_year - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
     ELSE '80+'
   END AS fascia_eta
 FROM daibetes1.anagrafica a
 JOIN (
   SELECT
     idcentro, idana,
     MIN(EXTRACT(YEAR FROM data)::int) AS first_year
   FROM (
     SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE
data IS NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE
data IS NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci
WHERE data IS NOT NULL
   ) ev
   GROUP BY idcentro, idana
 ) pe
   ON pe.idcentro = a.idcentro AND pe.idana = a.idana
 WHERE a.annonascita IS NOT NULL
   AND pe.first_year IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
)b
GROUP BY b.fascia_eta
ORDER BY CASE b.fascia_eta
        WHEN '18-39' THEN 1
        WHEN '40-64' THEN 2
        WHEN '65-79' THEN 3
        ELSE 4
       END;

/*
Q30: Sex distribution at first activation
Original appendix title: Distribuzione per sesso alla prima attivazione (n e % sul totale)

Purpose:
- Sex distribution at first activation.
*/
SELECT
 b.sesso,
 COUNT(*) AS n_pazienti,
 ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_sul_totale
FROM (
 SELECT a.sesso
 FROM daibetes1.anagrafica a
 JOIN (
   SELECT
     idcentro, idana,
     MIN(data) AS first_event_date,
     MIN(EXTRACT(YEAR FROM data)::int) AS first_year
   FROM (
     SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE data IS
NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE data IS
NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci WHERE data
IS NOT NULL
   ) ev
   GROUP BY idcentro, idana
 ) pe ON pe.idcentro = a.idcentro AND pe.idana = a.idana
 WHERE a.sesso IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND pe.first_year IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
)b
GROUP BY b.sesso
ORDER BY b.sesso;

/*
Q31: Regional distribution at first activation
Original appendix title: Distribuzione per regione alla prima attivazione (n e % sul totale)

Purpose:
- Regional distribution at first activation.
*/
SELECT
 b.regione,
 COUNT(*) AS n_pazienti,
 ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_sul_totale
FROM (
 SELECT c.regione
 FROM daibetes1.anagrafica a
 JOIN daibetes1.centriamd c ON c.idcentro = a.idcentro
 JOIN (
   SELECT
     idcentro, idana,
     MIN(data) AS first_event_date,
     MIN(EXTRACT(YEAR FROM data)::int) AS first_year
   FROM (
     SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE data IS
NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE data IS
NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci WHERE data
IS NOT NULL
   ) ev
   GROUP BY idcentro, idana
 ) pe ON pe.idcentro = a.idcentro AND pe.idana = a.idana
 WHERE c.regione IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND pe.first_year IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
)b
GROUP BY b.regione
ORDER BY n_pazienti DESC, b.regione;

/*
Q32: Age distribution at first recorded clinical event by sex
Original appendix title: Distribuzione per fascia d’età al primo evento per sesso (n e % entro-sesso)

Purpose:
- Age distribution at first recorded clinical event by sex.
*/
SELECT
 b.sesso, b.fascia_eta,
 COUNT(*) AS n_pazienti,
 ROUND(
   100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY b.sesso), 0)
 , 2) AS pct_entrosesso
FROM (
 SELECT DISTINCT
   a.idcentro, a.idana, a.sesso,
   CASE
    WHEN (pe.first_year - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
    WHEN (pe.first_year - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
    WHEN (pe.first_year - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'

     ELSE '80+'
   END AS fascia_eta
 FROM daibetes1.anagrafica a
 JOIN (
   SELECT
     idcentro, idana,
     MIN(EXTRACT(YEAR FROM data)::int) AS first_year
   FROM (
     SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE data IS
NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE data IS
NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci WHERE data
IS NOT NULL
   ) ev
   GROUP BY idcentro, idana
 ) pe ON pe.idcentro = a.idcentro AND pe.idana = a.idana
 WHERE a.sesso IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
)b
GROUP BY b.sesso, b.fascia_eta
ORDER BY
 b.sesso,
 CASE b.fascia_eta
   WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3 ELSE 4
 END;

/*
Q33: Age distribution at first recorded clinical event by region
Original appendix title: Distribuzione per fascia d’età al primo evento per regione (n e % entro-regione)

Purpose:
- Age distribution at first recorded clinical event by region.
*/
SELECT
 b.regione, b.fascia_eta,
 COUNT(*) AS n_pazienti,
 ROUND(
   100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY b.regione), 0)
 , 2) AS pct_entroregione
FROM (
 SELECT DISTINCT
   a.idcentro, a.idana, c.regione,
   CASE
     WHEN (pe.first_year - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
     WHEN (pe.first_year - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
     WHEN (pe.first_year - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
     ELSE '80+'
   END AS fascia_eta
 FROM daibetes1.anagrafica a
 JOIN daibetes1.centriamd c ON c.idcentro = a.idcentro
 JOIN (
   SELECT idcentro, idana, MIN(EXTRACT(YEAR FROM data)::int) AS first_year
   FROM (
     SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE data IS
NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE data IS
NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci WHERE data
IS NOT NULL
   ) ev
   GROUP BY idcentro, idana
 ) pe ON pe.idcentro = a.idcentro AND pe.idana = a.idana
 WHERE c.regione IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
)b
GROUP BY b.regione, b.fascia_eta
ORDER BY
 b.regione,
 CASE b.fascia_eta

  WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3 ELSE 4
 END;
