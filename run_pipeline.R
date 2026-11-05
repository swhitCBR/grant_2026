# Master script: runs the sourceable scripts of the grant_2026 pipeline in order.
# Run from the repo root (open grant_2026.Rproj).
#
# Step types:
#   auto    - runs unattended
#   manual  - done by hand in TagPro / ATLAS; printed as a reminder (pauses if include_manual = TRUE)
#   after_manual - a script that needs the output of a manual step; runs only if every path
#                  listed in `requires` exists, otherwise it is logged as "skipped"
#
# Usage:
#   source("run_pipeline.R")                    # defines pipeline_steps / run_pipeline(), runs nothing
#   run_pipeline(stages = "data_cleaning")      # run one stage
#   run_pipeline()                              # run everything that can run
#
# Diagram of all scripts, functions, data sets and outputs (writes repo_diagram.svg):
#   source("R/create_repo_diagram.R"); create_repo_diagram()

stopifnot("Run from the repo root (open grant_2026.Rproj)" = file.exists("grant_2026.Rproj"))

step <- function(stage, type, path, note = "", requires = "") {
  data.frame(stage = stage, type = type, path = path, note = note,
             requires = requires, stringsAsFactors = FALSE)
}

# Directories that hold the pasted ATLAS output used by tagger_effects/03
atlas_md_dirs <- paste("assumption_checking/tagger_effects",
                       c("all_sites_run", "BRZsel_run"), sep = "/", collapse = ";")

pipeline_steps <- rbind(
  step("data_cleaning", "auto", "data_cleaning/01_load_csvs.R"),
  step("data_cleaning", "auto", "data_cleaning/02_create_tag_subsets.R"),
  step("data_cleaning", "auto", "data_cleaning/03_create_DH_from_tag_subsets.R"),

  step("QAQC", "auto", "QAQC/QAQC_tables_full_set.R",
       "renders 2 Word reports into media/docx/QAQC word docs"),

  step("replicate_pooling", "auto",
       "data_cleaning/04_create_DH_for_spec_repIDs_and_survuse_subset.R",
       "writes replicate-level DH count xlsx and data/Nov_run/new_rep_ID_attrib_ATLAS.csv"),

  step("tagger_effects", "auto",
       "assumption_checking/tagger_effects/00_comp_SURVUSE_or_act_euth_tabs_and_plots.r",
       "writes summary rds and two PNGs in media/png"),
  step("tagger_effects", "auto",
       "assumption_checking/tagger_effects/01_tagpro_preprocessing.R",
       "writes TagPro input csvs to data/clean/pre_tagpro"),
  step("tagger_effects", "manual", "TagPro (all_sites and BRZsel runs)",
       "see assumption_checking/tagger_effects/TagPro settings (all_sites and BRZsel).md; writes *_ATLAS.csv to data/clean/post_tagpro"),
  step("tagger_effects", "after_manual",
       "assumption_checking/tagger_effects/02_post_tagpro_preATLAS_subsets.R",
       "filters RI_all_sites_MOD_ATLAS.csv and splits ATLAS files by tagger",
       "data/clean/post_tagpro/RI_all_sites_MOD_ATLAS.csv;data/clean/post_tagpro/PR_BRZsel_ATLAS.csv"),
  step("tagger_effects", "manual", "ATLAS single-release runs by tagger",
       "paste html output into the md files under tagger_effects/{all_sites_run,BRZsel_run}"),
  step("tagger_effects", "after_manual",
       "assumption_checking/tagger_effects/03_compile_postATLAS_results_and_perform_F_tests_on tagger esitmates.R",
       "scrapes ATLAS md files; writes xlsx to media/xlsx/assumption_checking and plots to media/png/assumption_checking",
       paste(atlas_md_dirs, "data/clean/summary_results_SURVUSE_OR_EUTH_ACTIVE.rds", sep = ";")),

  step("length_weight_condition", "after_manual",
       "assumption_checking/length_weight_condition/condition_factor_plotting_by_species_MOD.R",
       "condition-factor figures and exclusion table in media/png/assumption_checking",
       "data/clean/pre_tagpro/tags.csv;data/clean/pre_tagpro/events.csv;data/clean/pre_tagpro/nodes.csv"),

  step("mixing_plots", "auto", "analysis/mixing plots/more_mixing_plots_live_and_dead_fish.R",
       "live (R1) detections at Priest Rapids vs dead (D2) releases; writes 4 PNGs to media/png/mixing_dead_plts"),

  step("taglife", "auto", "analysis/taglife/Weibull_LRT_across_RC_values.R",
       "Weibull LRT of pooled vs separate lots across right-censoring values; prints only, writes no files"),

  step("taglife", "auto", "analysis/taglife/vitality_LRT.R",
       "pooled vs separate lots LRT (Weibull-2, 68 longest tags censored at 68.98 d); writes media/docx/taglife/lrt_table_weibull_rc68.98....docx (needs flextable)"),

  step("analysis", "manual", "ATLAS pooled and replicate-level runs",
       "see analysis/Grant_ATLAS_analysis_PROTOCOL.md; save the CaptHist/Cjs/Modeled reports as .rtf in analysis/pooled and analysis/replicate_level/{CHN,STH}"),
  step("analysis", "after_manual", "analysis/extractinng_ATLAS_rtfs_CHN.R",
       "parses CHN ATLAS reports; writes analysis/CHN_ATLAS_out.rds",
       "analysis/pooled/CHN_report;analysis/replicate_level/CHN"),
  step("analysis", "after_manual", "analysis/extractinng_ATLAS_rtfs_STH.R",
       "parses STH ATLAS reports; writes analysis/STH_ATLAS_out.rds",
       "analysis/pooled/STH_report;analysis/replicate_level/STH")
)

