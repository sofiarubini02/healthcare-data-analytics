/*
===============================================================================
HbA1c coverage and timeliness
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
Q6: HbA1c test coverage in the year of diagnosis by region and year
Original appendix title: Copertura del test HbA1c nell’anno di diagnosi per regione e anno

Purpose:
- HbA1c test coverage in the year of diagnosis by region and year.
*/
SELECT
 t.regione, t.anno, t.neo, t.neo_con_hba1c_stesso_anno,
 ROUND(100.0 * t.neo_con_hba1c_stesso_anno / NULLIF(t.neo,0), 2) AS
pct_stesso_anno_su_neo
FROM (
 SELECT
   c.regione, n.anno,
   COUNT(DISTINCT (n.idcentro, n.idana)) AS neo,
   COUNT(DISTINCT (n.idcentro, n.idana)) FILTER (WHERE hba.idana IS NOT NULL) AS
neo_con_hba1c_stesso_anno
 FROM (
   SELECT idcentro, idana, annodiagnosidiabete AS anno
   FROM daibetes1.anagrafica
   WHERE annodiagnosidiabete IS NOT NULL
    AND annonascita IS NOT NULL
    AND (annodiagnosidiabete - annonascita) BETWEEN 0 AND 110
    AND COALESCE(inconsistenza,0) = 0
 )n
 JOIN daibetes1.centriamd c
   ON c.idcentro = n.idcentro
 LEFT JOIN (
   SELECT DISTINCT idcentro, idana, EXTRACT(YEAR FROM data)::int AS anno
   FROM daibetes1.esamilaboratorioparametri
   WHERE data IS NOT NULL
    AND valore IS NOT NULL
    AND codiceamd IN ('AMD008','AMD305')
 ) hba
   ON hba.idcentro = n.idcentro
  AND hba.idana = n.idana
  AND hba.anno = n.anno
 WHERE c.regione IS NOT NULL
 GROUP BY c.regione, n.anno
)t
ORDER BY t.anno, t.regione;

/*
Q7: Time to first HbA1c after diagnosis by sex
Original appendix title: Tempestività della prima HbA1c post-diagnosi per sesso (stesso anno, ≤1 anno, ≥2 anni)

Purpose:
- Time to first HbA1c after diagnosis by sex.
*/
SELECT
 a.sesso,
 COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti,
 COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (WHERE f.first_year_post_dx IS NOT NULL)
AS n_con_hba1c_post_dx,
 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (WHERE f.first_year_post_dx IS
NOT NULL)
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)),0), 2
 ) AS pct_con_hba1c_post_dx,
 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (WHERE f.first_year_post_dx =
a.annodiagnosidiabete)

   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)),0), 2
 ) AS pct_stesso_anno,
 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (
     WHERE f.first_year_post_dx IS NOT NULL
      AND (f.first_year_post_dx - a.annodiagnosidiabete) BETWEEN 0 AND 1
   )
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)),0), 2
 ) AS pct_entro_1_anno,
 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (
     WHERE f.first_year_post_dx IS NOT NULL
      AND (f.first_year_post_dx - a.annodiagnosidiabete) >= 2
   )
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)),0), 2
 ) AS pct_ritardo_ge_2_anni

FROM daibetes1.anagrafica a
LEFT JOIN (
 SELECT e.idcentro, e.idana,
     MIN(EXTRACT(YEAR FROM e.data)::int) AS first_year_post_dx
 FROM daibetes1.esamilaboratorioparametri e
 JOIN daibetes1.anagrafica ax
   ON ax.idcentro = e.idcentro AND ax.idana = e.idana
 WHERE e.data IS NOT NULL
   AND e.valore IS NOT NULL
   AND e.codiceamd IN ('AMD008','AMD305')
   AND EXTRACT(YEAR FROM e.data)::int >= ax.annodiagnosidiabete
 GROUP BY e.idcentro, e.idana
)f
 ON f.idcentro = a.idcentro AND f.idana = a.idana
WHERE a.sesso IS NOT NULL
 AND a.annodiagnosidiabete IS NOT NULL
 AND a.annonascita IS NOT NULL
 AND (a.annodiagnosidiabete - a.annonascita) BETWEEN 0 AND 110
 AND COALESCE(a.inconsistenza,0) = 0
GROUP BY a.sesso
ORDER BY a.sesso;

/*
Q8: Time to first HbA1c after first access by sex
Original appendix title: Tempestività della prima HbA1c dopo il primo accesso per sesso (stesso anno, ≤1 anno, ≥2 anni)

Purpose:
- Time to first HbA1c after first access by sex.
*/
SELECT
 a.sesso,
 COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti,
 COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (WHERE fh.first_year IS NOT NULL) AS
n_con_hba1c_post_accesso,

 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (WHERE fh.first_year IS NOT
NULL)
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)), 0), 2
 ) AS pct_con_hba1c_post_accesso,

 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (WHERE fh.first_year =
a.annoprimoaccesso)
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)), 0), 2
 ) AS pct_stesso_anno,

 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (
     WHERE fh.first_year IS NOT NULL
      AND (fh.first_year - a.annoprimoaccesso) BETWEEN 0 AND 1
   )
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)), 0), 2
 ) AS pct_entro_1_anno,

 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (
     WHERE fh.first_year IS NOT NULL
      AND (fh.first_year - a.annoprimoaccesso) >= 2
   )
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)), 0), 2
 ) AS pct_ritardo_ge_2_anni

