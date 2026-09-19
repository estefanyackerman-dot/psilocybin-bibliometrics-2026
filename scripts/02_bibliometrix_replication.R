# Replication of the bibliometric arm in R/bibliometrix
# Psilocybin and depression/anxiety, 2022-2026 (WoS analytical corpus)
# Requires: one or more WoS RIS/EndNote exports in raw/ (or pass paths as
# command-line arguments). The two supplied savedrecs RIS files can be passed
# together; they are combined before analysis.

library(bibliometrix)
library(dplyr)

RETRACTED <- tolower(c("10.1177/02698811241234247", "10.3389/FNINS.2023.1168911"))

args <- commandArgs(trailingOnly = TRUE)
wos_files <- if (length(args) > 0) args else list.files("raw", pattern = "\\.(ris|enw)$",
                                                          full.names = TRUE,
                                                          ignore.case = TRUE)
if (length(wos_files) == 0) stop("No WoS RIS files found. Pass their paths as arguments.")
M <- dplyr::bind_rows(lapply(wos_files, function(path) {
  convert2df(path, dbsource = "wos", format = "endnote")
}))
M <- M %>%
  dplyr::mutate(.doi = tolower(trimws(DI)),
                .title = tolower(gsub("[^[:alnum:]]", "", TI))) %>%
  dplyr::filter(!(.doi %in% RETRACTED)) %>%
  dplyr::filter(!duplicated(.doi) | .doi == "") %>%
  dplyr::filter(!duplicated(.title) | .title == "") %>%
  dplyr::select(-.doi, -.title)

res <- biblioAnalysis(M)
S <- summary(res, k = 20, pause = FALSE)

# Annual production and growth
prod <- as.data.frame(table(M$PY))
write.csv(prod, "results/tables/R_annual_production.csv", row.names = FALSE)

# Keyword co-occurrence network (author keywords, cleaned)
remove_terms <- c("PSILOCYBIN", "PSYCHEDELICS", "PSYCHEDELIC", "DEPRESSION", "ANXIETY")
NetMatrix <- biblioNetwork(M, analysis = "co-occurrences", network = "author_keywords", sep = ";")
net <- networkPlot(NetMatrix, normalize = "association", n = 50,
                   Title = "Author keyword co-occurrence", type = "fruchterman",
                   remove.isolates = TRUE, labelsize = 0.7, edges.min = 3)

# Thematic map
Map <- thematicMap(M, field = "DE", n = 250, minfreq = 5, stemming = FALSE,
                   size = 0.5, n.labels = 3, repel = TRUE)
plot(Map$map)

# Country collaboration
M <- metaTagExtraction(M, Field = "AU_CO", sep = ";")
NetCo <- biblioNetwork(M, analysis = "collaboration", network = "countries", sep = ";")
networkPlot(NetCo, n = 25, Title = "Country collaboration", type = "circle", labelsize = 0.8)

# Export for VOSviewer (co-citation uses the CR field retained in the RIS export)
# In VOSviewer: Create > map based on bibliographic data > read the WoS RIS file.
