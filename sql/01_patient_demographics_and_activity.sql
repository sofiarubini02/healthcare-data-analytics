/*
===============================================================================
Patient demographics and activity
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
Q1: Patient count and average age at diagnosis by region and sex
Original appendix title: Numero di pazienti e età media alla diagnosi per regione e sesso

Purpose:
- Patient count and average age at diagnosis by region and sex.
*/
SELECT
 c.regione, a.sesso,
 COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti,
 AVG(a.annodiagnosidiabete - a.annonascita) AS eta_media_alla_diagnosi
FROM daibetes1.anagrafica a
JOIN daibetes1.centriamd c
 ON c.idcentro = a.idcentro
WHERE a.sesso IS NOT NULL
 AND a.annodiagnosidiabete IS NOT NULL
 AND a.annonascita IS NOT NULL
 AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 0 AND 110
 AND COALESCE(a.inconsistenza,0) = 0
 AND c.regione IS NOT NULL
GROUP BY c.regione, a.sesso
ORDER BY c.regione, a.sesso;

/*
Q2: Patient count and average age at diagnosis by region
Original appendix title: Numero di pazienti e età media alla diagnosi per regione

Purpose:
- Patient count and average age at diagnosis by region.
*/
SELECT
 c.regione,
 COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti,
 AVG(a.annodiagnosidiabete - a.annonascita) AS eta_media_alla_diagnosi
FROM daibetes1.anagrafica a
JOIN daibetes1.centriamd c
 ON c.idcentro = a.idcentro
WHERE a.annodiagnosidiabete IS NOT NULL
 AND a.annonascita IS NOT NULL
 AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 0 AND 110
 AND COALESCE(a.inconsistenza,0) = 0
 AND c.regione IS NOT NULL
GROUP BY c.regione
ORDER BY n_pazienti DESC, c.regione;

/*
Q3: Regional patient distribution normalized by population and active centers
Original appendix title: Distribuzione dei pazienti per regione, normalizzata per popolazione e numero di centri attivi

Purpose:
- Regional patient distribution normalized by population and active centers.
*/
SELECT
 pr.regione AS regione_db,
 pr.n_pazienti,
 ROUND(100.0 * pr.n_pazienti / NULLIF(t.n_tot_pazienti,0), 2) AS pct_pazienti_su_totale,
 p.popolazione,
 ROUND(100000.0 * pr.n_pazienti / NULLIF(p.popolazione,0), 2) AS tasso_per_100k,
 ROUND(
   (
     (pr.n_pazienti::numeric / NULLIF(t.n_tot_pazienti,0)) /
     (p.popolazione::numeric / NULLIF(pt.popolazione_totale,0))
   )::numeric, 3
 ) AS indice_rappresentazione,
 (
   pr.n_pazienti::numeric /
   NULLIF((SELECT COUNT(DISTINCT c2.idcentro)
         FROM daibetes1.centriamd c2
         WHERE c2.regione = pr.regione), 0)

 )::numeric(12,2) AS pazienti_per_centro
FROM
 (
   SELECT c.regione,
          COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti
   FROM daibetes1.anagrafica a
   JOIN daibetes1.centriamd c USING (idcentro)
   JOIN (
     SELECT idcentro, idana, MIN(data)::date AS first_event_date
     FROM (
       SELECT idcentro, idana, data FROM dati2.esamilaboratorioparametri WHERE data IS
NOT NULL
       UNION ALL
       SELECT idcentro, idana, data FROM dati2.prescrizionidiabetefarmaci WHERE data IS
NOT NULL
       UNION ALL
       SELECT idcentro, idana, data FROM dati2.prescrizionidiabetenonfarmaci WHERE data IS
NOT NULL
     ) ev
     GROUP BY idcentro, idana
   ) pe USING (idcentro, idana)
   WHERE c.regione IS NOT NULL
     AND COALESCE(a.inconsistenza,0) = 0
     AND a.annonascita IS NOT NULL
   GROUP BY c.regione
 ) pr
LEFT JOIN
 (
   SELECT
     v.regione,
     v.popolazione,
     translate(lower(v.regione), ' -''’/', '') AS reg_key
   FROM (
     VALUES
       ('Abruzzo',      1269571),
       ('Basilicata', 533233),
       ('Calabria',    1838568),
       ('Campania',      5609536),
       ('Emilia-Romagna', 4482977),
       ('Friuli',    1194096),
       ('Lazio',      5720536),
       ('Liguria',    1507636),
       ('Lombardia', 10012054),
       ('Marche',      1482746),

       ('Molise',      289224),
       ('Piemonte', 4251351),
       ('Puglia',    3890661),
       ('Sardegna', 1570453),
       ('Sicilia',  4797359),
       ('Toscana',     3660530),
       ('Trentino-Alto Adige', 1087470),
       ('Umbria',       853068),
       ('Valle d''Aosta', 123130),
       ('Veneto',     4852216)
   ) AS v(regione, popolazione)
 )p
 ON translate(lower(pr.regione), ' -''’/', '') = p.reg_key