FROM daibetes1.anagrafica a
LEFT JOIN (
 SELECT
  e.idcentro, e.idana,
  MIN(EXTRACT(YEAR FROM e.data)::int) AS first_year
 FROM daibetes1.esamilaboratorioparametri e
 JOIN daibetes1.anagrafica a2

   ON a2.idcentro = e.idcentro AND a2.idana = e.idana
  WHERE e.data IS NOT NULL
   AND e.valore IS NOT NULL
   AND e.codiceamd IN ('AMD008','AMD305')
   AND e.data >= make_date(a2.annoprimoaccesso, 1, 1)
  GROUP BY e.idcentro, e.idana
) fh
  ON fh.idcentro = a.idcentro AND fh.idana = a.idana
WHERE a.sesso IS NOT NULL
  AND a.annoprimoaccesso IS NOT NULL
GROUP BY a.sesso
ORDER BY a.sesso;

/*
Q9: Time to first HbA1c after the first recorded clinical event by sex
Original appendix title: Tempestività della prima HbA1c rispetto al primo evento (visita/esame/prescrizione) per sesso (stesso anno, ≤1 anno, ≥2 anni)

Purpose:
- Time to first HbA1c after the first recorded clinical event by sex.
*/
SELECT
 a.sesso,
 COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti,
 COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (WHERE fh.first_year IS NOT NULL) AS
n_con_hba1c,

 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (WHERE fh.first_year IS NOT
NULL)
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)), 0), 2
 ) AS pct_con_hba1c,

 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (WHERE fh.first_year =
pe.first_year)
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)), 0), 2
 ) AS pct_stesso_anno,

 ROUND(
   100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (
     WHERE fh.first_year IS NOT NULL AND (fh.first_year - pe.first_year) BETWEEN 0 AND 1
   )
   / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)), 0), 2
 ) AS pct_entro_1_anno,

  ROUND(
    100.0 * COUNT(DISTINCT (a.idcentro, a.idana)) FILTER (
      WHERE fh.first_year IS NOT NULL AND (fh.first_year - pe.first_year) >= 2
    )
    / NULLIF(COUNT(DISTINCT (a.idcentro, a.idana)), 0), 2
  ) AS pct_ritardo_ge_2_anni
FROM daibetes1.anagrafica a
LEFT JOIN (
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
) pe
  ON pe.idcentro = a.idcentro AND pe.idana = a.idana
LEFT JOIN (
  SELECT idcentro, idana, MIN(EXTRACT(YEAR FROM data)::int) AS first_year
  FROM daibetes1.esamilaboratorioparametri
  WHERE data IS NOT NULL
    AND valore IS NOT NULL
    AND codiceamd IN ('AMD008','AMD305')
  GROUP BY idcentro, idana
) fh
  ON fh.idcentro = a.idcentro AND fh.idana = a.idana
WHERE a.sesso IS NOT NULL
  AND pe.first_year IS NOT NULL
GROUP BY a.sesso
ORDER BY a.sesso;

/*
Q10: HbA1c coverage in the year of the first recorded clinical event by region
Original appendix title: Copertura del test HbA1c nell’anno del primo evento per regione

Purpose:
- HbA1c coverage in the year of the first recorded clinical event by region.
*/
SELECT

 c.regione,
 COUNT(DISTINCT (n.idcentro, n.idana)) AS pazienti_primo_evento,
 COUNT(DISTINCT (n.idcentro, n.idana)) FILTER (
   WHERE EXISTS (
     SELECT 1
     FROM daibetes1.esamilaboratorioparametri e
     WHERE e.idcentro = n.idcentro
       AND e.idana = n.idana
       AND e.data IS NOT NULL
       AND e.valore IS NOT NULL
       AND e.codiceamd IN ('AMD008','AMD305')
       AND EXTRACT(YEAR FROM e.data)::int = n.anno_pe
   )
 ) AS con_hba1c_stesso_anno,
 CASE
   WHEN COUNT(DISTINCT (n.idcentro, n.idana)) = 0 THEN NULL
   ELSE ROUND(
     100.0 * COUNT(DISTINCT (n.idcentro, n.idana)) FILTER (
       WHERE EXISTS (
         SELECT 1
         FROM daibetes1.esamilaboratorioparametri e
         WHERE e.idcentro = n.idcentro
          AND e.idana = n.idana
          AND e.data IS NOT NULL
          AND e.valore IS NOT NULL
          AND e.codiceamd IN ('AMD008','AMD305')
          AND EXTRACT(YEAR FROM e.data)::int = n.anno_pe
       )
     )
     / COUNT(DISTINCT (n.idcentro, n.idana)), 2)
 END AS pct_con_hba1c_stesso_anno
FROM (
 SELECT a.idcentro, a.idana,
        MIN(EXTRACT(YEAR FROM ev.data)::int) AS anno_pe
 FROM daibetes1.anagrafica a
 JOIN (
   SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE data IS
NOT NULL
   UNION ALL
   SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE data IS
NOT NULL
   UNION ALL
   SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci WHERE data
IS NOT NULL

  ) ev
    ON ev.idcentro = a.idcentro AND ev.idana = a.idana
  WHERE a.annonascita IS NOT NULL
    AND (EXTRACT(YEAR FROM ev.data)::int - a.annonascita) BETWEEN 0 AND 110
    AND COALESCE(a.inconsistenza, 0) = 0
  GROUP BY a.idcentro, a.idana
) AS n
JOIN daibetes1.centriamd c
  ON c.idcentro = n.idcentro
WHERE c.regione IS NOT NULL
GROUP BY c.regione
ORDER BY pct_con_hba1c_stesso_anno DESC, c.regione;
