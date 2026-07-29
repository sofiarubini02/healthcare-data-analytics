/*
===============================================================================
Age and early glycemic control
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
Q17: Latest normalized HbA1c by age at test and sex
Original appendix title: Ultima HbA1c normalizzata per paziente per fascia d’età al test e sesso (n, media, mediana)

Purpose:
- Latest normalized HbA1c by age at test and sex.
*/
SELECT
 z.fascia_eta, z.sesso,
 COUNT(DISTINCT (z.idcentro, z.idana)) AS n_pazienti,
 ROUND(AVG(z.hba1c_pct)::numeric, 2) AS media_hba1c,
 ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
z.hba1c_pct))::numeric, 2) AS mediana_hba1c
FROM (
 SELECT
   a.idcentro, a.idana, a.sesso,
   CASE
     WHEN EXTRACT(YEAR FROM l.data)::int - a.annonascita BETWEEN 18 AND 39
THEN '18-39'
     WHEN EXTRACT(YEAR FROM l.data)::int - a.annonascita BETWEEN 40 AND 64
THEN '40-64'
     WHEN EXTRACT(YEAR FROM l.data)::int - a.annonascita BETWEEN 65 AND 79
THEN '65-79'
     ELSE '80+'
   END AS fascia_eta,
   l.hba1c_pct
 FROM daibetes1.anagrafica a
 JOIN (
   SELECT DISTINCT ON (idcentro, idana)
        idcentro, idana, data,
        CASE
          WHEN codiceamd = 'AMD305' THEN
           (CAST(REPLACE(REGEXP_REPLACE(valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
          ELSE
           CAST(REPLACE(REGEXP_REPLACE(valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
        END AS hba1c_pct,
        CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
   FROM daibetes1.esamilaboratorioparametri
   WHERE data IS NOT NULL
     AND valore IS NOT NULL
     AND codiceamd IN ('AMD008','AMD305')
   ORDER BY idcentro, idana, data DESC, pref
 )l
   ON l.idcentro = a.idcentro AND l.idana = a.idana
 WHERE a.sesso IS NOT NULL
   AND a.annonascita IS NOT NULL

  AND (EXTRACT(YEAR FROM l.data)::int - a.annonascita) BETWEEN 18 AND 110
  AND l.hba1c_pct BETWEEN 4 AND 15
)z
GROUP BY z.fascia_eta, z.sesso
ORDER BY
 CASE z.fascia_eta
   WHEN '18-39' THEN 1
   WHEN '40-64' THEN 2
   WHEN '65-79' THEN 3
   ELSE 4
 END,
 z.sesso;

/*
Q18: Latest normalized HbA1c by age at first access and sex
Original appendix title: Ultima HbA1c normalizzata per paziente per fascia d’età al primo accesso e sesso (n, media, mediana)

Purpose:
- Latest normalized HbA1c by age at first access and sex.
*/
SELECT
 b.fascia_eta, b.sesso,
 COUNT(DISTINCT (b.idcentro, b.idana)) AS n_pazienti,
 ROUND(AVG(l.hba1c_pct) FILTER (WHERE l.hba1c_pct IS NOT NULL), 2) AS
media_ultima_hba1c_valida,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.hba1c_pct)
  FILTER (WHERE l.hba1c_pct IS NOT NULL) AS mediana_ultima_hba1c_valida
FROM (
 SELECT
  a.idcentro, a.idana, a.sesso,
  CASE
    WHEN (a.annoprimoaccesso - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'

       WHEN (a.annoprimoaccesso - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
       WHEN (a.annoprimoaccesso - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
       ELSE '80+'
     END AS fascia_eta
  FROM daibetes1.anagrafica a
  WHERE a.sesso IS NOT NULL
     AND a.annonascita IS NOT NULL
     AND a.annoprimoaccesso IS NOT NULL
     AND (a.annoprimoaccesso - a.annonascita) BETWEEN 18 AND 110
)b
LEFT JOIN (
  SELECT DISTINCT ON (idcentro, idana)
          idcentro, idana, data, hba1c_pct
  FROM (
     SELECT
       e.idcentro, e.idana, e.data,
       CASE
         WHEN e.codiceamd = 'AMD305'
           THEN ROUND((CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'),
',', '.') AS numeric) / 10.929) + 2.15, 1)
         ELSE CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
       END AS hba1c_pct,
       CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
     FROM daibetes1.esamilaboratorioparametri e
     WHERE e.data IS NOT NULL
       AND e.valore IS NOT NULL
       AND e.codiceamd IN ('AMD008','AMD305')
  )s
  WHERE s.hba1c_pct BETWEEN 4 AND 15
  ORDER BY idcentro, idana, data DESC, pref
)l
  ON l.idcentro = b.idcentro AND l.idana = b.idana
GROUP BY b.fascia_eta, b.sesso
ORDER BY
  CASE b.fascia_eta
     WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3 ELSE 4 END,
  b.sesso;

/*
Q19: Latest normalized HbA1c by age at first recorded clinical event and sex
Original appendix title: Ultima HbA1c normalizzata per paziente per fascia d’età al primo evento e sesso (n, media, mediana)

Purpose:
- Latest normalized HbA1c by age at first recorded clinical event and sex.
*/
SELECT
 b.fascia_eta,
 b.sesso,
 COUNT(DISTINCT (b.idcentro, b.idana)) AS n_pazienti,
 ROUND(AVG(l.hba1c_pct) FILTER (WHERE l.hba1c_pct IS NOT NULL), 2) AS
media_ultima_hba1c_valida,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.hba1c_pct)
  FILTER (WHERE l.hba1c_pct IS NOT NULL) AS mediana_ultima_hba1c_valida
FROM (
 SELECT
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
 WHERE a.sesso IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
)b
LEFT JOIN (
 SELECT DISTINCT ON (idcentro, idana)
       idcentro, idana, data, hba1c_pct
 FROM (
   SELECT
     e.idcentro, e.idana, e.data,
     CASE
      WHEN e.codiceamd = 'AMD305' THEN
        (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
      ELSE
        CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
     END AS hba1c_pct,
     CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
   FROM daibetes1.esamilaboratorioparametri e
   WHERE e.data IS NOT NULL
     AND e.valore IS NOT NULL
     AND e.codiceamd IN ('AMD008','AMD305')
 )s
 WHERE s.hba1c_pct BETWEEN 4 AND 15
 ORDER BY idcentro, idana, data DESC, pref
)l
 ON l.idcentro = b.idcentro AND l.idana = b.idana
GROUP BY b.fascia_eta, b.sesso
ORDER BY
 CASE b.fascia_eta
   WHEN '18-39' THEN 1
   WHEN '40-64' THEN 2
   WHEN '65-79' THEN 3
   ELSE 4
 END,
 b.sesso;

/*
Q20: HbA1c within 12 months of the first recorded clinical event by age group
Original appendix title: HbA1c entro 12 mesi dal primo evento per fascia d’età (copertura, media, mediana)

Purpose:
- HbA1c within 12 months of the first recorded clinical event by age group.
*/
SELECT
 b.fascia_eta,
 COUNT(DISTINCT (b.idcentro, b.idana)) AS n_pazienti,
 COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE w.hba1c_pct IS NOT NULL)
AS n_con_hba1c_12m,
 ROUND(AVG(w.hba1c_pct) FILTER (WHERE w.hba1c_pct IS NOT NULL), 2) AS
media_hba1c_12m,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY w.hba1c_pct)
  FILTER (WHERE w.hba1c_pct IS NOT NULL) AS mediana_hba1c_12m
FROM (
 SELECT
  a.idcentro, a.idana, pe.first_event_date,
  CASE
    WHEN (EXTRACT(YEAR FROM pe.first_event_date)::int - a.annonascita) BETWEEN
18 AND 39 THEN '18-39'
    WHEN (EXTRACT(YEAR FROM pe.first_event_date)::int - a.annonascita) BETWEEN
40 AND 64 THEN '40-64'
    WHEN (EXTRACT(YEAR FROM pe.first_event_date)::int - a.annonascita) BETWEEN
65 AND 79 THEN '65-79'
    ELSE '80+'
  END AS fascia_eta
 FROM daibetes1.anagrafica a
 JOIN (
  SELECT idcentro, idana, MIN(data) AS first_event_date
  FROM (
    SELECT idcentro,idana,data FROM daibetes1.esamilaboratorioparametri WHERE
data IS NOT NULL
    UNION ALL

     SELECT idcentro,idana,data FROM daibetes1.prescrizionidiabetefarmaci WHERE
data IS NOT NULL
     UNION ALL
     SELECT idcentro,idana,data FROM daibetes1.prescrizionidiabetenonfarmaci WHERE
data IS NOT NULL
   ) ev
   GROUP BY idcentro,idana
 ) pe ON pe.idcentro = a.idcentro AND pe.idana = a.idana
 WHERE a.annonascita IS NOT NULL
   AND (EXTRACT(YEAR FROM pe.first_event_date)::int - a.annonascita) BETWEEN 18
AND 110
)b
LEFT JOIN (
 SELECT DISTINCT ON (e.idcentro, e.idana)
      e.idcentro, e.idana, e.data,
      CASE
        WHEN e.codiceamd = 'AMD305' THEN
         (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
        ELSE
         CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
      END AS hba1c_pct
 FROM daibetes1.esamilaboratorioparametri e
 JOIN (
   SELECT idcentro,idana, MIN(data) AS first_event_date
   FROM (
     SELECT idcentro,idana,data FROM daibetes1.esamilaboratorioparametri WHERE
data IS NOT NULL
     UNION ALL
     SELECT idcentro,idana,data FROM daibetes1.prescrizionidiabetefarmaci WHERE
data IS NOT NULL
     UNION ALL
     SELECT idcentro,idana,data FROM daibetes1.prescrizionidiabetenonfarmaci WHERE
data IS NOT NULL
   ) ev GROUP BY idcentro,idana
 ) pe ON pe.idcentro = e.idcentro AND pe.idana = e.idana
 WHERE e.data >= pe.first_event_date
   AND e.data < pe.first_event_date + INTERVAL '1 year'
   AND e.data IS NOT NULL
   AND e.valore IS NOT NULL
   AND e.codiceamd IN ('AMD008','AMD305')
   AND (
     CASE

     WHEN e.codiceamd = 'AMD305' THEN
      (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
     ELSE
      CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
    END
  ) BETWEEN 4 AND 15
 ORDER BY e.idcentro, e.idana, e.data DESC,
       CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END
)w
 ON w.idcentro = b.idcentro AND w.idana = b.idana
GROUP BY b.fascia_eta
ORDER BY
 CASE b.fascia_eta
  WHEN '18-39' THEN 1
  WHEN '40-64' THEN 2
  WHEN '65-79' THEN 3
  ELSE 4
 END;

/*
Q21: HbA1c within 12 months of the first recorded clinical event by age group and sex
Original appendix title: HbA1c entro 12 mesi dal primo evento per fascia d’età e sesso (copertura, media, mediana)

Purpose:
- HbA1c within 12 months of the first recorded clinical event by age group and sex.
*/
SELECT
 b.fascia_eta, b.sesso,
 COUNT(DISTINCT (b.idcentro, b.idana)) AS n_pazienti,
 COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE w.hba1c_pct IS NOT NULL)
AS n_con_hba1c_12m,
 ROUND(AVG(w.hba1c_pct) FILTER (WHERE w.hba1c_pct IS NOT NULL), 2) AS
media_hba1c_12m,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY w.hba1c_pct)
  FILTER (WHERE w.hba1c_pct IS NOT NULL) AS mediana_hba1c_12m
FROM (
 SELECT
  a.idcentro, a.idana, a.sesso, pe.first_event_date,

   CASE
     WHEN (EXTRACT(YEAR FROM pe.first_event_date)::int - a.annonascita) BETWEEN
18 AND 39 THEN '18-39'
     WHEN (EXTRACT(YEAR FROM pe.first_event_date)::int - a.annonascita) BETWEEN
40 AND 64 THEN '40-64'
     WHEN (EXTRACT(YEAR FROM pe.first_event_date)::int - a.annonascita) BETWEEN
65 AND 79 THEN '65-79'
     ELSE '80+'
   END AS fascia_eta
 FROM daibetes1.anagrafica a
 JOIN (
   SELECT idcentro, idana, MIN(data) AS first_event_date
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
 WHERE a.sesso IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND (EXTRACT(YEAR FROM pe.first_event_date)::int - a.annonascita) BETWEEN 18
AND 110
)b
LEFT JOIN (
 SELECT DISTINCT ON (e.idcentro, e.idana)
      e.idcentro, e.idana, e.data,
      CASE
        WHEN e.codiceamd = 'AMD305' THEN
         (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
        ELSE
         CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
      END AS hba1c_pct
 FROM daibetes1.esamilaboratorioparametri e
 JOIN (
   SELECT idcentro, idana, MIN(data) AS first_event_date

   FROM (
     SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE
data IS NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE
data IS NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci
WHERE data IS NOT NULL
   ) ev GROUP BY idcentro, idana
 ) pe
   ON pe.idcentro = e.idcentro AND pe.idana = e.idana
 WHERE e.data >= pe.first_event_date
   AND e.data < pe.first_event_date + INTERVAL '1 year'
   AND e.data IS NOT NULL
   AND e.valore IS NOT NULL
   AND e.codiceamd IN ('AMD008','AMD305')
   AND (
     CASE
      WHEN e.codiceamd = 'AMD305' THEN
       (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
      ELSE
       CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
     END
   ) BETWEEN 4 AND 15
 ORDER BY e.idcentro, e.idana, e.data DESC,
        CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END
)w
 ON w.idcentro = b.idcentro AND w.idana = b.idana
GROUP BY b.fascia_eta, b.sesso
ORDER BY
 CASE b.fascia_eta
   WHEN '18-39' THEN 1
   WHEN '40-64' THEN 2
   WHEN '65-79' THEN 3
   ELSE 4
 END,
 b.sesso;

/*
Q22: Latest and maximum HbA1c within 12 months of the first event by age group
Original appendix title: Ultima e massima HbA1c entro 12 mesi dal primo evento per fascia d’età (copertura, media/mediana ultima, % max ≥9/≥10 tra i testati)

Purpose:
- Latest and maximum HbA1c within 12 months of the first event by age group.
*/
SELECT
 b.fascia_eta,
 COUNT(DISTINCT (b.idcentro, b.idana)) AS n_pazienti,
 COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c IS NOT
NULL) AS n_testati_12m,
 ROUND(
   100.0 * COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c >=
9.0)
   / NULLIF(COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c IS
NOT NULL), 0)
 , 2) AS pct_max_ge_9_su_testati,
 ROUND(
   100.0 * COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c >=
10.0)
   / NULLIF(COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c IS
NOT NULL), 0)
 , 2) AS pct_max_ge_10_su_testati,
 ROUND(AVG(l.last_hba1c) FILTER (WHERE l.last_hba1c IS NOT NULL), 2) AS
media_last_12m,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.last_hba1c)
   FILTER (WHERE l.last_hba1c IS NOT NULL) AS mediana_last_12m
FROM (
 SELECT
   a.idcentro, a.idana,
   CASE
     WHEN (pe.first_year - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
     WHEN (pe.first_year - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
     WHEN (pe.first_year - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'

     ELSE '80+'
   END AS fascia_eta
 FROM daibetes1.anagrafica a
 JOIN (
   SELECT idcentro, idana,
        MIN(data) AS first_event_date,
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
 ) pe ON pe.idcentro = a.idcentro AND pe.idana = a.idana
 WHERE a.annonascita IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
)b
LEFT JOIN (
 SELECT DISTINCT ON (d.idcentro, d.idana)
      d.idcentro, d.idana, d.data, d.hba1c_pct AS last_hba1c
 FROM (
   SELECT DISTINCT ON (e.idcentro, e.idana, e.data)
        e.idcentro, e.idana, e.data,
        CASE
         WHEN e.codiceamd = 'AMD305' THEN
           (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
         ELSE
           CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
        END AS hba1c_pct,
        CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
   FROM daibetes1.esamilaboratorioparametri e
   JOIN (
     SELECT idcentro, idana, MIN(data) AS first_event_date
     FROM (
      SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE
data IS NOT NULL
      UNION ALL

       SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE
data IS NOT NULL
       UNION ALL
       SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci
WHERE data IS NOT NULL
     ) ev GROUP BY idcentro, idana
   ) pe ON pe.idcentro = e.idcentro AND pe.idana = e.idana
   WHERE e.data IS NOT NULL
     AND e.valore IS NOT NULL
     AND e.data >= pe.first_event_date
     AND e.data < pe.first_event_date + INTERVAL '1 year'
     AND e.codiceamd IN ('AMD008','AMD305')
   ORDER BY e.idcentro, e.idana, e.data, pref
 )d
 WHERE d.hba1c_pct BETWEEN 4 AND 15
 ORDER BY d.idcentro, d.idana, d.data DESC
)l
 ON l.idcentro = b.idcentro AND l.idana = b.idana
LEFT JOIN (
 SELECT d2.idcentro, d2.idana, MAX(d2.hba1c_pct) AS max_hba1c
 FROM (
   SELECT DISTINCT ON (e.idcentro, e.idana, e.data)
        e.idcentro, e.idana, e.data,
        CASE
          WHEN e.codiceamd = 'AMD305' THEN
           (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
          ELSE
           CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
        END AS hba1c_pct,
        CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
   FROM daibetes1.esamilaboratorioparametri e
   JOIN (
     SELECT idcentro, idana, MIN(data) AS first_event_date
     FROM (
       SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE
data IS NOT NULL
       UNION ALL
       SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE
data IS NOT NULL
       UNION ALL
       SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci
WHERE data IS NOT NULL

     ) ev GROUP BY idcentro, idana
   ) pe ON pe.idcentro = e.idcentro AND pe.idana = e.idana
   WHERE e.data IS NOT NULL
     AND e.valore IS NOT NULL
     AND e.data >= pe.first_event_date
     AND e.data < pe.first_event_date + INTERVAL '1 year'
     AND e.codiceamd IN ('AMD008','AMD305')
   ORDER BY e.idcentro, e.idana, e.data, pref
 ) d2
 WHERE d2.hba1c_pct BETWEEN 4 AND 15
 GROUP BY d2.idcentro, d2.idana
)m
 ON m.idcentro = b.idcentro AND m.idana = b.idana
GROUP BY b.fascia_eta
ORDER BY
 CASE b.fascia_eta
   WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3 ELSE 4 END;

/*
Q23: Latest and maximum HbA1c within 12 months of the first event by age group and sex
Original appendix title: Ultima e massima HbA1c entro 12 mesi dal primo evento per fascia d’età e sesso (copertura, media/mediana ultima, % max ≥9/≥10 tra i testati)

Purpose:
- Latest and maximum HbA1c within 12 months of the first event by age group and sex.
*/
SELECT
 b.fascia_eta, b.sesso,
 COUNT(DISTINCT (b.idcentro, b.idana)) AS n_pazienti,
 COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c IS
NOT NULL) AS n_testati_12m,
 ROUND(
   100.0 * COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE
m.max_hba1c >= 9.0)
   / NULLIF(COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE
m.max_hba1c IS NOT NULL), 0)
 , 2) AS pct_max_ge_9_su_testati,
 ROUND(

   100.0 * COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE
m.max_hba1c >= 10.0)
   / NULLIF(COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE
m.max_hba1c IS NOT NULL), 0)
 , 2) AS pct_max_ge_10_su_testati,
 ROUND(AVG(l.last_hba1c) FILTER (WHERE l.last_hba1c IS NOT NULL), 2) AS
media_last_12m,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.last_hba1c)
   FILTER (WHERE l.last_hba1c IS NOT NULL) AS mediana_last_12m
FROM (
 SELECT
   a.idcentro, a.idana, a.sesso,
   CASE
     WHEN (pe.first_year - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
     WHEN (pe.first_year - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
     WHEN (pe.first_year - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
     ELSE '80+'
   END AS fascia_eta
 FROM daibetes1.anagrafica a
 JOIN (
   SELECT idcentro, idana,
        MIN(data) AS first_event_date,
        MIN(EXTRACT(YEAR FROM data)::int) AS first_year
   FROM (
     SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri
WHERE data IS NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci
WHERE data IS NOT NULL
     UNION ALL
     SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci
WHERE data IS NOT NULL
   ) ev
   GROUP BY idcentro, idana
 ) pe ON pe.idcentro = a.idcentro AND pe.idana = a.idana
 WHERE a.sesso IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
)b
LEFT JOIN (

 SELECT DISTINCT ON (d.idcentro, d.idana)
      d.idcentro, d.idana, d.data, d.hba1c_pct AS last_hba1c
 FROM (
  SELECT DISTINCT ON (e.idcentro, e.idana, e.data)
       e.idcentro, e.idana, e.data,
       CASE
         WHEN e.codiceamd = 'AMD305' THEN
          (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.')
AS numeric) / 10.929) + 2.15
         ELSE
          CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.')
AS numeric)
       END AS hba1c_pct,
       CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
  FROM daibetes1.esamilaboratorioparametri e
  JOIN (
    SELECT idcentro, idana, MIN(data) AS first_event_date
    FROM (
      SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri
WHERE data IS NOT NULL
      UNION ALL
      SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci
WHERE data IS NOT NULL
      UNION ALL
      SELECT idcentro, idana, data FROM
daibetes1.prescrizionidiabetenonfarmaci WHERE data IS NOT NULL
    ) ev GROUP BY idcentro, idana
  ) pe ON pe.idcentro = e.idcentro AND pe.idana = e.idana
  WHERE e.data IS NOT NULL
    AND e.valore IS NOT NULL
    AND e.data >= pe.first_event_date
    AND e.data < pe.first_event_date + INTERVAL '1 year'
    AND e.codiceamd IN ('AMD008','AMD305')
    AND (
      CASE
       WHEN e.codiceamd = 'AMD305' THEN
        (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
       ELSE

         CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
       END
     ) BETWEEN 4 AND 15
   ORDER BY e.idcentro, e.idana, e.data, pref
 )d
 ORDER BY d.idcentro, d.idana, d.data DESC
)l
 ON l.idcentro = b.idcentro AND l.idana = b.idana
LEFT JOIN (
 SELECT d2.idcentro, d2.idana, MAX(d2.hba1c_pct) AS max_hba1c
 FROM (
   SELECT DISTINCT ON (e.idcentro, e.idana, e.data)
        e.idcentro, e.idana, e.data,
        CASE
          WHEN e.codiceamd = 'AMD305' THEN
           (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.')
AS numeric) / 10.929) + 2.15
          ELSE
           CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.')
AS numeric)
        END AS hba1c_pct,
        CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
   FROM daibetes1.esamilaboratorioparametri e
   JOIN (
     SELECT idcentro, idana, MIN(data) AS first_event_date
     FROM (
       SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri
WHERE data IS NOT NULL
       UNION ALL
       SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci
WHERE data IS NOT NULL
       UNION ALL
       SELECT idcentro, idana, data FROM
daibetes1.prescrizionidiabetenonfarmaci WHERE data IS NOT NULL
     ) ev GROUP BY idcentro, idana
   ) pe ON pe.idcentro = e.idcentro AND pe.idana = e.idana
   WHERE e.data IS NOT NULL
     AND e.valore IS NOT NULL
     AND e.data >= pe.first_event_date

    AND e.data < pe.first_event_date + INTERVAL '1 year'
    AND e.codiceamd IN ('AMD008','AMD305')
    AND (
      CASE
       WHEN e.codiceamd = 'AMD305' THEN
        (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
       ELSE
        CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
      END
    ) BETWEEN 4 AND 15
   ORDER BY e.idcentro, e.idana, e.data, pref
 ) d2
 GROUP BY d2.idcentro, d2.idana
)m
 ON m.idcentro = b.idcentro AND m.idana = b.idana
GROUP BY b.fascia_eta, b.sesso
ORDER BY
 CASE b.fascia_eta
   WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3 ELSE 4
END,
 b.sesso;

/*
Q24: Latest and maximum HbA1c in 2010 among active patients by age group and sex
Original appendix title: Ultima e massima HbA1c nel 2010 tra i pazienti attivi per fascia d’età e sesso (n attivi, n testati, media/mediana ultima, % max ≥9/≥10 su testati)

Purpose:
- Latest and maximum HbA1c in 2010 among active patients by age group and sex.
*/
SELECT
 b.fascia_eta, b.sesso,
 COUNT(DISTINCT (b.idcentro, b.idana)) AS n_attivi,

 COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE l.last_hba1c IS NOT NULL)
AS n_testati,
 ROUND(AVG(l.last_hba1c) FILTER (WHERE l.last_hba1c IS NOT NULL), 2) AS
media_last,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.last_hba1c)
   FILTER (WHERE l.last_hba1c IS NOT NULL) AS mediana_last,
 ROUND(
   100.0 * COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c >=
9.0)
   / NULLIF(COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c IS
NOT NULL), 0)
 , 2) AS pct_max_ge_9_su_testati,
 ROUND(
   100.0 * COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c >=
10.0)
   / NULLIF(COUNT(DISTINCT (b.idcentro, b.idana)) FILTER (WHERE m.max_hba1c IS
NOT NULL), 0)
 , 2) AS pct_max_ge_10_su_testati
