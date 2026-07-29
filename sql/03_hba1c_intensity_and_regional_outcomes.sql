/*
===============================================================================
HbA1c testing intensity and regional outcomes
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
Q11: HbA1c testing intensity among active patients by year and sex
Original appendix title: Intensità dei test HbA1c tra i pazienti attivi per anno e sesso

Purpose:
- HbA1c testing intensity among active patients by year and sex.
*/
SELECT
 y.anno, a.sesso,
 COUNT(*) AS pazienti_attivi,
 ROUND(AVG(COALESCE(h.n_hba1c,0))::numeric, 2) AS media_hba1c_ppa,

 ROUND(100.0 * COUNT(*) FILTER (WHERE COALESCE(h.n_hba1c,0) >= 2) / COUNT(*), 2)
AS pct_ge_2
FROM (
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
JOIN daibetes1.anagrafica a
 ON a.idcentro = y.idcentro AND a.idana = y.idana
LEFT JOIN (
 SELECT
   idcentro,
   idana,
   EXTRACT(YEAR FROM data)::int AS anno,
   COUNT(*) AS n_hba1c
 FROM (
   SELECT DISTINCT ON (idcentro, idana, data)
       idcentro, idana, data, codiceamd
   FROM daibetes1.esamilaboratorioparametri
   WHERE data IS NOT NULL
     AND valore IS NOT NULL
     AND codiceamd IN ('AMD008','AMD305')
   ORDER BY idcentro, idana, data,
         CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
 )d
 GROUP BY idcentro, idana, EXTRACT(YEAR FROM data)::int
)h
 ON h.idcentro = y.idcentro AND h.idana = y.idana AND h.anno = y.anno
WHERE a.sesso IS NOT NULL
GROUP BY y.anno, a.sesso
ORDER BY y.anno, a.sesso;

/*
Q12: HbA1c testing intensity among unique active patients by sex
Original appendix title: Intensità dei test HbA1c tra i pazienti attivi unici per sesso (media per paziente-anno e % ≥2)

Purpose:
- HbA1c testing intensity among unique active patients by sex.
*/
SELECT
 a.sesso,
 COUNT(DISTINCT (y.idcentro, y.idana)) AS pazienti_attivi_unici,
 ROUND(AVG(COALESCE(h.n_hba1c,0))::numeric, 2) AS media_hba1c,
 ROUND(100.0 * COUNT(*) FILTER (WHERE COALESCE(h.n_hba1c,0) >= 2) / COUNT(*), 2)
AS pct_2
FROM (
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
JOIN daibetes1.anagrafica a
 ON a.idcentro = y.idcentro AND a.idana = y.idana
LEFT JOIN (
 SELECT
   idcentro,
   idana,
   EXTRACT(YEAR FROM data)::int AS anno,
   COUNT(*) AS n_hba1c
 FROM (
   SELECT DISTINCT ON (idcentro, idana, data)
       idcentro, idana, data, codiceamd
   FROM daibetes1.esamilaboratorioparametri
   WHERE data IS NOT NULL
     AND valore IS NOT NULL
     AND codiceamd IN ('AMD008','AMD305')
   ORDER BY idcentro, idana, data,
         CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END

 )d
 GROUP BY idcentro, idana, EXTRACT(YEAR FROM data)::int
)h
 ON h.idcentro = y.idcentro AND h.idana = y.idana AND h.anno = y.anno
WHERE a.sesso IS NOT NULL
GROUP BY a.sesso
ORDER BY a.sesso;

/*
Q13: HbA1c testing intensity among unique active patients by region
Original appendix title: Intensità dei test HbA1c tra i pazienti attivi unici per regione (media per paziente-anno e % ≥2)

Purpose:
- HbA1c testing intensity among unique active patients by region.
*/
SELECT
 c.regione,
 COUNT(DISTINCT (y.idcentro, y.idana)) AS pazienti_attivi_unici,
 ROUND(AVG(COALESCE(h.n_hba1c,0))::numeric, 2) AS media_hba1c_per_anno_attivo,
 ROUND(100.0 * COUNT(*) FILTER (WHERE COALESCE(h.n_hba1c,0) >= 2) / COUNT(*), 2)
AS pct_ge_2
FROM (
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
JOIN daibetes1.centriamd c
 ON c.idcentro = y.idcentro

LEFT JOIN (
 SELECT
  idcentro,
  idana,
  EXTRACT(YEAR FROM data)::int AS anno,
  COUNT(*) AS n_hba1c
 FROM (
  SELECT DISTINCT ON (idcentro, idana, data)
      idcentro, idana, data, codiceamd
  FROM daibetes1.esamilaboratorioparametri
  WHERE data IS NOT NULL
    AND valore IS NOT NULL
    AND codiceamd IN ('AMD008','AMD305')
  ORDER BY idcentro, idana, data,
        CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
 )d
 GROUP BY idcentro, idana, EXTRACT(YEAR FROM data)::int
)h
 ON h.idcentro = y.idcentro AND h.idana = y.idana AND h.anno = y.anno
WHERE c.regione IS NOT NULL
GROUP BY c.regione
ORDER BY media_hba1c_per_anno_attivo desc;

/*
Q14: Latest normalized HbA1c per patient by sex
Original appendix title: Ultima HbA1c normalizzata per paziente: media e mediana per sesso

Purpose:
- Latest normalized HbA1c per patient by sex.
*/
SELECT
  a.sesso,
  COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti,
  ROUND(AVG(fh.hba1c_pct)::numeric, 2) AS media_hba1c,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fh.hba1c_pct))::numeric, 2)
