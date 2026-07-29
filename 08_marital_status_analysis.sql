/*
===============================================================================
Marital-status analysis
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
Q38: Marital-status distribution
Original appendix title: Stato civile — distribuzione dei pazienti (n e % sul totale)

Purpose:
- Marital-status distribution.
*/
SELECT
 CASE a.statocivile
  WHEN 1 THEN 'Nubile/Celibe'
  WHEN 2 THEN 'Coniugato/a'

  WHEN 3 THEN 'Vedovo/a'
  WHEN 4 THEN 'Separato/Divorziato'
  WHEN 5 THEN 'Vive solo'
  WHEN 6 THEN 'Care giver'
  ELSE 'Non specificato'
 END AS stato_civile_label,
 COUNT(*) AS n_pazienti
FROM daibetes1.anagrafica a
WHERE a.statocivile IS NOT NULL
GROUP BY stato_civile_label
ORDER BY n_pazienti DESC;

/*
Q39: Marital-status distribution by region
Original appendix title: Distribuzione per stato civile per regione (n e % entro-regione)

Purpose:
- Marital-status distribution by region.
*/
SELECT
 b.regione, b.stato_civile,
 COUNT(*) AS n_pazienti,
 ROUND(
   100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY b.regione), 0)
 , 2) AS pct_entroregione
FROM (
 SELECT DISTINCT
   a.idcentro, a.idana, c.regione,
   CASE a.statocivile
    WHEN 1 THEN 'Nubile/Celibe'
    WHEN 2 THEN 'Coniugato/a'
    WHEN 3 THEN 'Vedovo/a'
    WHEN 4 THEN 'Separato/Divorziato'
    WHEN 5 THEN 'Vive solo'

     WHEN 6 THEN 'Care giver'
     ELSE 'Non specificato'
   END AS stato_civile
 FROM daibetes1.anagrafica a
 JOIN daibetes1.centriamd c ON c.idcentro = a.idcentro
 JOIN (
   SELECT idcentro, idana,
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
 WHERE a.statocivile IS NOT NULL
   AND c.regione IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
   AND COALESCE(a.inconsistenza, 0) = 0
)b
GROUP BY b.regione, b.stato_civile
ORDER BY b.regione, n_pazienti DESC;

-- Methodological note: Q40-Q46 exclude the marital-status category "Care giver".

/*
Q40: Region with the highest within-region share for each marital-status category
Original appendix title: Per ciascuno stato civile: regione con percentuale più alta sul totale regionale (% entro-regione)

Purpose:
- Region with the highest within-region share for each marital-status category.
*/
SELECT stato_civile, regione, perc_su_regione
FROM (
 SELECT
  regione, stato_civile, perc_su_regione,
  ROW_NUMBER() OVER (PARTITION BY stato_civile
              ORDER BY perc_su_regione DESC, regione) AS rn
 FROM (
  SELECT
   c.regione,

      CASE a.statocivile
        WHEN 1 THEN 'Nubile/Celibe'
        WHEN 2 THEN 'Coniugato/a'
        WHEN 3 THEN 'Vedovo/a'
        WHEN 4 THEN 'Separato/Divorziato'
        WHEN 5 THEN 'Vive solo'
        ELSE 'Non specificato'
      END AS stato_civile,
      COUNT(DISTINCT (a.idcentro, a.idana)) AS n_pazienti,
      ROUND(
        100.0 * COUNT(DISTINCT (a.idcentro, a.idana))
        / NULLIF(SUM(COUNT(DISTINCT (a.idcentro, a.idana)))
             OVER (PARTITION BY c.regione), 0)
      , 2) AS perc_su_regione
    FROM daibetes1.anagrafica a
    JOIN daibetes1.centriamd c
      ON a.idcentro = c.idcentro
    JOIN (
      SELECT idcentro, idana, MIN(EXTRACT(YEAR FROM data)::int) AS first_year
      FROM (
        SELECT idcentro, idana, data FROM daibetes1.esamilaboratorioparametri WHERE data
IS NOT NULL
        UNION ALL
        SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetefarmaci WHERE data
IS NOT NULL
        UNION ALL
        SELECT idcentro, idana, data FROM daibetes1.prescrizionidiabetenonfarmaci WHERE
data IS NOT NULL
      ) ev
      GROUP BY idcentro, idana
    ) pe ON pe.idcentro = a.idcentro AND pe.idana = a.idana
    WHERE a.statocivile IS NOT NULL
      AND a.statocivile <> 6
      AND c.regione IS NOT NULL
      AND a.annonascita IS NOT NULL
      AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
      AND COALESCE(a.inconsistenza, 0) = 0
    GROUP BY c.regione, a.statocivile
  ) base
) ranked
WHERE rn = 1
ORDER BY perc_su_regione DESC;

/*
Q41: Marital status by sex
Original appendix title: Stato civile per sesso (n e % entro categoria)

Purpose:
- Marital status by sex.
*/
SELECT
 CASE a.statocivile
   WHEN 1 THEN 'Nubile/Celibe'
   WHEN 2 THEN 'Coniugato/a'
   WHEN 3 THEN 'Vedovo/a'
   WHEN 4 THEN 'Separato/Divorziato'
   WHEN 5 THEN 'Vive solo'
   ELSE 'Non specificato'
 END AS stato_civile,
 COUNT(*) FILTER (WHERE a.sesso = 'M') AS n_maschi,
 COUNT(*) FILTER (WHERE a.sesso = 'F') AS n_femmine,
 ROUND(100.0 * COUNT(*) FILTER (WHERE a.sesso = 'M') / NULLIF(COUNT(*),0), 2) AS
perc_maschi,
 ROUND(100.0 * COUNT(*) FILTER (WHERE a.sesso = 'F') / NULLIF(COUNT(*),0), 2) AS
perc_femmine
FROM (
 SELECT DISTINCT a.idcentro, a.idana, a.sesso, a.statocivile
 FROM daibetes1.anagrafica a
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
   ) ev GROUP BY idcentro, idana

 ) pe ON pe.idcentro = a.idcentro AND pe.idana = a.idana
 WHERE a.statocivile IS NOT NULL
   AND a.statocivile <> 6
   AND a.sesso IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
   AND COALESCE(a.inconsistenza,0) = 0
)a
GROUP BY stato_civile
ORDER BY stato_civile;

