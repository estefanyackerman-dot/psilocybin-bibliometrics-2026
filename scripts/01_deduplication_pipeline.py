#!/usr/bin/env python3
"""Deduplicate WoS, Scopus and PubMed exports using WoS > Scopus > PubMed.

The input paths can be supplied explicitly, which is useful for licensed exports
kept outside the repository:

    python scripts/01_deduplication_pipeline.py \
      --wos "Downloads/savedrecs (1).ris" "Downloads/savedrecs (2).ris" \
      --scopus Downloads/scopus.csv --pubmed Downloads/pubmed.csv

Defaults expect one or more WoS RIS files in raw/, raw/scopus.csv and
raw/pubmed.csv. The output is data/corpus_unique_tridatabase.csv and the
PRISMA flow table in results/tables/T0_prisma_s_flow.csv.
"""
import argparse
import re
import unicodedata
from pathlib import Path

import pandas as pd


RETRACTED = {"10.1177/02698811241234247", "10.3389/fnins.2023.1168911"}


def norm_doi(value):
    if pd.isna(value) or not str(value).strip():
        return None
    value = re.sub(r"^https?://(dx\.)?doi\.org/", "", str(value).strip().lower())
    return value.rstrip(" .;") or None


def norm_title(value):
    if pd.isna(value) or not str(value).strip():
        return None
    value = unicodedata.normalize("NFKD", str(value))
    value = value.encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]", "", value) or None


def read_ris(path):
    """Read a RIS/EndNote export, retaining the fields needed downstream."""
    records, current, last_tag = [], {}, None
    with Path(path).open(encoding="utf-8-sig", errors="replace") as handle:
        for raw_line in handle:
            line = raw_line.rstrip("\r\n")
            match = re.match(r"^([A-Z0-9]{2})  - ?(.*)$", line)
            if match:
                tag, value = match.groups()
                last_tag = tag
                if tag == "TY":
                    if current:
                        records.append(current)
                    current = {}
                if tag in {"AU", "A1"}:
                    current.setdefault("AU", []).append(value.strip())
                else:
                    current[tag] = value.strip()
            elif line.startswith("      ") and last_tag and current:
                current[last_tag] = f"{current.get(last_tag, '')} {line.strip()}".strip()
            elif line == "ER  -":
                if current:
                    records.append(current)
                    current = {}
                last_tag = None
    if current:
        records.append(current)
    return pd.DataFrame(records)


def read_wos(paths):
    frames = [read_ris(path) for path in paths]
    if not frames:
        raise ValueError("At least one WoS RIS file is required.")
    wos = pd.concat(frames, ignore_index=True).fillna("")
    for column in ("TI", "PY", "DO", "M3", "T2", "AN"):
        if column not in wos:
            wos[column] = ""
    return wos.rename(
        columns={"TI": "title", "PY": "year", "DO": "doi", "M3": "document_type"}
    )


def require_columns(frame, required, source):
    missing = [column for column in required if column not in frame.columns]
    if missing:
        raise ValueError(f"{source} export is missing columns: {', '.join(missing)}")


def read_scopus(path):
    scopus = pd.read_csv(path, dtype=str, keep_default_na=False)
    require_columns(scopus, ["Title", "Year", "DOI", "Document Type"], "Scopus")
    return scopus.rename(
        columns={
            "Title": "title",
            "Year": "year",
            "DOI": "doi",
            "Document Type": "document_type",
        }
    )


def read_pubmed(path):
    pubmed = pd.read_csv(path, dtype=str, keep_default_na=False)
    require_columns(pubmed, ["Title", "Publication Year", "DOI"], "PubMed")
    return pubmed.rename(
        columns={"Title": "title", "Publication Year": "year", "DOI": "doi"}
    )


def add_keys(frame):
    frame = frame.copy()
    frame["doi"] = frame["doi"].map(norm_doi)
    frame["title"] = frame["title"].fillna("").astype(str)
    frame["_title_key"] = frame["title"].map(norm_title)
    return frame


def duplicate_mask(frame, seen_dois, seen_titles):
    return frame["doi"].isin(seen_dois) | frame["_title_key"].isin(seen_titles)


def unique_within_source(frame):
    """Keep the first record, matching DOI first and then title."""
    has_doi = frame["doi"].notna()
    frame = frame.loc[~(has_doi & frame["doi"].duplicated(keep="first"))].copy()
    has_title = frame["_title_key"].notna()
    return frame.loc[~(has_title & frame["_title_key"].duplicated(keep="first"))].copy()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--wos", nargs="+", default=None, type=Path)
    parser.add_argument("--scopus", type=Path, default=Path("raw/scopus.csv"))
    parser.add_argument("--pubmed", type=Path, default=Path("raw/pubmed.csv"))
    parser.add_argument("--output", type=Path, default=Path("data/corpus_unique_tridatabase.csv"))
    parser.add_argument("--flow-output", type=Path, default=Path("results/tables/T0_prisma_s_flow.csv"))
    args = parser.parse_args()

    wos_paths = args.wos or sorted(Path("raw").glob("*.ris"))
    if not wos_paths:
        raise FileNotFoundError("No WoS RIS files found. Use --wos PATH [PATH ...].")

    wos = unique_within_source(add_keys(read_wos(wos_paths)))
    wos_retracted = wos["doi"].isin(RETRACTED)
    wos = wos.loc[~wos_retracted].copy()

    scopus = add_keys(read_scopus(args.scopus))
    wos_dois = set(wos["doi"].dropna())
    wos_titles = set(wos["_title_key"].dropna())
    scopus_dup = duplicate_mask(scopus, wos_dois, wos_titles)
    scopus_unique = unique_within_source(scopus.loc[~scopus_dup])

    pubmed = add_keys(read_pubmed(args.pubmed))
    seen_dois = wos_dois | set(scopus_unique["doi"].dropna())
    seen_titles = wos_titles | set(scopus_unique["_title_key"].dropna())
    pubmed_dup = duplicate_mask(pubmed, seen_dois, seen_titles)
    pubmed_unique = unique_within_source(pubmed.loc[~pubmed_dup])

    corpus = pd.concat(
        [
            wos.assign(source="WOS"),
            scopus_unique.assign(source="SCOPUS"),
            pubmed_unique.assign(source="PUBMED"),
        ],
        ignore_index=True,
    )[["source", "title", "year", "doi", "document_type"]]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.flow_output.parent.mkdir(parents=True, exist_ok=True)
    corpus.to_csv(args.output, index=False)

    flow = pd.DataFrame(
        [
            ("WoS raw", len(read_wos(wos_paths))),
            ("WoS retracted removed", int(wos_retracted.sum())),
            ("WoS unique", len(wos)),
            ("Scopus raw", len(scopus)),
            ("Scopus duplicates vs WoS", int(scopus_dup.sum())),
            ("Scopus unique contribution", len(scopus_unique)),
            ("PubMed raw", len(pubmed)),
            ("PubMed duplicates vs WoS+Scopus", int(pubmed_dup.sum())),
            ("PubMed unique contribution", len(pubmed_unique)),
            ("Total raw", len(read_wos(wos_paths)) + len(scopus) + len(pubmed)),
            ("Final unique corpus", len(corpus)),
        ],
        columns=["Stage", "n"],
    )
    flow.to_csv(args.flow_output, index=False)
    print(
        f"WoS {len(wos)} | Scopus unique {len(scopus_unique)} | "
        f"PubMed unique {len(pubmed_unique)} | Total {len(corpus)}"
    )


if __name__ == "__main__":
    main()