# Inputs that must exist before the pipeline starts
check_inputs <- function() {
  inputs <- c(
    "data/Round 2",
    "data/Nov_run",
    "media/xlsx/replicate_regrouping/replicate releases and suggested replicate pooling.xlsx"
  )
  missing <- inputs[!file.exists(inputs)]
  if (length(missing)) warning("Missing inputs: ", paste(missing, collapse = "; "))
  invisible(missing)
}

# Source one script in a fresh child of globalenv; record status, warnings, time
run_step <- function(path) {
  warns <- character()
  t0 <- Sys.time()
  status <- tryCatch({
    withCallingHandlers(
      source(path, local = new.env(parent = globalenv())),
      warning = function(w) {
        warns <<- c(warns, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
    if (length(warns)) "warning" else "ok"
  }, error = function(e) {
    warns <<- c(warns, conditionMessage(e))
    "error"
  })
  data.frame(path = path, status = status,
             secs = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
             message = paste(unique(warns), collapse = " | "),
             stringsAsFactors = FALSE)
}

run_pipeline <- function(stages = unique(pipeline_steps$stage),
                         include_manual = FALSE, stop_on_error = TRUE,
                         make_diagram = TRUE) {
  check_inputs()
  steps <- pipeline_steps[pipeline_steps$stage %in% stages, ]
  log <- list()
  for (i in seq_len(nrow(steps))) {
    s <- steps[i, ]
    if (s$type == "manual") {
      message("MANUAL STEP: ", s$path, " - ", s$note)
      if (include_manual && interactive()) readline("Press Enter when done...")
      next
    }
    if (s$type == "after_manual") {
      req <- strsplit(s$requires, ";")[[1]]
      missing <- req[!file.exists(req)]
      if (length(missing)) {
        message("Skipping ", s$path, " (missing: ", paste(missing, collapse = ", "), ")")
        log[[length(log) + 1]] <- data.frame(
          path = s$path, status = "skipped", secs = 0,
          message = paste("missing:", paste(missing, collapse = ", ")),
          stringsAsFactors = FALSE)
        next
      }
    }
    message("Running ", s$path)
    res <- run_step(s$path)
    log[[length(log) + 1]] <- res
    if (res$status == "error" && stop_on_error) break
  }
  log <- do.call(rbind, log)
  print(log)
  invisible(log)
}