FROM (
 SELECT
   a.idcentro, a.idana, a.sesso,
   CASE
     WHEN (2010 - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
     WHEN (2010 - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
     WHEN (2010 - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
     ELSE '80+'
   END AS fascia_eta
 FROM (
   SELECT idcentro, idana
   FROM (
     SELECT idcentro, idana, EXTRACT(YEAR FROM data)::int AS anno
     FROM daibetes1.esamilaboratorioparametri WHERE data IS NOT NULL
     UNION ALL
     SELECT idcentro, idana, EXTRACT(YEAR FROM data)::int
     FROM daibetes1.prescrizionidiabetefarmaci WHERE data IS NOT NULL
     UNION ALL
     SELECT idcentro, idana, EXTRACT(YEAR FROM data)::int
     FROM daibetes1.prescrizionidiabetenonfarmaci WHERE data IS NOT NULL
   ) ev
   WHERE ev.anno = 2010
   GROUP BY idcentro, idana
 )y
 JOIN daibetes1.anagrafica a ON a.idcentro = y.idcentro AND a.idana = y.idana
 WHERE a.sesso IS NOT NULL

   AND a.annonascita IS NOT NULL
   AND (2010 - a.annonascita) BETWEEN 18 AND 110
)b
LEFT JOIN (
 SELECT DISTINCT ON (d.idcentro, d.idana)
      d.idcentro, d.idana, d.data, d.hba1c_pct AS last_hba1c
 FROM (
   SELECT DISTINCT ON (e.idcentro, e.idana, e.data)
       e.idcentro, e.idana, e.data,
       CASE
         WHEN e.codiceamd = 'AMD305' THEN
          (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
         ELSE
          CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
       END AS hba1c_pct,
       CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
   FROM daibetes1.esamilaboratorioparametri e
   WHERE e.data IS NOT NULL
    AND EXTRACT(YEAR FROM e.data)::int = 2010
    AND e.valore IS NOT NULL
    AND e.codiceamd IN ('AMD008','AMD305')
    AND (
      CASE
       WHEN e.codiceamd = 'AMD305' THEN
        (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
       ELSE
        CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
      END
    ) BETWEEN 4 AND 15
   ORDER BY e.idcentro, e.idana, e.data, pref
 )d
 ORDER BY d.idcentro, d.idana, d.data DESC
)l
 ON l.idcentro = b.idcentro AND l.idana = b.idana
LEFT JOIN (
 SELECT d2.idcentro, d2.idana, MAX(d2.hba1c_pct) AS max_hba1c
 FROM (
   SELECT DISTINCT ON (e.idcentro, e.idana, e.data)
       e.idcentro, e.idana, e.data,
       CASE

         WHEN e.codiceamd = 'AMD305' THEN
          (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
         ELSE
          CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
       END AS hba1c_pct,
       CASE WHEN e.codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
   FROM daibetes1.esamilaboratorioparametri e
   WHERE e.data IS NOT NULL
    AND EXTRACT(YEAR FROM e.data)::int = 2010
    AND e.valore IS NOT NULL
    AND e.codiceamd IN ('AMD008','AMD305')
    AND (
      CASE
       WHEN e.codiceamd = 'AMD305' THEN
        (CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric) / 10.929) + 2.15
       ELSE
        CAST(REPLACE(REGEXP_REPLACE(e.valore, '[^0-9,.-]', '', 'g'), ',', '.') AS
numeric)
      END
    ) BETWEEN 4 AND 15
   ORDER BY e.idcentro, e.idana, e.data, pref
 ) d2
 GROUP BY d2.idcentro, d2.idana
)m
 ON m.idcentro = b.idcentro AND m.idana = b.idana
GROUP BY b.fascia_eta, b.sesso
ORDER BY
 CASE b.fascia_eta
   WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3 ELSE 4 END,
 b.sesso;