CROSS JOIN
 (
   SELECT SUM(pr2.n_pazienti)::bigint AS n_tot_pazienti
   FROM (
     SELECT c.regione,
           COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti
     FROM daibetes1.anagrafica a
     JOIN daibetes1.centriamd c USING (idcentro)
     JOIN (
       SELECT idcentro, idana, MIN(data)::date AS first_event_date
       FROM (
         SELECT idcentro, idana, data FROM dati2.esamilaboratorioparametri WHERE data IS
NOT NULL
         UNION ALL
         SELECT idcentro, idana, data FROM dati2.prescrizionidiabetefarmaci WHERE data IS
NOT NULL
         UNION ALL
         SELECT idcentro, idana, data FROM dati2.prescrizionidiabetenonfarmaci WHERE data
IS NOT NULL
       ) ev
       GROUP BY idcentro, idana
     ) pe USING (idcentro, idana)
     WHERE c.regione IS NOT NULL
       AND COALESCE(a.inconsistenza,0) = 0
       AND a.annonascita IS NOT NULL
     GROUP BY c.regione
   ) pr2
 )t
CROSS JOIN
 (
   SELECT SUM(p2.popolazione)::bigint AS popolazione_totale

   FROM (
     VALUES
      ('Abruzzo',      1269571),
      ('Basilicata', 533233),
      ('Calabria',     1838568),
      ('Campania',       5609536),
      ('Emilia-Romagna', 4482977),
      ('Friuli',    1194096),
      ('Lazio',      5720536),
      ('Liguria',    1507636),
      ('Lombardia', 10012054),
      ('Marche',      1482746),
      ('Molise',       289224),
      ('Piemonte', 4251351),
      ('Puglia',     3890661),
      ('Sardegna', 1570453),
      ('Sicilia',   4797359),
      ('Toscana',      3660530),
      ('Trentino-Alto Adige', 1087470),
      ('Umbria',        853068),
      ('Valle d''Aosta', 123130),
      ('Veneto',      4852216)
   ) AS p2(regione, popolazione)
 ) pt
ORDER BY indice_rappresentazione ASC, pr.regione;

/*
Q4: New diagnoses by year and region
Original appendix title: Numero di nuove diagnosi per anno e regione

Purpose:
- New diagnoses by year and region.
*/
SELECT
 c.regione,
 a.annodiagnosidiabete AS anno,
 COUNT(DISTINCT (a.idcentro, a.idana)) AS nuovi_pazienti
FROM daibetes1.anagrafica a
JOIN daibetes1.centriamd c
 ON c.idcentro = a.idcentro
WHERE a.annodiagnosidiabete IS NOT NULL
 AND a.annonascita IS NOT NULL
 AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 0 AND 110
 AND COALESCE(a.inconsistenza,0) = 0
 AND c.regione IS NOT NULL
GROUP BY c.regione, anno
ORDER BY anno, c.regione;

/*
Q5: Active patients by year and region (patient-years)
Original appendix title: Numero di pazienti attivi per anno e regione (paziente-anno)

Purpose:
- Active patients by year and region (patient-years).
*/
SELECT
 c.regione, x.anno,
 COUNT(DISTINCT (x.idcentro, x.idana)) AS n_pazienti_attivi
FROM (
 SELECT e.idcentro, e.idana, EXTRACT(YEAR FROM e.data)::int AS anno
 FROM daibetes1.esamilaboratorioparametri e
 WHERE e.data IS NOT NULL
 UNION
 SELECT pf.idcentro, pf.idana, EXTRACT(YEAR FROM pf.data)::int
 FROM daibetes1.prescrizionidiabetefarmaci pf
 WHERE pf.data IS NOT NULL
 UNION
 SELECT pn.idcentro, pn.idana, EXTRACT(YEAR FROM pn.data)::int
 FROM daibetes1.prescrizionidiabetenonfarmaci pn
 WHERE pn.data IS NOT NULL
)x
JOIN daibetes1.centriamd c ON c.idcentro = x.idcentro
WHERE c.regione IS NOT NULL
GROUP BY c.regione, x.anno
ORDER BY x.anno, n_pazienti_attivi DESC;
