/*
===============================================================================
Disease progression
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
Q25: HbA1c by disease phase and age at diagnosis
Original appendix title: HbA1c per fase di malattia e fascia d’età alla diagnosi (media/mediana della media per paziente; % max ≥9/≥10 tra i testati)

Purpose:
- HbA1c by disease phase and age at diagnosis.
*/
SELECT
 b.fascia_eta, p.fase_malattia,
 COUNT(*) AS n_pazienti_con_misure,
 ROUND(AVG(p.avg_hba1c), 2) AS media_hba1c,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.avg_hba1c) AS
mediana_hba1c,
 ROUND(100.0 * COUNT(*) FILTER (WHERE p.max_hba1c >= 9.0) /
NULLIF(COUNT(*), 0), 2) AS pct_max_ge_9,
 ROUND(100.0 * COUNT(*) FILTER (WHERE p.max_hba1c >= 10.0) /
NULLIF(COUNT(*), 0), 2) AS pct_max_ge_10
FROM (
 SELECT
  a.idcentro, a.idana,
  CASE
    WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
    WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
    WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
    ELSE '80+'
  END AS fascia_eta,
  a.annodiagnosidiabete AS dx_year
 FROM daibetes1.anagrafica a
 WHERE a.annodiagnosidiabete IS NOT NULL
  AND a.annonascita      IS NOT NULL
  AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 110
  AND COALESCE(a.inconsistenza, 0) = 0
)b
JOIN (
 SELECT
  d.idcentro, d.idana,
  CASE
    WHEN d.delta_years BETWEEN 0 AND 1 THEN '0-1y'
    WHEN d.delta_years BETWEEN 2 AND 5 THEN '2-5y'
    WHEN d.delta_years BETWEEN 6 AND 10 THEN '6-10y'
    ELSE '11+y'
  END AS fase_malattia,
  AVG(d.hba1c_pct) AS avg_hba1c,
  MAX(d.hba1c_pct) AS max_hba1c
 FROM (
  SELECT

   x.idcentro, x.idana, x.dx_year,
   EXTRACT(YEAR FROM e.data)::int - x.dx_year AS delta_years,
   CASE
     WHEN e.codiceamd = 'AMD305' THEN
      (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
     ELSE
      CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
   END AS hba1c_pct
  FROM (
   SELECT a.idcentro, a.idana, a.annodiagnosidiabete AS dx_year
   FROM daibetes1.anagrafica a
   WHERE a.annodiagnosidiabete IS NOT NULL
     AND a.annonascita IS NOT NULL
     AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 110
     AND COALESCE(a.inconsistenza, 0) = 0
  )x
  JOIN (
   SELECT DISTINCT ON (idcentro, idana, data)
        idcentro, idana, data, codiceamd, valore
   FROM daibetes1.esamilaboratorioparametri
   WHERE data IS NOT NULL
     AND valore IS NOT NULL
     AND codiceamd IN ('AMD008','AMD305')
   ORDER BY idcentro, idana, data,
          CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
  )e
   ON e.idcentro = x.idcentro AND e.idana = x.idana
  WHERE (EXTRACT(YEAR FROM e.data)::int - x.dx_year) BETWEEN 0 AND 50
 )d
 WHERE d.hba1c_pct BETWEEN 4 AND 15
 GROUP BY d.idcentro, d.idana,
       CASE
        WHEN d.delta_years BETWEEN 0 AND 1 THEN '0-1y'
        WHEN d.delta_years BETWEEN 2 AND 5 THEN '2-5y'
        WHEN d.delta_years BETWEEN 6 AND 10 THEN '6-10y'
        ELSE '11+y'
       END
)p
 ON p.idcentro = b.idcentro AND p.idana = b.idana
GROUP BY b.fascia_eta, p.fase_malattia
ORDER BY
 CASE b.fascia_eta WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN
3 ELSE 4 END,

 CASE p.fase_malattia WHEN '0-1y' THEN 1 WHEN '2-5y' THEN 2 WHEN '6-10y' THEN
3 ELSE 4 END;

/*
Q26: HbA1c by disease phase, age at diagnosis, and sex
Original appendix title: HbA1c per fase di malattia e fascia d’età alla diagnosi per sesso (media/mediana della media per paziente; % max ≥9/≥10 tra i testati)

Purpose:
- HbA1c by disease phase, age at diagnosis, and sex.
*/
SELECT
 b.fascia_eta, b.sesso, p.fase_malattia,
 COUNT(*) AS n_pazienti_con_misure,
 ROUND(AVG(p.avg_hba1c), 2) AS media_hba1c,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.avg_hba1c) AS
