# Bibliometric analysis body for the psilocybin corpus
# Reads the raw exports already in raw/ and generates descriptive tables without
# depending on the fragile bibliometrix RIS conversion path.

RETRACTED <- tolower(c(
  "10.1177/02698811241234247",
  "10.3389/fnins.2023.1168911"
))

normalize_doi <- function(x) {
  x <- trimws(as.character(x))
  x <- tolower(x)
  x <- sub("^https?://(dx\\.)?doi\\.org/", "", x)
  x <- gsub("[[:space:]]+", "", x)
  x <- gsub("[;,.]+$", "", x)
  if (identical(x, "NA") || !nzchar(x)) return(NA_character_)
  x
}

normalize_title <- function(x) {
  x <- trimws(as.character(x))
  if (!nzchar(x)) return(NA_character_)
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  x <- tolower(x)
  x <- gsub("[^a-z0-9]", "", x)
  if (!nzchar(x)) return(NA_character_)
  x
}

read_ris_records <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- iconv(lines, from = "UTF-8", to = "UTF-8", sub = "")
  lines <- gsub("^\ufeff", "", lines)

  records <- split(lines, cumsum(grepl("^ER\\s+-\\s*$", lines)))
  rows <- lapply(records, function(block) {
    block <- block[!is.na(block) & nzchar(block)]
    if (length(block) == 0L) return(list())

    current_tag <- NULL
    out <- list()
    for (line in block) {
      if (grepl("^ER\\s+-\\s*$", line)) next
      if (grepl("^\\s{2,}", line)) {
        if (!is.null(current_tag) && nzchar(trimws(line))) {
          value <- trimws(line)
          out[[current_tag]] <- paste(c(out[[current_tag]], value), collapse = " ")
        }
        next
      }
      if (grepl("^[A-Z0-9]{2,}\\s+-", line)) {
        tag <- trimws(substr(line, 1, 3))
        value <- trimws(substring(line, 4))
        current_tag <- tag
        if (!is.null(out[[tag]])) {
          out[[tag]] <- paste(c(out[[tag]], value), collapse = "; ")
        } else {
          out[[tag]] <- value
        }
      }
    }
    out
  })

  rows <- Filter(function(x) length(x) > 0L, rows)
  if (length(rows) == 0L) return(data.frame())

  fields <- sort(unique(unlist(lapply(rows, names), use.names = FALSE)))
  columns <- lapply(fields, function(field) {
    vapply(rows, function(rec) {
      value <- rec[[field]]
      if (is.null(value)) "" else as.character(value)
    }, character(1))
  })
  names(columns) <- fields

  data.frame(columns, stringsAsFactors = FALSE)
}

read_wos <- function(paths) {
  frames <- lapply(paths, read_ris_records)
  frames <- Filter(function(df) nrow(df) > 0, frames)
  if (length(frames) == 0L) {
    stop("No WoS records were parsed from the supplied RIS files.")
  }

  all_fields <- sort(unique(unlist(lapply(frames, names), use.names = FALSE)))
  frames <- lapply(frames, function(df) {
    for (field in setdiff(all_fields, names(df))) {
      df[[field]] <- ""
    }
    df[, all_fields, drop = FALSE]
  })

  wos <- do.call(rbind, frames)
  wos$source <- "WOS"

  if ("TI" %in% names(wos)) {
    wos$title <- wos$TI
  } else {
    wos$title <- ""
  }

  if ("PY" %in% names(wos)) {
    wos$year <- wos$PY
  } else {
    wos$year <- ""
  }

  if ("DO" %in% names(wos)) {
    wos$doi <- wos$DO
  } else if ("DI" %in% names(wos)) {
    wos$doi <- wos$DI
  } else {
    wos$doi <- ""
  }

  if ("M3" %in% names(wos)) {
    wos$document_type <- wos$M3
  } else {
    wos$document_type <- ""
  }

  if ("SO" %in% names(wos)) {
    wos$journal <- wos$SO
  } else {
    wos$journal <- ""
  }

  data.frame(
    source = wos$source,
    title = wos$title,
    year = wos$year,
    doi = wos$doi,
    document_type = wos$document_type,
    journal = wos$journal,
    stringsAsFactors = FALSE
  )
}

