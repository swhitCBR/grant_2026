#' Extract ATLAS report tables (capture histories, CJS and paired-release estimates)
#'
#' Parses the ATLAS report files saved as ".rtf" (they are actually Qt-generated HTML)
#' for every replicate folder of one species plus the pooled report folder.
#'
#' Files read (one of each per folder; "nobins" files are preferred when a folder has several):
#'   *CaptHist*.rtf  capture-history counts
#'   *Cjs*.rtf       single-release CJS estimates
#'   *Modeled*.rtf   paired-release model estimates
#'
#' Replicate IDs: the folder name gives `repID` (e.g. "CHN_14_15") and `spp_repID` ("14_15").
#' `new_repID` uses the comma form of pooled replicates ("14,15"), matching the `new_repID`
#' used in data_cleaning/04 and the pooling spreadsheet. The replicate is taken from the
#' report's own "repID_code:" line and checked against the folder name. The pooled folder
#' has no replicate attribute and is labelled "pool" in all three tables.
#'
#' @param spp "CHN" or "STH".
#' @param rep_root Folder holding one subfolder per replicate (<rep_root>/<spp>/<spp>_<rep>).
#' @param pool_root Folder holding the pooled report folder "<spp>_report".
#' @param out_file Where to save the result with saveRDS (NULL to skip saving).
#' @return A named list: <spp>_DH_tab, <spp>_Cjs_tab, <spp>_Pair_CJS_tab (also saved to out_file).
extract_atlas_rtf_tables <- function(spp = c("CHN", "STH"),
                                     rep_root = "analysis/replicate_level",
                                     pool_root = "analysis/pooled",
                                     out_file = file.path("analysis", paste0(spp, "_ATLAS_out.rds"))) {
  spp <- match.arg(spp)
  stopifnot(requireNamespace("xml2", quietly = TRUE))

  find_file <- function(dir, pattern) {
    fl <- list.files(dir, pattern = paste0(pattern, ".*\\.rtf$"))
    if (length(fl) > 1) fl <- fl[grepl("nobins", fl)]
    if (length(fl) != 1) stop("Expected exactly one '", pattern, "' file in ", dir, " but found ", length(fl))
    file.path(dir, fl)
  }
  read_txt <- function(f) trimws(xml2::xml_text(xml2::xml_find_all(xml2::read_html(f), "//p")))
  repID_code <- function(txt) {
    x <- grep("^repID_code:", txt, value = TRUE)
    if (length(x) == 1) trimws(sub("^repID_code:", "", x)) else NA_character_
  }

  # Folder inventory; replicate folders in numeric order, pooled report last
  rep_dirs <- list.dirs(file.path(rep_root, spp), recursive = FALSE)
  rep_ids <- basename(rep_dirs)
  rep_dirs <- rep_dirs[order(as.integer(sub("_.*", "", sub(paste0("^", spp, "_"), "", rep_ids))))]
  units <- rbind(
    data.frame(type = "rep", dir = rep_dirs, stringsAsFactors = FALSE),
    data.frame(type = "pool", dir = file.path(pool_root, paste0(spp, "_report")), stringsAsFactors = FALSE))
  units$folder <- basename(units$dir)
  units$repID <- ifelse(units$type == "rep", units$folder, "pool")
  units$spp_repID <- ifelse(units$type == "rep", sub(paste0("^", spp, "_"), "", units$folder), "pool")
  units$new_repID <- ifelse(units$type == "rep", gsub("_", ",", units$spp_repID), "pool")

  DH_ls <- Cjs_ls <- Pair_ls <- vector("list", nrow(units))
  for (ii in seq_len(nrow(units))) {
    u <- units[ii, ]
    ids <- data.frame(type = u$type, spp_repID = u$spp_repID, repID = u$repID, new_repID = u$new_repID)

    # ---- capture histories: two release groups x five detection histories
    txt1 <- read_txt(find_file(u$dir, "CaptHist"))
    stopifnot(grepl("^1 1:", txt1[3]), grepl("^0 0:", txt1[11]),
              grepl("^1 1:", txt1[14]), grepl("^0 0:", txt1[22]))
    DH_ls[[ii]] <- cbind(ids, rbind(
      data.frame(rel_loc_spp = txt1[2],  DH = substr(txt1[seq(3, 12, 2)], 1, 3),  count = txt1[seq(4, 12, 2)]),
      data.frame(rel_loc_spp = txt1[13], DH = substr(txt1[seq(14, 23, 2)], 1, 3), count = txt1[seq(15, 23, 2)])))

    # ---- single-release CJS estimates
    txt2 <- read_txt(find_file(u$dir, "Cjs"))
    attrib2 <- repID_code(txt2)
    if (u$type == "rep") stopifnot(identical(attrib2, u$folder))
    stopifnot(grepl("Tailrace", txt2[6]), grepl("Tailrace", txt2[9]),
              grepl("Tailrace", txt2[19]), grepl("Tailrace", txt2[24]))
    Cjs_ls[[ii]] <- cbind(ids, rbind(
      data.frame(attrib = attrib2, spp_rel_loc = txt2[6],  param = "surv_p", est = txt2[7],  SE = txt2[8]),
      data.frame(attrib = attrib2, spp_rel_loc = txt2[9],  param = "surv_p", est = txt2[10], SE = txt2[11]),
      data.frame(attrib = attrib2, spp_rel_loc = txt2[19], param = "det_p",  est = txt2[20], SE = txt2[21]),
      data.frame(attrib = attrib2, spp_rel_loc = txt2[19], param = "lambda", est = txt2[22], SE = txt2[23]),
      data.frame(attrib = attrib2, spp_rel_loc = txt2[24], param = "det_p",  est = txt2[25], SE = txt2[26]),
      data.frame(attrib = attrib2, spp_rel_loc = txt2[24], param = "lambda", est = txt2[27], SE = txt2[28])))

    # ---- paired-release model estimates
    txt3 <- read_txt(find_file(u$dir, "Modeled"))
    attrib3 <- repID_code(txt3)
    if (u$type == "rep") stopifnot(identical(attrib3, u$folder))
    stopifnot(grepl("^Paired Survival", txt3[9]), grepl("Tailrace", txt3[16]), grepl("Tailrace", txt3[19]),
              grepl("Tailrace", txt3[29]), grepl("Tailrace", txt3[34]))
    Pair_ls[[ii]] <- cbind(ids, rbind(
      data.frame(attrib = attrib3, spp_rel_loc = txt3[9],  param = "pair_surv_p", est = txt3[10], SE = txt3[11]),
      data.frame(attrib = attrib3, spp_rel_loc = txt3[16], param = "surv_p",      est = txt3[17], SE = txt3[18]),
      data.frame(attrib = attrib3, spp_rel_loc = txt3[19], param = "surv_p",      est = txt3[20], SE = txt3[21]),
      data.frame(attrib = attrib3, spp_rel_loc = txt3[29], param = "det_p",       est = txt3[30], SE = txt3[31]),
      data.frame(attrib = attrib3, spp_rel_loc = txt3[29], param = "lambda",      est = txt3[32], SE = txt3[33]),
      data.frame(attrib = attrib3, spp_rel_loc = txt3[34], param = "det_p",       est = txt3[35], SE = txt3[36]),
      data.frame(attrib = attrib3, spp_rel_loc = txt3[34], param = "lambda",      est = txt3[37], SE = txt3[38])))
  }

  DH_tab   <- do.call(rbind, DH_ls)
  Cjs_tab  <- do.call(rbind, Cjs_ls)
  Pair_tab <- do.call(rbind, Pair_ls)
  DH_tab$count <- as.numeric(DH_tab$count)
  for (nm in c("est", "SE")) {
    Cjs_tab[[nm]]  <- as.numeric(Cjs_tab[[nm]])
    Pair_tab[[nm]] <- as.numeric(Pair_tab[[nm]])
  }

  out <- setNames(list(DH_tab, Cjs_tab, Pair_tab),
                  paste0(spp, c("_DH_tab", "_Cjs_tab", "_Pair_CJS_tab")))
  if (!is.null(out_file)) saveRDS(out, out_file)
  out
}
