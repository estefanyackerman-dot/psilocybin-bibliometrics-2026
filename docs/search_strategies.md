# Search strategies (PRISMA-S documentation)

All searches executed on 27 August 2026. No language limit; no full-text availability limit.

## Bibliometric arm (broad strategies; reviews eligible)

**Web of Science Core Collection** (advanced search)
```
((((TS=(psilocybin therapy )) OR TS=(psilocybin assisted therapy)) OR (TI=(psilocybin) OR TI=(psilocybe) OR TI=("psilocibin") OR AB=(psilocybin) OR AB=(psilocybe) OR AB=("psilocibin"))) AND (((TS=("depression and anxiety")) OR TS=(dysthymia)) OR (TI=("depression") OR TI=("depressive") OR TI=("anxiety") OR AB=("depression") OR AB=("depressive") OR AB=("anxiety"))

```
Refined: PY=2022-2026; document types Article, Review, Early Access. Retrieved: 1,433. Export: Plain Text, full record with cited references.

**Scopus**
```
TITLE-ABS-KEY(psilocybin* AND (depress* OR anxiet* OR anxious)) AND PUBYEAR > 2021 AND PUBYEAR < 2027
```
Retrieved: 1,163. Export: CSV, full record.

**PubMed** (bibliometric string)
```
("Psilocybine"[MeSH] OR psilocyb*[tiab]) AND ("Depression"[MeSH] OR "Depressive Disorder"[MeSH]
OR "Anxiety"[MeSH] OR "Anxiety Disorders"[MeSH] OR depress*[tiab] OR anxiet*[tiab]) AND 2022:2026[dp]
```
Retrieved: 918. Export: CSV summary / MEDLINE.

## Meta-analytic arm (restrictive strategies; execution pending PROSPERO confirmation)

**PubMed**
```
("Psilocybine"[MeSH] OR psilocyb*[tiab]) AND ("Depression"[MeSH] OR "Depressive Disorder"[MeSH]
OR "Anxiety"[MeSH] OR "Anxiety Disorders"[MeSH] OR depress*[tiab] OR anxiet*[tiab])
AND (randomized controlled trial[pt] OR "clinical trial, phase ii"[pt] OR "clinical trial, phase iii"[pt]
OR "clinical trial, phase iv"[pt] OR randomi*[tiab])
NOT (systematic review[pt] OR meta-analysis[pt]) AND humans[mh] AND 2022:2026[dp]
```

**Cochrane CENTRAL** (Trials tab)
```
#1 (psilocybin*):ti,ab,kw
#2 (depress* OR anxiet* OR anxious):ti,ab,kw
#3 #1 AND #2, publication date 2022-2026
```

**Europe PMC** (complementary preprint source, includes medRxiv)
```
(psilocybin*) AND (depress* OR anxiet* OR anxious) AND (SRC:PPR) AND (FIRST_PDATE:[2022-01-01 TO 2026-12-31])
```

## Deduplication

Priority WoS > Scopus > PubMed; match by normalized DOI, then normalized title. Two retracted WoS articles excluded (10.1177/02698811241234247; 10.3389/fnins.2023.1168911). Flow numbers in `results/tables/T0_prisma_s_flow.csv`.