/*
Q42: Marital status by region and sex
Original appendix title: Stato civile per regione e sesso (n e % entro stato civile nella regione)

Purpose:
- Marital status by region and sex.
*/
SELECT
 c.regione,
 CASE a.statocivile
  WHEN 1 THEN 'Nubile/Celibe'
  WHEN 2 THEN 'Coniugato/a'
  WHEN 3 THEN 'Vedovo/a'
  WHEN 4 THEN 'Separato/Divorziato'
  WHEN 5 THEN 'Vive solo'
  ELSE 'Non specificato'
 END AS stato_civile,
 COUNT(*) FILTER (WHERE a.sesso = 'M') AS n_maschi,
 COUNT(*) FILTER (WHERE a.sesso = 'F') AS n_femmine,
 ROUND(100.0 * COUNT(*) FILTER (WHERE a.sesso = 'M') / NULLIF(COUNT(*),0), 2) AS
perc_maschi,
 ROUND(100.0 * COUNT(*) FILTER (WHERE a.sesso = 'F') / NULLIF(COUNT(*),0), 2) AS
perc_femmine
FROM (
 SELECT DISTINCT
  a.idcentro, a.idana, a.sesso, a.statocivile, a.idcentro AS join_idcentro

 FROM daibetes1.anagrafica a
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
   ) ev GROUP BY idcentro, idana
 ) pe USING (idcentro, idana)
 WHERE a.statocivile IS NOT NULL
   AND a.statocivile <> 6
   AND a.sesso IS NOT NULL
   AND a.annonascita IS NOT NULL
   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
   AND COALESCE(a.inconsistenza,0) = 0
)a
JOIN daibetes1.centriamd c ON c.idcentro = a.join_idcentro
WHERE c.regione IS NOT NULL
GROUP BY c.regione, stato_civile
ORDER BY c.regione, stato_civile;