read_scopus <- function(path) {
  if (!file.exists(path)) return(data.frame())
  scopus <- read.csv(path, header = TRUE, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  keep <- intersect(c("Title", "Year", "DOI", "Document.Type", "Document Type", "Source.title", "Source title"), names(scopus))
  if (length(keep) == 0L) return(data.frame())

  selected <- scopus[, keep, drop = FALSE]
  if ("Document.Type" %in% names(selected)) {
    selected$document_type <- selected$"Document.Type"
  } else if ("Document Type" %in% names(selected)) {
    selected$document_type <- selected$"Document Type"
  } else {
    selected$document_type <- ""
  }

  if ("Source.title" %in% names(selected)) {
    selected$journal <- selected$"Source.title"
  } else if ("Source title" %in% names(selected)) {
    selected$journal <- selected$"Source title"
  } else {
    selected$journal <- ""
  }

  if ("DOI" %in% names(selected)) {
    selected$doi <- selected$DOI
  } else {
    selected$doi <- ""
  }

  if ("Year" %in% names(selected)) {
    selected$year <- selected$Year
  } else {
    selected$year <- ""
  }

  if ("Title" %in% names(selected)) {
    selected$title <- selected$Title
  } else {
    selected$title <- ""
  }

  data.frame(
    source = "SCOPUS",
    title = selected$title,
    year = selected$year,
    doi = selected$doi,
    document_type = selected$document_type,
    journal = selected$journal,
    stringsAsFactors = FALSE
  )
}

read_pubmed <- function(path) {
  if (!file.exists(path)) return(data.frame())
  pubmed <- read.csv(path, header = TRUE, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  if (!all(c("Title", "Publication.Year", "DOI") %in% names(pubmed))) {
    return(data.frame())
  }

  data.frame(
    source = "PUBMED",
    title = pubmed$Title,
    year = pubmed$Publication.Year,
    doi = pubmed$DOI,
    document_type = if ("Journal.Book" %in% names(pubmed)) pubmed$"Journal.Book" else "",
    journal = if ("Journal.Book" %in% names(pubmed)) pubmed$"Journal.Book" else "",
    stringsAsFactors = FALSE
  )
}

deduplicate_sources <- function(df_list) {
  seen_dois <- character(0)
  seen_titles <- character(0)
  out <- list()

  for (source_name in c("WOS", "SCOPUS", "PUBMED")) {
    frame <- df_list[[source_name]]
    if (is.null(frame) || nrow(frame) == 0L) next

    keep <- rep(TRUE, nrow(frame))
    for (i in seq_len(nrow(frame))) {
      doi_key <- normalize_doi(frame$doi[i])
      title_key <- normalize_title(frame$title[i])

      doi_dup <- !is.na(doi_key) && doi_key %in% seen_dois
      title_dup <- !is.na(title_key) && title_key %in% seen_titles
      if (doi_dup || title_dup) {
        keep[i] <- FALSE
      } else {
        if (!is.na(doi_key)) seen_dois <- c(seen_dois, doi_key)
        if (!is.na(title_key)) seen_titles <- c(seen_titles, title_key)
      }
    }

    out[[source_name]] <- frame[keep, , drop = FALSE]
  }

  do.call(rbind, out)
}

write_results <- function(corpus, results_root) {
  dir.create(results_root, recursive = TRUE, showWarnings = FALSE)

  annual <- as.data.frame(table(corpus$year), stringsAsFactors = FALSE)
  names(annual) <- c("year", "n")
  annual$year <- as.character(annual$year)
  annual <- annual[order(annual$year), , drop = FALSE]
  write.csv(annual, file.path(results_root, "R_annual_production.csv"), row.names = FALSE)

  source_counts <- as.data.frame(table(corpus$source), stringsAsFactors = FALSE)
  names(source_counts) <- c("source", "n")
  source_counts <- source_counts[order(source_counts$n, decreasing = TRUE), , drop = FALSE]
  write.csv(source_counts, file.path(results_root, "R_source_breakdown.csv"), row.names = FALSE)

  doc_types <- as.data.frame(table(corpus$document_type), stringsAsFactors = FALSE)
  names(doc_types) <- c("document_type", "n")
  doc_types <- doc_types[order(doc_types$n, decreasing = TRUE), , drop = FALSE]
  write.csv(doc_types, file.path(results_root, "R_document_types.csv"), row.names = FALSE)

  top_journals <- as.data.frame(table(corpus$journal), stringsAsFactors = FALSE)
  names(top_journals) <- c("journal", "n")
  top_journals <- top_journals[order(top_journals$n, decreasing = TRUE), , drop = FALSE]
  top_journals <- head(top_journals, 20)
  write.csv(top_journals, file.path(results_root, "R_top_journals.csv"), row.names = FALSE)

  list(
    annual = annual,
    sources = source_counts,
    document_types = doc_types,
    top_journals = top_journals
  )
}

args <- commandArgs(trailingOnly = TRUE)
repo_root <- "."
raw_dir <- file.path(repo_root, "raw")

if (length(args) > 0) {
  wos_paths <- normalizePath(args, winslash = "/", mustWork = FALSE)
} else {
  wos_paths <- list.files(raw_dir,
    pattern = "\\.(ris|enw)$",
    full.names = TRUE,
    ignore.case = TRUE
  )
}

if (length(wos_paths) == 0) {
  stop("No WoS RIS files found in raw/. Pass one or more RIS files as arguments.")
}

wos_raw <- read_wos(wos_paths)
scopus_raw <- read_scopus(file.path(raw_dir, "scopus.csv"))
pubmed_raw <- read_pubmed(file.path(raw_dir, "pubmed.csv"))

corpus <- deduplicate_sources(list(
  WOS = wos_raw,
  SCOPUS = scopus_raw,
  PUBMED = pubmed_raw
))

corpus <- subset(corpus, !is.na(corpus$doi) & corpus$doi != "")
corpus$doi <- sapply(corpus$doi, normalize_doi)
corpus$title <- sapply(corpus$title, function(x) {
  if (length(x) == 0L || is.na(x) || !nzchar(trimws(as.character(x)))) return(NA_character_)
  trimws(as.character(x))
})
corpus$year <- suppressWarnings(as.integer(corpus$year))
corpus$document_type <- trimws(corpus$document_type)
corpus$journal <- trimws(corpus$journal)
corpus <- subset(corpus, !is.na(corpus$doi) & corpus$doi != "")
corpus <- subset(corpus, !(tolower(corpus$doi) %in% RETRACTED))

results_dir <- file.path(repo_root, "results", "tables")
res <- write_results(corpus, results_dir)

cat("WoS records:", nrow(wos_raw), "\n")
cat("Scopus records:", nrow(scopus_raw), "\n")
cat("PubMed records:", nrow(pubmed_raw), "\n")
cat("Unique analytical corpus:", nrow(corpus), "\n")
cat("Annual production rows:", nrow(res$annual), "\n")
cat("Top document types:\n")
print(head(res$document_types, 10))