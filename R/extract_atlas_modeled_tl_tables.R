#' Extract tag-life adjusted survival estimates from ATLAS "Modeled" reports
#'
#' Parses the single-release pooled ATLAS reports (HTML saved as ".rtf") that were run with
#' tag-life curves, for one species. One folder per release location (RI, PR) is expected:
#' <tl_root>/<spp>/<RI|PR>/.
#'
#' Files read (one of each per release-location folder):
#'   *_Modeled.rtf     reach-level survival and capture estimates ("Modeled Parameter Report")
#'   *_ModeledCum.rtf  cumulative survival from release ("Modeled Cumulative Survival Report")
#'
#' Each report is a wide table: reach labels, then Estimate / s.e. header pairs, then one row of
#' alternating estimates and standard errors for the single release group. Sections are parsed by
#' position relative to their headers, and the structure is checked while parsing, so an
#' unexpected layout (e.g. more than one release group) stops with an error instead of
#' returning misaligned values.
#'
#' @param spp "CHN" or "STH".
#' @param tl_root Folder holding one subfolder per species.
#' @param out_file Where to save the result with saveRDS (NULL to skip saving).
#' @return A named list: <spp>_TL_Modeled_tab and <spp>_TL_ModeledCum_tab, each with columns
#'   rel_loc ("RI"/"PR"), spp_rel_loc (ATLAS release group), param, reach, est, SE, and
#'   se_method ("bootstrap" or "inverse Hessian", from the report's footnote symbols).
#'   param is "surv_p" (reach survival), "capture_p" (capture detail; the last reach is the
#'   combined Hanford Survival*Capture) or "cum_surv_p" (cumulative survival).
extract_atlas_modeled_tl_tables <- function(spp = c("CHN", "STH"),
                                            tl_root = "analysis/pooled/Single Release Pooled TL",
                                            out_file = file.path("analysis", paste0(spp, "_ATLAS_TLSR_out.rds"))) {
  spp <- match.arg(spp)
  stopifnot(requireNamespace("xml2", quietly = TRUE))

  dagger <- "\u2020"  # marks bootstrap standard errors in the reports

  find_file <- function(dir, suffix) {
    fl <- list.files(dir, pattern = paste0(suffix, "\\.rtf$"))
    if (length(fl) != 1) stop("Expected exactly one '*", suffix, ".rtf' file in ", dir, " but found ", length(fl))
    file.path(dir, fl)
  }
  read_txt <- function(f) trimws(xml2::xml_text(xml2::xml_find_all(xml2::read_html(f), "//p")))

  # Parse one section: header, k reach labels, k x (Estimate, s.e.), group label, k x (est, SE)
  parse_section <- function(txt, header_pattern, param) {
    start <- grep(header_pattern, txt)
    stopifnot(length(start) == 1)
    first_est <- start + which(txt[(start + 1):length(txt)] == "Estimate")[1]
    labels <- txt[(start + 1):(first_est - 1)]
    k <- length(labels)

    hdr <- txt[first_est:(first_est + 2 * k - 1)]
    stopifnot(all(hdr[c(TRUE, FALSE)] == "Estimate"), all(grepl("^s\\.e\\.", hdr[c(FALSE, TRUE)])))

    grp <- txt[first_est + 2 * k]
    vals <- suppressWarnings(as.numeric(txt[(first_est + 2 * k + 1):(first_est + 4 * k)]))
    stopifnot(!anyNA(vals))
    # exactly one release group: the next paragraph must start a new section or the notes
    stopifnot(grepl("Detail for|^Notes:", txt[first_est + 4 * k + 1]))

    data.frame(spp_rel_loc = grp, param = param, reach = labels,
               est = vals[c(TRUE, FALSE)], SE = vals[c(FALSE, TRUE)],
               se_method = ifelse(grepl(dagger, hdr[c(FALSE, TRUE)], fixed = TRUE),
                                  "bootstrap", "inverse Hessian"),
               stringsAsFactors = FALSE)
  }

  loc_dirs <- list.dirs(file.path(tl_root, spp), recursive = FALSE)
  loc_dirs <- loc_dirs[order(match(basename(loc_dirs), c("RI", "PR")))]
  loc_name <- c(RI = "Rock Island", PR = "Priest Rapids")

  modeled_ls <- cum_ls <- vector("list", length(loc_dirs))
  for (ii in seq_along(loc_dirs)) {
    rel_loc <- basename(loc_dirs[ii])
    stopifnot(rel_loc %in% names(loc_name))

    txt_m <- read_txt(find_file(loc_dirs[ii], "_Modeled"))
    txt_c <- read_txt(find_file(loc_dirs[ii], "_ModeledCum"))

    modeled_ls[[ii]] <- rbind(
      parse_section(txt_m, "^Survival Detail for", "surv_p"),
      parse_section(txt_m, "^Capture Detail for", "capture_p"))
    cum_ls[[ii]] <- parse_section(txt_c, "^Cumulative Survival Detail for", "cum_surv_p")

    # the release group in the report must match the folder and species
    for (tb in list(modeled_ls[[ii]], cum_ls[[ii]])) {
      stopifnot(all(grepl(loc_name[[rel_loc]], tb$spp_rel_loc)), all(grepl(spp, tb$spp_rel_loc)))
    }
    modeled_ls[[ii]] <- cbind(rel_loc = rel_loc, modeled_ls[[ii]])
    cum_ls[[ii]] <- cbind(rel_loc = rel_loc, cum_ls[[ii]])
  }

  out <- setNames(list(do.call(rbind, modeled_ls), do.call(rbind, cum_ls)),
                  paste0(spp, c("_TL_Modeled_tab", "_TL_ModeledCum_tab")))
  if (!is.null(out_file)) saveRDS(out, out_file)
  out
}