AS mediana_hba1c
FROM daibetes1.anagrafica a
JOIN (
  SELECT DISTINCT ON (idcentro, idana)
      idcentro, idana, data,
      CASE
        WHEN codiceamd = 'AMD305' THEN
         (CAST(REPLACE(REGEXP_REPLACE(valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric) /
10.929) + 2.15
        ELSE
         CAST(REPLACE(REGEXP_REPLACE(valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
      END AS hba1c_pct
  FROM daibetes1.esamilaboratorioparametri
  WHERE data IS NOT NULL
   AND valore IS NOT NULL
   AND codiceamd IN ('AMD008','AMD305')
  ORDER BY idcentro, idana, data DESC,
        CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
) fh
  ON fh.idcentro = a.idcentro AND fh.idana = a.idana
WHERE a.sesso IS NOT NULL
  AND fh.hba1c_pct BETWEEN 4 AND 15
GROUP BY a.sesso
ORDER BY a.sesso;

/*
Q15: Latest normalized HbA1c per patient by region
Original appendix title: Ultima HbA1c normalizzata per paziente: media e mediana per regione

Purpose:
- Latest normalized HbA1c per patient by region.
*/
SELECT
  c.regione,
  COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti,
  ROUND(AVG(fh.hba1c_pct)::numeric, 2) AS media_hba1c,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fh.hba1c_pct))::numeric, 2)
AS mediana_hba1c
FROM daibetes1.anagrafica a
JOIN daibetes1.centriamd c ON c.idcentro = a.idcentro
JOIN (
  SELECT DISTINCT ON (idcentro, idana)
      idcentro, idana, data,
      CASE
        WHEN codiceamd = 'AMD305' THEN
         (CAST(REPLACE(REGEXP_REPLACE(valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric) /
10.929) + 2.15
        ELSE
         CAST(REPLACE(REGEXP_REPLACE(valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
      END AS hba1c_pct
  FROM daibetes1.esamilaboratorioparametri
  WHERE data IS NOT NULL
   AND valore IS NOT NULL
   AND codiceamd IN ('AMD008','AMD305')
  ORDER BY idcentro, idana, data DESC,
        CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
) fh ON fh.idcentro = a.idcentro AND fh.idana = a.idana
WHERE c.regione IS NOT NULL
  AND fh.hba1c_pct BETWEEN 4 AND 15
GROUP BY c.regione
ORDER BY media_hba1c desc, c.regione;

/*
Q16: Regional summary indicators: active patients, testing intensity, and latest HbA1c
Original appendix title: Indicatori per regione: pazienti attivi unici, intensità dei test HbA1c (paziente-anno) e ultima HbA1c (media/mediana)

Purpose:
- Regional summary indicators: active patients, testing intensity, and latest HbA1c.
*/
SELECT
 f.regione,
 ROUND(f.media_hba1c, 2) AS media_hba1c,
 ROUND(f.pct_ge_2, 2) AS pct_2,
 f.pazienti_attivi_unici,
 ROUND(v.media_hba1c_valore, 2) AS media_valore_hba1c,
 ROUND((v.mediana_hba1c_valore)::numeric, 2) AS mediana_valore_hba1c,
 v.n_pazienti AS n_pazienti_con_hba1c
FROM (
 SELECT
   c.regione,
   COUNT(DISTINCT (y.idcentro, y.idana)) AS pazienti_attivi_unici,
   AVG(COALESCE(h.n_hba1c,0)) AS media_hba1c,
   CASE WHEN COUNT(*) = 0 THEN 0
       ELSE 100.0 * COUNT(*) FILTER (WHERE COALESCE(h.n_hba1c,0) >= 2) / COUNT(*)
   END AS pct_ge_2
 FROM (
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
 JOIN daibetes1.centriamd c
   ON c.idcentro = y.idcentro
 LEFT JOIN (
   SELECT
    idcentro, idana, EXTRACT(YEAR FROM data)::int AS anno, COUNT(*) AS n_hba1c
   FROM (
    SELECT DISTINCT ON (idcentro, idana, data)
         idcentro, idana, data, codiceamd
    FROM daibetes1.esamilaboratorioparametri
    WHERE data IS NOT NULL
      AND valore IS NOT NULL
      AND codiceamd IN ('AMD008','AMD305')
    ORDER BY idcentro, idana, data,
           CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
   )d
   GROUP BY idcentro, idana, EXTRACT(YEAR FROM data)::int
 )h
   ON h.idcentro = y.idcentro AND h.idana = y.idana AND h.anno = y.anno
 WHERE c.regione IS NOT NULL
 GROUP BY c.regione
)f
JOIN (
 SELECT
   c.regione,
   AVG(t.hba1c) AS media_hba1c_valore,
   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY t.hba1c) AS
mediana_hba1c_valore,
   COUNT(*) AS n_pazienti
 FROM daibetes1.centriamd c

 JOIN (
   SELECT DISTINCT ON (idcentro, idana)
       idcentro, idana, data,
       CASE
         WHEN codiceamd = 'AMD305' THEN
          (CAST(REPLACE(REGEXP_REPLACE(valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric) /
10.929) + 2.15
         ELSE
          CAST(REPLACE(REGEXP_REPLACE(valore, '[^0-9,.-]', '', 'g'), ',', '.') AS numeric)
       END AS hba1c
   FROM daibetes1.esamilaboratorioparametri
   WHERE data IS NOT NULL
    AND valore IS NOT NULL
    AND codiceamd IN ('AMD008','AMD305')
   ORDER BY idcentro, idana, data DESC,
         CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
 )t
   ON t.idcentro = c.idcentro
 WHERE c.regione IS NOT NULL
   AND t.hba1c BETWEEN 4 AND 15
 GROUP BY c.regione
)v
 ON v.regione = f.regione
ORDER BY f.media_hba1c DESC, f.regione;