/*
Q43: HbA1c testing intensity by marital status
Original appendix title: Intensità dei test HbA1c per paziente per stato civile (n attivi, media annua, % con media ≥2)

Purpose:
- HbA1c testing intensity by marital status.
*/
SELECT
 CASE a.statocivile
  WHEN 1 THEN 'Nubile/Celibe'
  WHEN 2 THEN 'Coniugato/a'
  WHEN 3 THEN 'Vedovo/a'
  WHEN 4 THEN 'Separato/Divorziato'
  WHEN 5 THEN 'Vive solo'
  ELSE 'Non specificato'
 END AS stato_civile,

 COUNT(*) AS n_pazienti_attivi,

 ROUND(AVG(p.paz_avg_hba1c_per_year)::numeric, 2) AS media_hba1c_pa,

 ROUND(
   100.0 * COUNT(*) FILTER (WHERE p.paz_avg_hba1c_per_year >= 2)
   / NULLIF(COUNT(*),0)
 , 2) AS pct_paz_media_ge_2

FROM (
 SELECT DISTINCT
   a.idcentro, a.idana, a.statocivile
 FROM daibetes1.anagrafica a
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
 ) pe USING (idcentro, idana)
 WHERE a.statocivile IS NOT NULL
   AND a.statocivile <> 6
   AND a.annonascita IS NOT NULL

   AND (pe.first_year - a.annonascita) BETWEEN 18 AND 110
   AND COALESCE(a.inconsistenza,0) = 0
)a
JOIN (
 SELECT
   ay.idcentro,
   ay.idana,
   AVG(COALESCE(hy.n_hba1c, 0)) AS paz_avg_hba1c_per_year
 FROM (
   SELECT idcentro, idana, EXTRACT(YEAR FROM data)::int AS anno
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
   GROUP BY idcentro, idana, EXTRACT(YEAR FROM data)::int
 ) ay
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
 ) hy
   ON hy.idcentro = ay.idcentro AND hy.idana = ay.idana AND hy.anno = ay.anno
 GROUP BY ay.idcentro, ay.idana
)p
 ON p.idcentro = a.idcentro AND p.idana = a.idana

GROUP BY stato_civile
ORDER BY stato_civile;

/*
Q44: Latest normalized HbA1c by marital status
Original appendix title: Ultima HbA1c normalizzata per paziente per stato civile (n, media, mediana)

Purpose:
- Latest normalized HbA1c by marital status.
*/
SELECT
 a.statocivile,
 CASE a.statocivile
  WHEN 1 THEN 'Nubile/Celibe'
  WHEN 2 THEN 'Coniugato/a'
  WHEN 3 THEN 'Vedovo/a'
  WHEN 4 THEN 'Separato/Divorziato'
  WHEN 5 THEN 'Vive solo'
  ELSE 'Non specificato'
 END AS stato_civile_label,
 ROUND(AVG(fh.hba1c_pct)::numeric, 2) AS media_hba1c,
 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fh.hba1c_pct) AS mediana_hba1c,
 COUNT(*) AS n_pazienti
FROM daibetes1.anagrafica a
JOIN (
 SELECT DISTINCT ON (idcentro, idana)
      idcentro, idana,
      data,
      CASE
        WHEN codiceamd = 'AMD305'
         THEN ROUND((regexp_replace(valore, ',', '.', 'g'))::decimal / 10.929 + 2.15, 1)
        ELSE (regexp_replace(valore, ',', '.', 'g'))::decimal
      END AS hba1c_pct
 FROM daibetes1.esamilaboratorioparametri
 WHERE data IS NOT NULL
  AND valore IS NOT NULL

   AND codiceamd IN ('AMD008','AMD305')
   AND regexp_replace(valore, ',', '.', 'g') ~ '^[0-9]+(\.[0-9]+)?$'
  ORDER BY idcentro, idana, data DESC,
       CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
) fh
  ON fh.idcentro = a.idcentro AND fh.idana = a.idana
WHERE a.statocivile IS NOT NULL
  AND a.statocivile <> 6
  AND fh.hba1c_pct BETWEEN 4 AND 15
GROUP BY a.statocivile, stato_civile_label
ORDER BY stato_civile_label;

