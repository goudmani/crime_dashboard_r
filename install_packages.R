# install_packages.R
# Run this script if renv::restore() fails or if you prefer a direct install.
# Usage: Rscript install_packages.R

pkgs <- c(
  # Core base deps (install first)
  "rlang",
  "cli",
  "glue",
  "lifecycle",
  "vctrs",
  "magrittr",
  "generics",
  # HTML / UI
  "digest",
  "fastmap",
  "cachem",
  "memoise",
  "base64enc",
  "htmltools",
  "jquerylib",
  "jsonlite",
  "mime",
  "sass",
  "bslib",
  "bsicons",
  "fontawesome",
  # Shiny + widgets
  "Rcpp",
  "later",
  "promises",
  "httpuv",
  "commonmark",
  "sourcetools",
  "ellipsis",
  "xtable",
  "shiny",
  "htmlwidgets",
  "lazyeval",
  "crosstalk",
  "DT",
  # Data wrangling
  "fansi",
  "utf8",
  "pillar",
  "pkgconfig",
  "tibble",
  "tidyselect",
  "withr",
  "dplyr",
  "purrr",
  "stringi",
  "stringr",
  # File reading
  "bit",
  "bit64",
  "cpp11",
  "tzdb",
  "clipr",
  "crayon",
  "hms",
  "prettyunits",
  "progress",
  "vroom",
  "readr",
  # Plotting
  "farver",
  "labeling",
  "RColorBrewer",
  "viridisLite",
  "munsell",
  "colorspace",
  "scales",
  "isoband",
  "gtable",
  "ggplot2",
  # Deploy
  "fs",
  "rappdirs",
  "R6",
  "yaml",
  "renv"
)

# Install any that are missing
missing <- pkgs[!pkgs %in% rownames(installed.packages())]

if (length(missing) == 0) {
  message("All packages already installed.")
} else {
  message("Installing ", length(missing), " missing packages: ",
          paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org")
  message("Done. Run shiny::runApp() to launch the dashboard.")
}