mediana_hba1c,
 ROUND(100.0 * COUNT(*) FILTER (WHERE p.max_hba1c >= 9.0) /
NULLIF(COUNT(*), 0), 2) AS pct_max_ge_9,
 ROUND(100.0 * COUNT(*) FILTER (WHERE p.max_hba1c >= 10.0) /
NULLIF(COUNT(*), 0), 2) AS pct_max_ge_10
FROM (
 SELECT
  a.idcentro, a.idana, a.sesso,
  CASE
    WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
    WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
    WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
    ELSE '80+'

  END AS fascia_eta,
  a.annodiagnosidiabete AS dx_year
 FROM daibetes1.anagrafica a
 WHERE a.annodiagnosidiabete IS NOT NULL
  AND a.annonascita IS NOT NULL
  AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 110
  AND a.sesso IS NOT NULL
  AND COALESCE(a.inconsistenza, 0) = 0
)b
JOIN (
 SELECT
  d.idcentro, d.idana, d.sesso,
  CASE
   WHEN d.delta_years BETWEEN 0 AND 1 THEN '0-1y'
   WHEN d.delta_years BETWEEN 2 AND 5 THEN '2-5y'
   WHEN d.delta_years BETWEEN 6 AND 10 THEN '6-10y'
   ELSE '11+y'
  END AS fase_malattia,
  AVG(d.hba1c_pct) AS avg_hba1c,
  MAX(d.hba1c_pct) AS max_hba1c
 FROM (
  SELECT
   x.idcentro, x.idana, x.dx_year, x.sesso,
   EXTRACT(YEAR FROM e.data)::int - x.dx_year AS delta_years,
   CASE
     WHEN e.codiceamd = 'AMD305' THEN
      (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
     ELSE
      CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
   END AS hba1c_pct
  FROM (
   SELECT a.idcentro, a.idana, a.annodiagnosidiabete AS dx_year, a.sesso
   FROM daibetes1.anagrafica a
   WHERE a.annodiagnosidiabete IS NOT NULL
     AND a.annonascita       IS NOT NULL
     AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 110
     AND a.sesso IS NOT NULL
     AND COALESCE(a.inconsistenza, 0) = 0
  )x
  JOIN (
   SELECT DISTINCT ON (idcentro, idana, data)
        idcentro, idana, data, codiceamd, valore
   FROM daibetes1.esamilaboratorioparametri

    WHERE data IS NOT NULL
     AND valore IS NOT NULL
     AND codiceamd IN ('AMD008','AMD305')
    ORDER BY idcentro, idana, data,
         CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
  )e
    ON e.idcentro = x.idcentro AND e.idana = x.idana
  WHERE (EXTRACT(YEAR FROM e.data)::int - x.dx_year) BETWEEN 0 AND 50
 )d
 WHERE d.hba1c_pct BETWEEN 4 AND 15
 GROUP BY d.idcentro, d.idana, d.sesso,
      CASE
       WHEN d.delta_years BETWEEN 0 AND 1 THEN '0-1y'
       WHEN d.delta_years BETWEEN 2 AND 5 THEN '2-5y'
       WHEN d.delta_years BETWEEN 6 AND 10 THEN '6-10y'
       ELSE '11+y'
      END
)p
 ON p.idcentro = b.idcentro AND p.idana = b.idana
GROUP BY b.fascia_eta, b.sesso, p.fase_malattia
ORDER BY
 CASE b.fascia_eta WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN
3 ELSE 4 END,
 b.sesso,
 CASE p.fase_malattia WHEN '0-1y' THEN 1 WHEN '2-5y' THEN 2 WHEN '6-10y' THEN
3 ELSE 4 END;

/*
Q27: HbA1c by disease phase and region
Original appendix title: HbA1c per fase di malattia per regione (media/mediana della media per paziente; % max ≥9/≥10 tra i testati)

Purpose:
- HbA1c by disease phase and region.
*/
SELECT
 b.regione, p.fase_malattia,
 COUNT(*) AS n_pazienti_con_misure,
 ROUND(AVG(p.avg_hba1c), 2) AS media_hba1c,
 ROUND( (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
p.avg_hba1c))::numeric, 2 ) AS mediana_hba1c,
 ROUND(100.0 * COUNT(*) FILTER (WHERE p.max_hba1c >= 9.0) /
NULLIF(COUNT(*),0), 2) AS pct_max_ge_9,
 ROUND(100.0 * COUNT(*) FILTER (WHERE p.max_hba1c >= 10.0) /
NULLIF(COUNT(*),0), 2) AS pct_max_ge_10
FROM (

 SELECT
  a.idcentro, a.idana, c.regione,
  a.annodiagnosidiabete AS dx_year
 FROM daibetes1.anagrafica a
 JOIN daibetes1.centriamd c ON c.idcentro = a.idcentro
 WHERE a.annodiagnosidiabete IS NOT NULL
  AND a.annonascita IS NOT NULL
  AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 110
  AND COALESCE(a.inconsistenza,0) = 0
  AND c.regione IS NOT NULL
)b
JOIN (
 SELECT
  d.idcentro, d.idana,
  CASE
   WHEN d.delta_years BETWEEN 0 AND 1 THEN '0-1y'
   WHEN d.delta_years BETWEEN 2 AND 5 THEN '2-5y'
   WHEN d.delta_years BETWEEN 6 AND 10 THEN '6-10y'
   ELSE '11+y'
  END AS fase_malattia,
  AVG(d.hba1c_pct) AS avg_hba1c,
  MAX(d.hba1c_pct) AS max_hba1c
 FROM (
  SELECT
   x.idcentro, x.idana, x.dx_year,
   EXTRACT(YEAR FROM e.data)::int - x.dx_year AS delta_years,
   CASE
     WHEN e.codiceamd = 'AMD305' THEN
      (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
     ELSE
      CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
   END AS hba1c_pct
  FROM (
   SELECT idcentro, idana, annodiagnosidiabete AS dx_year
   FROM daibetes1.anagrafica
   WHERE annodiagnosidiabete IS NOT NULL
     AND annonascita        IS NOT NULL
     AND (annodiagnosidiabete - annonascita) BETWEEN 18 AND 110
     AND COALESCE(inconsistenza,0) = 0
  )x
  JOIN (
   SELECT DISTINCT ON (idcentro, idana, data)
        idcentro, idana, data, codiceamd, valore

   FROM daibetes1.esamilaboratorioparametri
   WHERE data IS NOT NULL
    AND valore IS NOT NULL
    AND codiceamd IN ('AMD008','AMD305')
   ORDER BY idcentro, idana, data,
        CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
  )e
   ON e.idcentro = x.idcentro AND e.idana = x.idana
  WHERE (EXTRACT(YEAR FROM e.data)::int - x.dx_year) BETWEEN 0 AND 50
 )d
 WHERE d.hba1c_pct BETWEEN 4 AND 15
 GROUP BY d.idcentro, d.idana,
      CASE
       WHEN d.delta_years BETWEEN 0 AND 1 THEN '0-1y'
       WHEN d.delta_years BETWEEN 2 AND 5 THEN '2-5y'
       WHEN d.delta_years BETWEEN 6 AND 10 THEN '6-10y'
       ELSE '11+y'
      END
)p
 ON p.idcentro = b.idcentro AND p.idana = b.idana
GROUP BY b.regione, p.fase_malattia
ORDER BY b.regione,
 CASE p.fase_malattia WHEN '0-1y' THEN 1 WHEN '2-5y' THEN 2 WHEN '6-10y' THEN
3 ELSE 4 END;

/*
Q28: HbA1c by disease phase and sex
Original appendix title: HbA1c per fase di malattia per sesso (media/mediana della media per paziente; % max ≥9/≥10 tra i testati)

Purpose:
- HbA1c by disease phase and sex.
*/
SELECT
 b.sesso, p.fase_malattia, COUNT(*) AS n_pazienti_con_misure,
 ROUND(AVG(p.avg_hba1c), 2) AS media_hba1c,
 ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
p.avg_hba1c))::numeric, 2) AS mediana_hba1c,
 ROUND(100.0 * COUNT(*) FILTER (WHERE p.max_hba1c >= 9.0) /
NULLIF(COUNT(*),0), 2) AS pct_max_ge_9,

 ROUND(100.0 * COUNT(*) FILTER (WHERE p.max_hba1c >= 10.0) /
NULLIF(COUNT(*),0), 2) AS pct_max_ge_10
FROM (
 SELECT a.idcentro, a.idana, a.sesso, a.annodiagnosidiabete AS dx_year
 FROM daibetes1.anagrafica a
 WHERE a.sesso IS NOT NULL
  AND a.annodiagnosidiabete IS NOT NULL
  AND a.annonascita IS NOT NULL
  AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 110
  AND COALESCE(a.inconsistenza,0) = 0
)b
JOIN (
 SELECT
  d.idcentro, d.idana,
  CASE
   WHEN d.delta_years BETWEEN 0 AND 1 THEN '0-1y'
   WHEN d.delta_years BETWEEN 2 AND 5 THEN '2-5y'
   WHEN d.delta_years BETWEEN 6 AND 10 THEN '6-10y'
   ELSE '11+y'
  END AS fase_malattia,
  AVG(d.hba1c_pct) AS avg_hba1c,
  MAX(d.hba1c_pct) AS max_hba1c
 FROM (
  SELECT
   x.idcentro, x.idana, x.dx_year,
   EXTRACT(YEAR FROM e.data)::int - x.dx_year AS delta_years,
   CASE
     WHEN e.codiceamd = 'AMD305' THEN
      (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
     ELSE
      CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
   END AS hba1c_pct
  FROM (
   SELECT idcentro, idana, annodiagnosidiabete AS dx_year
   FROM daibetes1.anagrafica
   WHERE annodiagnosidiabete IS NOT NULL
     AND annonascita IS NOT NULL
     AND (annodiagnosidiabete - annonascita) BETWEEN 18 AND 110
     AND COALESCE(inconsistenza,0) = 0
  )x
  JOIN (
   SELECT DISTINCT ON (idcentro, idana, data)
        idcentro, idana, data, codiceamd, valore

    FROM daibetes1.esamilaboratorioparametri
    WHERE data IS NOT NULL
     AND valore IS NOT NULL
     AND codiceamd IN ('AMD008','AMD305')
    ORDER BY idcentro, idana, data,
         CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
  )e
    ON e.idcentro = x.idcentro AND e.idana = x.idana
  WHERE (EXTRACT(YEAR FROM e.data)::int - x.dx_year) BETWEEN 0 AND 50
 )d
 WHERE d.hba1c_pct BETWEEN 4 AND 15
 GROUP BY d.idcentro, d.idana,
      CASE
       WHEN d.delta_years BETWEEN 0 AND 1 THEN '0-1y'
       WHEN d.delta_years BETWEEN 2 AND 5 THEN '2-5y'
       WHEN d.delta_years BETWEEN 6 AND 10 THEN '6-10y'
       ELSE '11+y'
      END
)p
 ON p.idcentro = b.idcentro AND p.idana = b.idana
GROUP BY b.sesso, p.fase_malattia
ORDER BY
 CASE p.fase_malattia WHEN '0-1y' THEN 1 WHEN '2-5y' THEN 2 WHEN '6-10y' THEN
3 ELSE 4 END,
 b.sesso;