/*
Q45: Latest normalized HbA1c by marital status and region
Original appendix title: Ultima HbA1c normalizzata per paziente: media per stato civile e regione

Purpose:
- Latest normalized HbA1c by marital status and region.
*/
SELECT
 c.regione,

 ROUND(AVG(fh.hba1c_pct) FILTER (WHERE a.statocivile = 1), 2) AS nubile_media,
 ROUND(AVG(fh.hba1c_pct) FILTER (WHERE a.statocivile = 2), 2) AS coniugato_media,
 ROUND(AVG(fh.hba1c_pct) FILTER (WHERE a.statocivile = 3), 2) AS vedovo_media,
 ROUND(AVG(fh.hba1c_pct) FILTER (WHERE a.statocivile = 4), 2) AS separato_media,
 ROUND(AVG(fh.hba1c_pct) FILTER (WHERE a.statocivile = 5), 2) AS vivesolo_media

FROM daibetes1.anagrafica a
JOIN daibetes1.centriamd c
 ON c.idcentro = a.idcentro
JOIN (
 SELECT DISTINCT ON (idcentro, idana)
     idcentro, idana,
     data,
     CASE
       WHEN codiceamd = 'AMD305'

         THEN ROUND((regexp_replace(valore, ',', '.', 'g'))::decimal / 10.929 + 2.15, 1)
       ELSE (regexp_replace(valore, ',', '.', 'g'))::decimal
      END AS hba1c_pct
  FROM daibetes1.esamilaboratorioparametri
  WHERE data IS NOT NULL
   AND valore IS NOT NULL
   AND codiceamd IN ('AMD008','AMD305')
   AND regexp_replace(valore, ',', '.', 'g') ~ '^[0-9]+(\.[0-9]+)?$'
  ORDER BY idcentro, idana, data DESC,
       CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
) fh
  ON fh.idcentro = a.idcentro AND fh.idana = a.idana
WHERE a.statocivile IS NOT NULL
  AND a.statocivile <> 6
  AND c.regione IS NOT NULL
  AND fh.hba1c_pct BETWEEN 4 AND 15
GROUP BY c.regione
ORDER BY c.regione;

/*
Q46: Latest HbA1c and out-of-target rate by marital status
Original appendix title: Ultima HbA1c per paziente per stato civile (n, media e % fuori target ≥8%)

Purpose:
- Latest HbA1c and out-of-target rate by marital status.
*/
SELECT
 a.statocivile,
 CASE a.statocivile
  WHEN 1 THEN 'Nubile/Celibe'
  WHEN 2 THEN 'Coniugato/a'
  WHEN 3 THEN 'Vedovo/a'
  WHEN 4 THEN 'Separato/Divorziato'
  WHEN 5 THEN 'Vive solo'
  ELSE 'Non specificato'
 END AS stato_civile_label,
 COUNT(*) AS n_pazienti,

 ROUND(
   100.0 * COUNT(*) FILTER (WHERE fh.hba1c_pct >= 8)
   / NULLIF(COUNT(*),0), 2
 ) AS pct_fuori_target,

 ROUND(AVG(fh.hba1c_pct)::numeric, 2) AS media_hba1c

FROM daibetes1.anagrafica a
JOIN (
  SELECT DISTINCT ON (idcentro, idana)
      idcentro, idana,
      data,
      CASE
        WHEN codiceamd = 'AMD305'
         THEN ROUND((regexp_replace(valore, ',', '.', 'g'))::decimal / 10.929 + 2.15, 1)
        ELSE (regexp_replace(valore, ',', '.', 'g'))::decimal
      END AS hba1c_pct
  FROM daibetes1.esamilaboratorioparametri
  WHERE data IS NOT NULL
   AND valore IS NOT NULL
   AND codiceamd IN ('AMD008','AMD305')
   AND regexp_replace(valore, ',', '.', 'g') ~ '^[0-9]+(\.[0-9]+)?$'
  ORDER BY idcentro, idana, data DESC,
        CASE WHEN codiceamd = 'AMD008' THEN 0 ELSE 1 END
) fh
  ON fh.idcentro = a.idcentro AND fh.idana = a.idana
WHERE a.statocivile IS NOT NULL
  AND a.statocivile <> 6
  AND fh.hba1c_pct BETWEEN 4 AND 15

GROUP BY a.statocivile, stato_civile_label
ORDER BY stato_civile_label;
