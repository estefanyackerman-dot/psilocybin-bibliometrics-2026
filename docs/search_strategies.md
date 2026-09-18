# Search strategies (PRISMA-S documentation)

All searches executed on 5 September 2026. No language limit; no full-text availability limit.

## Bibliometric arm (broad strategies; reviews eligible)

**Web of Science Core Collection** (advanced search)
```
(( TS=(psilocyb*) OR TS=("psilocybin therapy") OR TS=("psilocybin-assisted therapy") OR TS=("psilocybin assisted therapy") OR TI=(psilocybin OR psilocybe OR psilocibin) OR AB=(psilocybin OR psilocybe OR psilocibin) ) AND ( TS=(depress*) OR TS=(anxiety) OR TS=(dysthymia) OR TS=("depression and anxiety") OR TI=(depression OR depressive OR anxiety OR anxious) OR AB=(depression OR depressive OR anxiety OR anxious))) and 2022 or 2023 or 2024 or 2025 or 2026 (Publication Years) and Web of Science Core Collection (Database)
```
Refined: PY=2022-2026; Retrieved: 1,828.  y Web of Science Core Collection (Database)
LINK https://www.webofscience.com/wos/alldb/summary/4fb38d7a-7c35-4ec2-8903-4ad15ee16153-01c504d6de/relevance/1

**Scopus**
```
TITLE-ABS-KEY ( ( psilocybin OR psilocibin OR psilocybe OR "psilocybin therapy" OR "psilocybin-assisted therapy" OR "psilocybin assisted therapy" ) AND ( depress* OR dysthymi* OR anxi* OR "depressive disorder" OR "major depressive disorder" OR "treatment-resistant depression" ) ) AND ( LIMIT-TO ( DOCTYPE , "ar" ) OR LIMIT-TO ( DOCTYPE , "re" ) ) AND PUBYEAR > 2021 AND PUBYEAR < 2027
```
Retrieved: 1,045. Export: CSV, full record.

**PubMed** (bibliometric string)
```
Search: "psilocyb*"[Title/Abstract] OR (("psilocybin"[MeSH Terms] OR "psilocybe"[MeSH Terms])) AND ("depress*"[Title/Abstract] OR "anxiety*"[Title/Abstract] OR "depression"[MeSH Terms] OR "Depressive Disorder"[MeSH] OR "anxiety"[MeSH Terms] OR "Anxiety Disorders"[MeSH]) Filters: MEDLINE, from 2022 - 2027
```
Retrieved: 654. Export: CSV summary / MEDLINE.

## Deduplication

Priority WoS > Scopus > PubMed; match by normalized DOI, then normalized title. Two retracted WoS articles excluded (10.1177/02698811241234247; 10.3389/fnins.2023.1168911). Flow numbers in `results/tables/T0_prisma_s_flow.csv`.
