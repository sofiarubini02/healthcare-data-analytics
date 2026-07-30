# Project Summary

## Background

This project was developed as my Bachelor's Thesis at Sapienza University of Rome using the AMD-STITCH healthcare database.

The objective was to investigate healthcare quality through the analysis of real-world clinical data rather than curated public datasets. Unlike many academic projects based on simplified datasets, this work involved the analysis of anonymized healthcare records collected during routine clinical practice, requiring both technical and critical interpretation skills.

Type 2 Diabetes was selected as the case study because it represents one of the most widespread chronic diseases in Italy and requires continuous monitoring to reduce the risk of long-term complications. Among the available clinical indicators, glycated hemoglobin (HbA1c) was chosen as the primary outcome because it reflects average blood glucose levels over the previous three months and is one of the most important indicators used to evaluate diabetes management.

---

## The AMD-STITCH Database

The analyses were performed using the AMD-STITCH database, developed through the collaboration between the STITCH Research Center of Sapienza University of Rome and the Associazione Medici Diabetologi (AMD).

AMD-STITCH integrates and standardizes clinical information collected from more than 250 Italian diabetes centers, creating one of the largest repositories of Type 2 Diabetes data in Italy.

The database contains approximately 600,000 anonymized patients followed between 2005 and 2018 and includes demographic information, laboratory results, clinical characteristics, therapies, and diabetes-related complications.

Its primary objective is to transform routine clinical records into a structured database suitable for epidemiological studies and healthcare research.

---

## Project Objectives

The main objective of this project was to evaluate healthcare quality by analyzing HbA1c monitoring throughout the patient care pathway.

The analyses focused on:

- HbA1c monitoring coverage
- Frequency of HbA1c testing
- Glycemic control
- Disease progression
- Age-related differences
- Gender differences
- Regional variability
- Marital status
- Healthcare quality indicators

All analyses were performed using SQL on PostgreSQL.

---

## Working with Real-World Clinical Data

One of the most important aspects of this project was dealing with real-world healthcare data.

Unlike datasets specifically created for research, clinical databases often contain incomplete records, heterogeneous information, inconsistencies, and differences in data collection among healthcare centers.

Several challenges had to be considered during the interpretation of the results.

First, participation of diabetes centers was not uniform across Italy. Some centers contributed data for many years, while others joined the network only recently. Consequently, regional analyses should not automatically be interpreted as evidence of differences in healthcare quality.

Another limitation concerns patient identification. Since patients do not have a permanent identifier across different diabetes centers, individuals changing center are recorded as new patients. This makes it impossible to reconstruct a complete clinical history across multiple centers.

Finally, missing values may originate from different causes, including missed examinations, incomplete data entry, or differences in clinical reporting practices. These aspects required careful interpretation throughout the analysis.

---

## Ethical Considerations

Working with healthcare data requires balancing scientific value and patient privacy.

Before becoming available for research, the AMD-STITCH database underwent extensive data cleaning, standardization, and anonymization procedures. Personal identifiers and highly sensitive information were removed to protect patient confidentiality.

Although anonymization is essential from an ethical perspective, it also reduces the amount of information available for research. This project therefore emphasizes that privacy protection and scientific usefulness must always remain balanced.

For this reason, all findings presented in this project should be interpreted as observational evidence rather than definitive proof of healthcare inequalities.

---

## Methodology

The analytical workflow consisted of designing and implementing SQL queries to investigate multiple aspects of diabetes management.

The analyses included:

- patient demographics;
- HbA1c monitoring coverage;
- monitoring intensity;
- regional comparisons;
- disease progression;
- age and gender analyses;
- marital status analyses;
- healthcare quality indicators.

The SQL scripts available in this repository generated the tables and figures included throughout the project.

---

## Main Findings

The analyses produced several relevant observations.

HbA1c monitoring increased substantially after patients entered specialized diabetes care, demonstrating improved adherence to clinical guidelines.

Younger patients generally showed poorer glycemic control compared with older age groups.

Important regional differences emerged in both monitoring practices and clinical outcomes, although these results should be interpreted while considering differences in network coverage.

One of the most interesting findings was that a higher frequency of HbA1c testing was not always associated with better glycemic control. This suggests that the quality of patient follow-up may have a greater impact than simply increasing the number of laboratory tests.

Overall, the analyses demonstrate how large-scale healthcare databases can generate valuable insights for healthcare planning and clinical research.

---

## Project Limitations

Several limitations should be considered when interpreting the results.

The dataset is observational rather than experimental and was originally collected for routine clinical practice instead of research.

Regional coverage is not perfectly homogeneous, patient mobility between centers cannot be fully reconstructed, and missing values may reflect different underlying causes.

Consequently, the findings should be interpreted as evidence supporting further investigation rather than definitive conclusions.

---

## Repository Structure

This repository contains:

- SQL scripts used for every analysis;
- visualizations generated from the results;
- project documentation;
- Bachelor's Thesis (Italian).

The original AMD-STITCH database is not included because it contains protected healthcare information and is not publicly available.

---

## Conclusion

This project demonstrates how SQL can be applied to large-scale healthcare databases to extract meaningful clinical insights from real-world data.

Beyond the technical implementation, the project highlights the importance of data quality, ethical considerations, and critical interpretation when working with observational healthcare information.

The experience provided practical exposure to healthcare analytics, relational databases, and data-driven decision making while emphasizing that meaningful conclusions require both technical skills and awareness of the limitations inherent in clinical data.
