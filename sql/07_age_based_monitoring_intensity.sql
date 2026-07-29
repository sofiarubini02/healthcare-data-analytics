/*
===============================================================================
Age-based monitoring intensity
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
Q34: HbA1c testing intensity per patient-year by age group
Original appendix title: Intensità dei controlli HbA1c per paziente-anno per fascia d’età (media e % ≥2)

Purpose:
- HbA1c testing intensity per patient-year by age group.
*/
SELECT
 b.fascia_eta,
 COUNT(*) AS pazienti_anni,
 ROUND(AVG(COALESCE(h.n_hba1c,0))::numeric, 2) AS media_hba1c_ppa,
 ROUND(100.0 * COUNT(*) FILTER (WHERE COALESCE(h.n_hba1c,0) >= 2) / COUNT(*), 2)
AS pct_ge_2
FROM (
 SELECT
  y.idcentro, y.idana, y.anno,

  CASE
    WHEN (y.anno - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
    WHEN (y.anno - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
    WHEN (y.anno - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
    ELSE '80+'
  END AS fascia_eta
 FROM (
  SELECT idcentro, idana, anno
  FROM (
    SELECT e.idcentro, e.idana, EXTRACT(YEAR FROM e.data)::int AS anno
    FROM daibetes1.esamilaboratorioparametri e
    WHERE e.data IS NOT NULL
    UNION ALL
    SELECT pf.idcentro, pf.idana, EXTRACT(YEAR FROM pf.data)::int
    FROM daibetes1.prescrizionidiabetefarmaci pf
    WHERE pf.data IS NOT NULL
    UNION ALL
    SELECT pn.idcentro, pn.idana, EXTRACT(YEAR FROM pn.data)::int
    FROM daibetes1.prescrizionidiabetenonfarmaci pn
    WHERE pn.data IS NOT NULL
  )u
  GROUP BY idcentro, idana, anno
 )y
 JOIN daibetes1.anagrafica a
  ON a.idcentro = y.idcentro AND a.idana = y.idana
 WHERE a.annonascita IS NOT NULL
  AND (y.anno - a.annonascita) BETWEEN 18 AND 110
)b
LEFT JOIN (
 SELECT
  idcentro, idana, EXTRACT(YEAR FROM data)::int AS anno,
  COUNT(*) AS n_hba1c
 FROM (
  SELECT DISTINCT ON (idcentro, idana, data)
      idcentro, idana, data, codiceamd
  FROM daibetes1.esamilaboratorioparametri
  WHERE data IS NOT NULL
    AND valore IS NOT NULL
    AND regexp_replace(valore, ',', '.', 'g') ~ '^[0-9]+(\.[0-9]+)?$'
    AND codiceamd IN ('AMD008','AMD305')
  ORDER BY idcentro, idana, data,
        CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
 )d
 GROUP BY idcentro, idana, EXTRACT(YEAR FROM data)::int

)h
 ON h.idcentro = b.idcentro AND h.idana = b.idana AND h.anno = b.anno
GROUP BY b.fascia_eta
ORDER BY CASE b.fascia_eta
      WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3 ELSE 4
    END;

/*
Q35: HbA1c testing intensity per patient-year by age group and sex
Original appendix title: Intensità dei controlli HbA1c per paziente-anno per fascia d’età e sesso (media e % ≥2)

Purpose:
- HbA1c testing intensity per patient-year by age group and sex.
*/
SELECT
 b.fascia_eta,
 b.sesso,
 COUNT(*) AS pazienti_anni,
 ROUND(AVG(COALESCE(h.n_hba1c,0))::numeric, 2) AS media_hba1c_ppa,
 ROUND(100.0 * COUNT(*) FILTER (WHERE COALESCE(h.n_hba1c,0) >= 2) / COUNT(*), 2)
AS pct_ge_2
FROM (
 SELECT
  y.idcentro, y.idana, y.anno,
  a.sesso,
  CASE
    WHEN (y.anno - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
    WHEN (y.anno - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
    WHEN (y.anno - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
    ELSE '80+'
  END AS fascia_eta
 FROM (
  SELECT idcentro, idana, anno
  FROM (
    SELECT e.idcentro, e.idana, EXTRACT(YEAR FROM e.data)::int AS anno
    FROM daibetes1.esamilaboratorioparametri e
    WHERE e.data IS NOT NULL
    UNION ALL

    SELECT pf.idcentro, pf.idana, EXTRACT(YEAR FROM pf.data)::int
    FROM daibetes1.prescrizionidiabetefarmaci pf
    WHERE pf.data IS NOT NULL
    UNION ALL
    SELECT pn.idcentro, pn.idana, EXTRACT(YEAR FROM pn.data)::int
    FROM daibetes1.prescrizionidiabetenonfarmaci pn
    WHERE pn.data IS NOT NULL
  )u
  GROUP BY idcentro, idana, anno
 )y
 JOIN daibetes1.anagrafica a
  ON a.idcentro = y.idcentro AND a.idana = y.idana
 WHERE a.annonascita IS NOT NULL
  AND a.sesso IS NOT NULL
  AND (y.anno - a.annonascita) BETWEEN 18 AND 110
)b
LEFT JOIN (
 SELECT
  idcentro, idana, EXTRACT(YEAR FROM data)::int AS anno,
  COUNT(*) AS n_hba1c
 FROM (
  SELECT DISTINCT ON (idcentro, idana, data)
      idcentro, idana, data, codiceamd
  FROM daibetes1.esamilaboratorioparametri
  WHERE data IS NOT NULL
    AND valore IS NOT NULL
    AND regexp_replace(valore, ',', '.', 'g') ~ '^[0-9]+(\.[0-9]+)?$'
    AND codiceamd IN ('AMD008','AMD305')
  ORDER BY idcentro, idana, data,
        CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
 )d
 GROUP BY idcentro, idana, EXTRACT(YEAR FROM data)::int
)h
 ON h.idcentro = b.idcentro AND h.idana = b.idana AND h.anno = b.anno
GROUP BY b.fascia_eta, b.sesso
ORDER BY
 CASE b.fascia_eta
  WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3 ELSE 4
 END,
 b.sesso;

/*
Q36: HbA1c testing intensity by age at diagnosis and disease phase
Original appendix title: Intensità HbA1c per paziente-anno per fascia d’età alla diagnosi e fase di malattia (media e % ≥2)

Purpose:
- HbA1c testing intensity by age at diagnosis and disease phase.
*/
SELECT
 b.fascia_eta, y.fase_malattia,
 COUNT(*) AS pazienti_anni,
 ROUND(AVG(COALESCE(h.n_hba1c,0))::numeric, 2) AS media_N_hba1c_ppa,
 ROUND(100.0 * COUNT(*) FILTER (WHERE COALESCE(h.n_hba1c,0) >= 2) / COUNT(*), 2)
AS pct_ge_2
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
  AND a.annonascita        IS NOT NULL
  AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 110
  AND COALESCE(a.inconsistenza,0) = 0
)b
JOIN (
 SELECT
  u.idcentro, u.idana, u.anno,
  CASE

     WHEN (u.anno - c.dx_year) BETWEEN 0 AND 1 THEN '0-1y'
     WHEN (u.anno - c.dx_year) BETWEEN 2 AND 5 THEN '2-5y'
     WHEN (u.anno - c.dx_year) BETWEEN 6 AND 10 THEN '6-10y'
     ELSE '11+y'
   END AS fase_malattia
 FROM (
   SELECT idcentro, idana, anno
   FROM (
     SELECT e.idcentro, e.idana, EXTRACT(YEAR FROM e.data)::int AS anno
     FROM daibetes1.esamilaboratorioparametri e
     WHERE e.data IS NOT NULL
     UNION ALL
     SELECT pf.idcentro, pf.idana, EXTRACT(YEAR FROM pf.data)::int
     FROM daibetes1.prescrizionidiabetefarmaci pf
     WHERE pf.data IS NOT NULL
     UNION ALL
     SELECT pn.idcentro, pn.idana, EXTRACT(YEAR FROM pn.data)::int
     FROM daibetes1.prescrizionidiabetenonfarmaci pn
     WHERE pn.data IS NOT NULL
   ) ev
   GROUP BY idcentro, idana, anno
 )u
 JOIN (
   SELECT idcentro, idana, annodiagnosidiabete AS dx_year
   FROM daibetes1.anagrafica
   WHERE annodiagnosidiabete IS NOT NULL
     AND annonascita       IS NOT NULL
     AND (annodiagnosidiabete - annonascita) BETWEEN 18 AND 110
     AND COALESCE(inconsistenza,0) = 0
 ) c ON c.idcentro = u.idcentro AND c.idana = u.idana
 WHERE (u.anno - c.dx_year) BETWEEN 0 AND 50
)y
 ON y.idcentro = b.idcentro AND y.idana = b.idana
LEFT JOIN (
 SELECT
   idcentro, idana, EXTRACT(YEAR FROM data)::int AS anno,
   COUNT(*) AS n_hba1c
 FROM (
   SELECT DISTINCT ON (idcentro, idana, data)
        idcentro, idana, data, codiceamd
   FROM daibetes1.esamilaboratorioparametri
   WHERE data IS NOT NULL
     AND valore IS NOT NULL
     AND regexp_replace(valore, ',', '.', 'g') ~ '^[0-9]+(\.[0-9]+)?$'

   AND codiceamd IN ('AMD008','AMD305')
  ORDER BY idcentro, idana, data,
       CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
 )d
 GROUP BY idcentro, idana, EXTRACT(YEAR FROM data)::int
)h
 ON h.idcentro = y.idcentro AND h.idana = y.idana AND h.anno = y.anno
GROUP BY b.fascia_eta, y.fase_malattia
ORDER BY
 CASE b.fascia_eta WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3
ELSE 4 END,
 CASE y.fase_malattia WHEN '0-1y' THEN 1 WHEN '2-5y' THEN 2 WHEN '6-10y' THEN 3
ELSE 4 END;

/*
Q37: Age at diagnosis: patient-years, mean HbA1c, testing intensity, and latest HbA1c
Original appendix title: Età alla diagnosi — paziente-anni, media HbA1c, %≥2; ultima HbA1c (media/mediana).

Purpose:
- Age at diagnosis: patient-years, mean HbA1c, testing intensity, and latest HbA1c.
*/
SELECT

 f.fascia_eta,
 ROUND(f.media_hba1c, 2) AS media_hba1c_ppa,
 ROUND(f.pct_ge_2, 2) AS pct_2_ppa,
 f.pazienti_anni,
 f.n_pazienti_unici,
 ROUND(v.media_hba1c_valore, 2) AS media_valore_hba1c_ultima,
 v.mediana_hba1c_valore AS mediana_valore_hba1c_ultima,
 v.n_pazienti AS n_pazienti_con_hba1c
FROM (
 SELECT
   bc.fascia_eta,
   COUNT(*) AS pazienti_anni,
   COUNT(DISTINCT (y.idcentro, y.idana)) AS n_pazienti_unici,
   AVG(COALESCE(h.n_hba1c,0)) AS media_hba1c,
   CASE WHEN COUNT(*) = 0 THEN 0
      ELSE 100.0 * COUNT(*) FILTER (WHERE COALESCE(h.n_hba1c,0) >= 2) / COUNT(*)
   END AS pct_ge_2
 FROM (
   SELECT
    a.idcentro, a.idana,
    a.annodiagnosidiabete AS dx_year,
    CASE
      WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
      WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
      WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
      ELSE '80+'
    END AS fascia_eta
   FROM daibetes1.anagrafica a
   WHERE a.annodiagnosidiabete IS NOT NULL
    AND a.annonascita IS NOT NULL
    AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 110
    AND COALESCE(a.inconsistenza,0) = 0
 ) bc
 JOIN (
   SELECT idcentro, idana, anno
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
   )u
   GROUP BY idcentro, idana, anno
 )y
   ON y.idcentro = bc.idcentro AND y.idana = bc.idana
 LEFT JOIN (
   SELECT
    idcentro, idana, EXTRACT(YEAR FROM data)::int AS anno,
    COUNT(*) AS n_hba1c
   FROM (
    SELECT DISTINCT ON (idcentro, idana, data)
         idcentro, idana, data, codiceamd
    FROM daibetes1.esamilaboratorioparametri
    WHERE data IS NOT NULL
      AND valore IS NOT NULL
      AND regexp_replace(valore, ',', '.', 'g') ~ '^[0-9]+(\.[0-9]+)?$'
      AND codiceamd IN ('AMD008','AMD305')
    ORDER BY idcentro, idana, data,
           CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
   )d
   GROUP BY idcentro, idana, EXTRACT(YEAR FROM data)::int
 )h
   ON h.idcentro = y.idcentro AND h.idana = y.idana AND h.anno = y.anno
 GROUP BY bc.fascia_eta
)f
JOIN (
 SELECT
   fas.fascia_eta,
   AVG(fas.hba1c) AS media_hba1c_valore,
   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fas.hba1c) AS
mediana_hba1c_valore,
   COUNT(*) AS n_pazienti
 FROM (
   SELECT
    a.idcentro, a.idana,
    CASE
      WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 39 THEN '18-39'
      WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 40 AND 64 THEN '40-64'
      WHEN (a.annodiagnosidiabete - a.annonascita) BETWEEN 65 AND 79 THEN '65-79'
      ELSE '80+'
    END AS fascia_eta,
    t.hba1c

   FROM daibetes1.anagrafica a
   JOIN (
    SELECT DISTINCT ON (idcentro, idana)
        idcentro, idana, data,
        CASE
          WHEN codiceamd = 'AMD305'
           THEN ROUND((regexp_replace(valore, ',', '.', 'g'))::decimal / 10.929 + 2.15, 1)
          ELSE (regexp_replace(valore, ',', '.', 'g'))::decimal
        END AS hba1c,
        CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END AS pref
    FROM daibetes1.esamilaboratorioparametri
    WHERE data IS NOT NULL
      AND valore IS NOT NULL
      AND codiceamd IN ('AMD008','AMD305')
      AND regexp_replace(valore, ',', '.', 'g') ~ '^[0-9]+(\.[0-9]+)?$'
    ORDER BY idcentro, idana, data DESC, pref
   )t
    ON t.idcentro = a.idcentro AND t.idana = a.idana
   WHERE a.annodiagnosidiabete IS NOT NULL
    AND a.annonascita IS NOT NULL
    AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 18 AND 110
    AND COALESCE(a.inconsistenza,0) = 0
    AND t.hba1c BETWEEN 4 AND 15
 ) fas
 GROUP BY fas.fascia_eta
)v
 ON v.fascia_eta = f.fascia_eta
ORDER BY
 CASE f.fascia_eta
   WHEN '18-39' THEN 1 WHEN '40-64' THEN 2 WHEN '65-79' THEN 3 ELSE 4
 END;
