#' Draw a diagram of the pipeline (scripts, helper functions, data sets and outputs) as an SVG
#'
#' The diagram is built by static analysis of the pipeline scripts listed in `pipeline_steps`
#' (defined in run_pipeline.R) and the helper files they `source()` from `R/`. Nothing is run.
#'
#' What is detected (by parsing the code, not by running it):
#'  * `source("R/xxx.R")`                     -> helper-function node feeding the script
#'  * read calls (readRDS, read.csv, read_excel, read_html, list.files, quarto_render, ...)
#'                                            -> data node feeding the script
#'  * write calls (saveRDS, write.*, saveWorkbook, ggsave, png, file.rename, ...), and any
#'    argument named out*/output*/save*        -> data/output node written by the script
#'  * path strings assigned to variables or built with file.path()/paste0() are resolved
#'  * default path arguments of the helper functions a script calls (e.g. process_all_atlas_files())
#'  * strings passed to helper functions defined in `R/` are treated as inputs
#'  * manual TagPro / ATLAS steps get their reads/writes from `manual_io`
#'
#' Layout (left to right): raw/manual inputs | R/ helper functions | scripts (grouped by stage) |
#' intermediate data sets | final outputs. Paths with no extension are folders.
#'
#' @param out_file Where to write the SVG.
#' @param steps Data frame like `pipeline_steps` (columns stage, type, path, note, requires).
#'   Defaults to `pipeline_steps` if it exists, otherwise run_pipeline.R is sourced to get it.
#' @param manual_io List of list(match =, reads =, writes =) giving the inputs/outputs of the manual
#'   steps; `match` is a regular expression matched against the manual step's name.
#' @param dynamic_io Like `manual_io`, for automatic scripts whose input/output paths are built
#'   at run time (so static analysis cannot see them): list of list(match =, reads =, writes =),
#'   with `match` a regular expression matched against the script path.
#' @param include_functions Show the R/ helper-function column.
#' @param repo_root Repo root (default: current directory).
#' @return Invisibly, a list with `nodes` and `edges` data frames (the diagram's contents).
create_repo_diagram <- function(out_file = "repo_diagram.svg",
                                steps = NULL,
                                manual_io = NULL, dynamic_io = NULL,
                                include_functions = TRUE,
                                repo_root = ".") {
  old_wd <- setwd(repo_root); on.exit(setwd(old_wd), add = TRUE)

  if (is.null(steps)) {
    if (!exists("pipeline_steps", inherits = TRUE)) source("run_pipeline.R", local = TRUE)
    steps <- get("pipeline_steps", inherits = TRUE)
  }
  if (is.null(manual_io)) {
    manual_io <- list(
      list(match = "^TagPro", reads = "data/clean/pre_tagpro",
           writes = "data/clean/post_tagpro"),
      list(match = "^ATLAS single-release", reads = "data/clean/post_tagpro",
           writes = c("assumption_checking/tagger_effects/all_sites_run",
                      "assumption_checking/tagger_effects/BRZsel_run")),
      list(match = "^ATLAS pooled", reads = "data/Nov_run",
           writes = c("analysis/pooled", "analysis/replicate_level")))
  }

  if (is.null(dynamic_io)) {
    dynamic_io <- list(
      list(match = "extractinng_ATLAS_rtfs_CHN",
           reads = c("analysis/replicate_level", "analysis/pooled"), writes = "analysis/CHN_ATLAS_out.rds"),
      list(match = "extractinng_ATLAS_rtfs_STH",
           reads = c("analysis/replicate_level", "analysis/pooled"), writes = "analysis/STH_ATLAS_out.rds"),
      list(match = "analysis/taglife/vitality_LRT",
           reads = character(), writes = "media/docx/taglife/lrt_table_weibull_rc*.docx"),
      list(match = "03_compile_postATLAS",
           reads = character(), writes = c("media/png/assumption_checking/tagger_survival_comparison.png",
                                           "media/png/assumption_checking/tagger_cumul_survival_comparison.png")))
  }

  # ---------------------------------------------------------------- parsing helpers
  strip_comments <- function(x) {
    gsub("(\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*')|#.*", "\\1", x, perl = TRUE)
  }
  tok_re <- paste0("\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'|",
                   "[A-Za-z_.][A-Za-z0-9_.]*(?:::[A-Za-z_.][A-Za-z0-9_.]*)?|<-|[(),={}$]")
  norm_path <- function(p) {
    p <- gsub("\\\\", "/", p)
    p <- sub("^[A-Za-z]:/repos/grant_2026/", "", p, ignore.case = TRUE)
    p <- gsub("^(\\./|\\.\\./)+", "", p)
    p <- sub("/+$", "", p)
    sub("/\\*$", "", p)           # "<dir>/*" (unknown file name in a folder) -> the folder
  }
  path_ext <- "\\.(rds|csv|xlsx|docx|png|qmd|md|rtf|html|pdf|svg|txt|json|R|r)$"
  is_path <- function(v) {
    !grepl("[\n{%]|^https?:", v) && !grepl("^\\*", v) && nzchar(v) &&
      (grepl("/", v, fixed = TRUE) || grepl(path_ext, v)) && !grepl("^\\.+$", v)
  }

  parse_file <- function(f) {
    txt <- paste(strip_comments(readLines(f, warn = FALSE)), collapse = "\n")
    tok <- regmatches(txt, gregexpr(tok_re, txt, perl = TRUE))[[1]]
    n <- length(tok)
    is_str <- function(t) grepl("^[\"']", t)
    unq <- function(t) substr(t, 2, nchar(t) - 1)
    is_id <- function(t) grepl("^[A-Za-z_.]", t) && !is_str(t)

    # simple string variables and function definitions (with string defaults)
    vars <- list(); defs <- list()
    for (i in seq_len(n)) {
      if (tok[i] == "<-" && i > 1 && i < n && is_id(tok[i - 1])) {
        if (is_str(tok[i + 1]) && !(i + 2 <= n && tok[i + 2] == "(")) vars[[tok[i - 1]]] <- unq(tok[i + 1])
        if (tok[i + 1] == "function" && i + 2 <= n && tok[i + 2] == "(") {
          depth <- 0; j <- i + 2; fname <- tok[i - 1]
          while (j <= n) {
            if (tok[j] == "(") depth <- depth + 1
            if (tok[j] == ")") { depth <- depth - 1; if (depth == 0) break }
            if (depth == 1 && is_id(tok[j]) && j + 2 <= n && tok[j + 1] == "=" && is_str(tok[j + 2]))
              defs[[length(defs) + 1]] <- list(fn = fname, arg = tok[j], value = unq(tok[j + 2]))
            j <- j + 1
          }
        }
      }
    }
    def_names <- unique(vapply(defs, `[[`, "", "fn"))
    all_defs <- unique(c(def_names, vapply(seq_len(n), function(i) {
      if (tok[i] == "<-" && i > 1 && i + 1 <= n && tok[i + 1] == "function") tok[i - 1] else NA_character_
    }, "")))
    all_defs <- all_defs[!is.na(all_defs)]

    # walk the tokens keeping a stack of open calls
    stack <- list(); events <- list(); calls <- character(); cid <- 0
    for (i in seq_len(n)) {
      t <- tok[i]
      if (is_id(t) && i < n && tok[i + 1] == "(") {
        nm <- sub("^.*::", "", t); cid <- cid + 1
        stack[[length(stack) + 1]] <- list(name = nm, id = cid, parts = character(), partial = FALSE)
        calls <- c(calls, nm)
        next
      }
      if (t == "(" && !(i > 1 && is_id(tok[i - 1]))) {
        cid <- cid + 1
        stack[[length(stack) + 1]] <- list(name = "(", id = cid, parts = character(), partial = FALSE)
        next
      }
      if (t == ")") {
        if (!length(stack)) next
        top <- stack[[length(stack)]]; stack[[length(stack)]] <- NULL
        val <- NULL
        if (top$name %in% c("file.path", "paste0")) {
          val <- paste(top$parts, collapse = if (top$name == "file.path") "/" else "")
          val <- gsub("\\*+", "*", val)
        }
        if (length(stack)) {
          par <- stack[[length(stack)]]
          if (par$name %in% c("file.path", "paste0")) {
            if (!is.null(val)) par$parts <- c(par$parts, val) else par$parts <- c(par$parts, "*")
            stack[[length(stack)]] <- par
          } else if (!is.null(val)) {
            events[[length(events) + 1]] <- list(value = val, arg = NA_character_,
              stack = vapply(rev(stack), `[[`, "", "name"), ids = vapply(rev(stack), `[[`, 0, "id"))
          }
        } else if (!is.null(val)) {
          events[[length(events) + 1]] <- list(value = val, arg = NA_character_, stack = character(), ids = numeric())
        }
        next
      }
      val <- NULL; arg <- NA_character_
      if (is_str(t)) {
        val <- unq(t)
        if (i > 2 && tok[i - 1] == "=" && is_id(tok[i - 2]) && tok[i - 2] != "=") arg <- tok[i - 2]
      } else if (is_id(t) && !(i < n && tok[i + 1] %in% c("(", "=")) && !(i > 1 && tok[i - 1] == "$")) {
        if (!is.null(vars[[t]]) && length(stack)) {
          val <- vars[[t]]
          if (i > 2 && tok[i - 1] == "=" && is_id(tok[i - 2])) arg <- tok[i - 2]
        } else if (length(stack) && stack[[length(stack)]]$name %in% c("file.path", "paste0") &&
                   !(t %in% c("TRUE", "FALSE", "NULL", "T", "F"))) {
          top <- stack[[length(stack)]]; top$parts <- c(top$parts, "*"); stack[[length(stack)]] <- top
        }
      }
      if (is.null(val)) next
      if (length(stack) && stack[[length(stack)]]$name %in% c("file.path", "paste0")) {
        top <- stack[[length(stack)]]; top$parts <- c(top$parts, val); stack[[length(stack)]] <- top
      } else {
        events[[length(events) + 1]] <- list(value = val, arg = arg,
          stack = vapply(rev(stack), `[[`, "", "name"), ids = vapply(rev(stack), `[[`, 0, "id"))
      }
    }
    list(events = events, defs = defs, def_names = all_defs, calls = unique(calls))
  }

  cache <- list()
  get_parse <- function(f) {
    if (is.null(cache[[f]])) cache[[f]] <<- parse_file(f)
    cache[[f]]
  }

  # R/ helper files: which functions they define, which other helpers they source
  r_files <- list.files("R", pattern = "\\.[Rr]$", full.names = TRUE)
  helper_defs <- list()
  for (f in r_files) helper_defs[[f]] <- get_parse(f)$def_names
  user_fns <- unique(unlist(helper_defs))

  # existence checks (file.exists) and dir.create() are not treated as data reads/writes
  read_re  <- "^(read|load|list\\.files|dir$|quarto_render|render$|unzip|scan$)"
  write_re <- "^(write|save|ggsave|png$|pdf$|svg$|jpeg$|tiff$|file\\.rename|file\\.copy|file\\.create|sink)"
  # strings that are regular expressions / patterns rather than paths
  looks_regex <- function(v) grepl("[$^|]|\\\\", v)
  regex_args <- c("pattern", "regexp", "replacement", "split", "sep", "fixed", "ignore.case")
  classify <- function(stack, arg) {
    if (!is.na(arg) && grepl("^(out|output|save)", arg)) return(list(kind = "write", id = NA))
    for (k in seq_along(stack)) {
      nm <- stack[k]
      if (nm == "source") return(list(kind = "source", id = k))
      if (grepl(write_re, nm)) return(list(kind = "write", id = k, fn = nm))
      if (grepl(read_re, nm)) return(list(kind = "read", id = k, fn = nm))
      if (nm %in% user_fns) return(list(kind = "read", id = k, fn = nm))
    }
    NULL
  }

  sourced_r <- function(f, seen = character()) {          # transitive R/ helper dependencies
    out <- character()
    for (e in get_parse(f)$events) {
      cl <- classify(e$stack, e$arg)
      if (!is.null(cl) && cl$kind == "source" && grepl("^R/.*\\.[Rr]$", norm_path(e$value))) out <- c(out, norm_path(e$value))
    }
    out <- unique(out)
    for (o in setdiff(out, seen)) if (file.exists(o)) out <- unique(c(out, sourced_r(o, c(seen, out))))
    out
  }

  # ---------------------------------------------------------------- edges
  edges <- data.frame(from = character(), to = character(), type = character(), stringsAsFactors = FALSE)
  add_edge <- function(from, to, type) edges[nrow(edges) + 1, ] <<- c(from, to, type)

  steps$id <- paste0("S:", steps$path)
  for (ii in seq_len(nrow(steps))) {
    st <- steps[ii, ]
    if (st$type == "manual") {
      for (m in manual_io) if (grepl(m$match, st$path)) {
        for (p in m$reads)  add_edge(paste0("D:", norm_path(p)), st$id, "read")
        for (p in m$writes) add_edge(st$id, paste0("D:", norm_path(p)), "write")
      }
      next
    }
    if (!file.exists(st$path)) next
    ps <- get_parse(st$path)
    helpers <- sourced_r(st$path)
    cl_events <- list()
    for (e in ps$events) {
      cl <- classify(e$stack, e$arg)
      if (is.null(cl)) next
      if (looks_regex(e$value) || (!is.na(e$arg) && e$arg %in% regex_args)) next
      v <- norm_path(e$value)
      if (cl$kind == "source") {
        if (grepl("^R/", v) && file.exists(v)) helpers <- unique(c(helpers, v), sourced_r(v))
        else if (v %in% norm_path(steps$path)) add_edge(paste0("S:", steps$path[match(v, norm_path(steps$path))]), st$id, "sources")
        next
      }
      if (!is_path(v) || (grepl("\\.[Rr]$", v))) next
      cl_events[[length(cl_events) + 1]] <- list(value = v, kind = cl$kind, relevant = e$stack[cl$id],
                                                 call_id = e$ids[cl$id], arg = e$arg)
    }
    # file.rename(from, to): only the destination is an output
    if (length(cl_events)) {
      ren <- which(vapply(cl_events, function(x) identical(x$relevant, "file.rename"), TRUE))
      if (length(ren)) {
        keep_last <- tapply(ren, vapply(cl_events[ren], function(x) x$call_id, 0), max)
        drop <- setdiff(ren, keep_last)
        if (length(drop)) cl_events <- cl_events[-drop]
      }
    }
    provided <- list()
    for (e in ps$events) {
      cl <- classify(e$stack, e$arg)
      if (!is.null(e$arg) && !is.na(e$arg)) for (fnm in e$stack) provided[[fnm]] <- c(provided[[fnm]], e$arg)
    }
    for (e in cl_events) {
      add_edge(if (e$kind == "write") st$id else paste0("D:", e$value),
               if (e$kind == "write") paste0("D:", e$value) else st$id, e$kind)
      if (e$kind == "write") edges[nrow(edges), ] <- c(st$id, paste0("D:", e$value), "write")
      if (e$kind == "read")  edges[nrow(edges), ] <- c(paste0("D:", e$value), st$id, "read")
    }
    # default path arguments of helper functions this script calls
    for (h in helpers) {
      hp <- get_parse(h)
      for (d in hp$defs) {
        if (!(d$fn %in% ps$calls)) next
        if (d$arg %in% provided[[d$fn]]) next
        if (looks_regex(d$value) || d$arg %in% regex_args) next
        v <- norm_path(d$value)
        if (!is_path(v) || grepl("\\.[Rr]$", v)) next
        if (grepl("^(out|output|save)", d$arg)) add_edge(st$id, paste0("D:", v), "write")
        else add_edge(paste0("D:", v), st$id, "read")
      }
    }
    for (m in dynamic_io) if (grepl(m$match, st$path)) {
      for (p in m$reads)  add_edge(paste0("D:", norm_path(p)), st$id, "read")
      for (p in m$writes) add_edge(st$id, paste0("D:", norm_path(p)), "write")
    }
    if (include_functions) for (h in helpers) add_edge(paste0("F:", h), st$id, "uses")
  }
  edges <- unique(edges)
  edges <- edges[edges$from != edges$to, ]
  # drop an output folder node when files written inside it are drawn individually
  dnodes <- unique(c(grep("^D:", edges$from, value = TRUE), grep("^D:", edges$to, value = TRUE)))
  is_folder <- !grepl("\\.[A-Za-z0-9]+$", basename(dnodes))
  only_written <- !(dnodes %in% edges$from)
  has_child <- vapply(dnodes, function(x) any(startsWith(dnodes, paste0(x, "/"))), TRUE)
  drop_ids <- dnodes[is_folder & only_written & has_child]
  edges <- edges[!(edges$from %in% drop_ids | edges$to %in% drop_ids), ]

  # ---------------------------------------------------------------- nodes
  data_ids <- unique(c(grep("^D:", edges$from, value = TRUE), grep("^D:", edges$to, value = TRUE)))
  produced <- unique(edges$to[edges$type == "write"]); consumed <- unique(edges$from[edges$type == "read"])
  nodes <- rbind(
    data.frame(id = steps$id, kind = "script", stage = steps$stage, type = steps$type,
               label = ifelse(steps$type == "manual", paste0(steps$path, " (manual)"), basename(steps$path)),
               tip = steps$path, stringsAsFactors = FALSE),
    if (length(data_ids)) data.frame(
      id = data_ids,
      kind = ifelse(data_ids %in% produced & data_ids %in% consumed, "intermediate",
                    ifelse(data_ids %in% produced, "output", "input")),
      stage = NA_character_, type = NA_character_,
      label = NA_character_, tip = sub("^D:", "", data_ids), stringsAsFactors = FALSE),
    if (include_functions) {
      fids <- unique(grep("^F:", edges$from, value = TRUE))
      if (length(fids)) data.frame(id = fids, kind = "function", stage = NA_character_, type = NA_character_,
                                   label = sub("\\.[Rr]$", "", basename(sub("^F:", "", fids))),
                                   tip = sub("^F:", "", fids), stringsAsFactors = FALSE)
    })
  rownames(nodes) <- NULL
  # data labels: files = basename (parent/basename when ambiguous or a wildcard such as "*.png");
  # folders = the full repo-relative path with a trailing slash. Long labels keep their right-hand end.
  d <- nodes$kind %in% c("input", "intermediate", "output")
  tips <- nodes$tip[d]
  base <- basename(tips); has_ext <- grepl("\\.[A-Za-z0-9]+$", base)
  lab <- ifelse(has_ext, base, paste0(tips, "/"))
  dup <- has_ext & (duplicated(lab) | duplicated(lab, fromLast = TRUE) | grepl("^\\*", base))
  par <- basename(dirname(tips))
  lab[dup] <- paste0(par[dup], "/", lab[dup])
  nodes$label[d] <- ifelse(nchar(lab) > 58, paste0("\u2026", substr(lab, nchar(lab) - 56, nchar(lab))), lab)
  nodes$label[nodes$kind == "script"] <- ifelse(nchar(nodes$label[nodes$kind == "script"]) > 52,
    paste0(substr(nodes$label[nodes$kind == "script"], 1, 51), "\u2026"), nodes$label[nodes$kind == "script"])

  # ---------------------------------------------------------------- layout
  cols <- c("input", "function", "script", "intermediate", "output")
  if (!include_functions) cols <- setdiff(cols, "function")
  cw <- 6.7; rowh <- 21; pad <- 16; gap <- 170
  col_w <- sapply(cols, function(k) { l <- nodes$label[nodes$kind == k]; if (length(l)) max(nchar(l)) * cw + 2 * pad else 60 })
  col_x <- cumsum(c(40, head(col_w + gap, -1))); names(col_x) <- cols
  n_per <- table(factor(nodes$kind, levels = cols))
  top <- 150
  H <- max(max(n_per) * rowh, sum(nodes$kind == "script") * rowh * 1.55)
  nodes$x <- col_x[nodes$kind]; nodes$w <- col_w[nodes$kind]; nodes$y <- NA_real_
  sc <- which(nodes$kind == "script")
  stage_gap <- 10
  stg <- nodes$stage[sc]; stage_idx <- cumsum(c(TRUE, stg[-1] != stg[-length(stg)]))
  spacing <- (H - stage_gap * max(stage_idx)) / length(sc)
  nodes$y[sc] <- top + (seq_along(sc) - 0.5) * spacing + (stage_idx - 1) * stage_gap
  script_y <- setNames(nodes$y[sc], nodes$id[sc])
  neighbours <- function(id) {
    e <- edges[(edges$from == id | edges$to == id) & !(edges$type == "sources"), ]
    other <- ifelse(e$from == id, e$to, e$from); other[other %in% names(script_y)]
  }
  for (k in setdiff(cols, "script")) {
    idx <- which(nodes$kind == k); if (!length(idx)) next
    y0 <- vapply(nodes$id[idx], function(id) { nb <- neighbours(id); if (length(nb)) mean(script_y[nb]) else top + H / 2 }, 0)
    o <- order(y0, nodes$label[idx]); idx <- idx[o]; y <- y0[o]
    for (j in seq_along(y)[-1]) y[j] <- max(y[j], y[j - 1] + rowh)
    lim <- top + H + rowh
    if (tail(y, 1) > lim) { y[length(y)] <- lim; for (j in rev(seq_along(y))[-1]) y[j] <- min(y[j], y[j + 1] - rowh) }
    nodes$y[idx] <- y
  }
  total_h <- max(nodes$y, na.rm = TRUE) + 60
  total_w <- max(nodes$x + nodes$w, na.rm = TRUE) + 40

  # ---------------------------------------------------------------- SVG
  esc <- function(x) gsub(">", "&gt;", gsub("<", "&lt;", gsub("&", "&amp;", x, fixed = TRUE), fixed = TRUE), fixed = TRUE)
  stage_cols <- c("#e8f0fe", "#fff4e0", "#e9f7ef", "#fdecef", "#f3e8fd", "#e0f7fa", "#fffde7", "#eceff1")
  fill_for <- c(input = "#cfe8ff", intermediate = "#fff3b0", output = "#c8efc8", `function` = "#e6d9f5",
                script = "#ffffff")
  edge_col <- c(read = "#3b6ea5", write = "#2e8b57", uses = "#8a63b8", sources = "#c0392b")
  svg <- c(sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" font-family="Consolas, Menlo, monospace" font-size="11">',
                   round(total_w), round(total_h), round(total_w), round(total_h)),
           '<style>.edge{fill:none;stroke-opacity:.35;stroke-width:1.2}.edge:hover{stroke-opacity:1;stroke-width:2.4}.node rect{stroke:#555;stroke-width:1}.node:hover rect{stroke:#000;stroke-width:2}</style>',
           '<defs>',
           paste0(sprintf('<marker id="arr_%s" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="%s"/></marker>',
                          names(edge_col), edge_col), collapse = ""),
           '</defs>',
           sprintf('<rect width="100%%" height="100%%" fill="white"/>'),
           '<text x="40" y="32" font-size="20" font-weight="bold">grant_2026 pipeline: scripts, functions, data sets and outputs</text>',
           '<text x="40" y="52" font-size="11" fill="#555">Generated by create_repo_diagram() from static analysis of the pipeline scripts. Hover a line to highlight it; hover a box for its full path.</text>')
  # stage bands + labels
  stages <- unique(nodes$stage[sc])
  for (si in seq_along(stages)) {
    ys <- nodes$y[sc][nodes$stage[sc] == stages[si]]
    y1 <- min(ys) - spacing / 2; y2 <- max(ys) + spacing / 2
    svg <- c(svg, sprintf('<rect x="20" y="%.1f" width="%.1f" height="%.1f" fill="%s" opacity="0.7"/>',
                          y1, total_w - 40, y2 - y1, stage_cols[(si - 1) %% length(stage_cols) + 1]),
             sprintf('<text x="26" y="%.1f" font-size="10" fill="#444" font-weight="bold">%s</text>', y1 + 12, esc(stages[si])))
  }
  # column headings
  heads <- c(input = "Inputs", `function` = "R/ functions", script = "Scripts", intermediate = "Intermediate data", output = "Outputs")
  for (k in cols) svg <- c(svg, sprintf('<text x="%.1f" y="%.1f" font-weight="bold" font-size="12">%s</text>', col_x[k], top - 28, heads[k]))
  # legend
  lx <- total_w - 330; ly <- 22
  leg <- c(sprintf('<rect x="%.0f" y="%.0f" width="14" height="10" fill="%s" stroke="#555"/><text x="%.0f" y="%.0f">%s</text>',
                   lx, ly, fill_for["input"], lx + 20, ly + 9, "input"),
           sprintf('<rect x="%.0f" y="%.0f" width="14" height="10" fill="%s" stroke="#555"/><text x="%.0f" y="%.0f">%s</text>',
                   lx + 70, ly, fill_for["intermediate"], lx + 90, ly + 9, "intermediate"),
           sprintf('<rect x="%.0f" y="%.0f" width="14" height="10" fill="%s" stroke="#555"/><text x="%.0f" y="%.0f">%s</text>',
                   lx + 190, ly, fill_for["output"], lx + 210, ly + 9, "output"),
           sprintf('<rect x="%.0f" y="%.0f" width="14" height="10" fill="%s" stroke="#555"/><text x="%.0f" y="%.0f">%s</text>',
                   lx, ly + 18, fill_for["function"], lx + 20, ly + 27, "R/ function"),
           sprintf('<rect x="%.0f" y="%.0f" width="14" height="10" fill="white" stroke="#555" stroke-dasharray="3,2"/><text x="%.0f" y="%.0f">%s</text>',
                   lx + 100, ly + 18, lx + 120, ly + 27, "manual step"))
  for (k in seq_along(edge_col)) {
    leg <- c(leg, sprintf('<line x1="%.0f" y1="%.0f" x2="%.0f" y2="%.0f" stroke="%s" stroke-width="2"/><text x="%.0f" y="%.0f">%s</text>',
                          lx + (k - 1) * 82, ly + 45, lx + (k - 1) * 82 + 16, ly + 45, edge_col[k],
                          lx + (k - 1) * 82 + 20, ly + 49, c(read = "reads", write = "writes", uses = "uses", sources = "sources")[k]))
  }
  svg <- c(svg, leg)
  # edges (behind nodes)
  pos <- nodes; rownames(pos) <- pos$id
  for (r in seq_len(nrow(edges))) {
    a <- pos[edges$from[r], ]; b <- pos[edges$to[r], ]
    if (is.na(a$x) || is.na(b$x)) next
    if (a$x + a$w <= b$x) { x1 <- a$x + a$w; x2 <- b$x } else if (b$x + b$w <= a$x) { x1 <- a$x; x2 <- b$x + b$w } else { x1 <- a$x + a$w; x2 <- b$x + b$w }
    dx <- (x2 - x1) / 2
    d <- sprintf("M%.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f", x1, a$y, x1 + dx, a$y, x2 - dx, b$y, x2, b$y)
    svg <- c(svg, sprintf('<path class="edge" d="%s" stroke="%s" marker-end="url(#arr_%s)"><title>%s &#8594; %s (%s)</title></path>',
                          d, edge_col[edges$type[r]], edges$type[r], esc(sub("^[A-Z]:", "", edges$from[r])),
                          esc(sub("^[A-Z]:", "", edges$to[r])), edges$type[r]))
  }
  # nodes
  for (r in seq_len(nrow(nodes))) {
    nd <- nodes[r, ]
    dash <- if (nd$kind == "script" && identical(nd$type, "manual")) ' stroke-dasharray="4,3"' else ""
    note <- if (nd$kind == "script" && identical(nd$type, "after_manual")) " [needs manual outputs]" else ""
    svg <- c(svg, sprintf('<g class="node"><title>%s%s</title><rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="4" fill="%s"%s/><text x="%.1f" y="%.1f" dominant-baseline="middle">%s</text></g>',
                          esc(nd$tip), note, nd$x, nd$y - rowh / 2 + 2, nd$w, rowh - 4, fill_for[nd$kind], dash,
                          nd$x + pad / 2, nd$y, esc(nd$label)))
  }
  svg <- c(svg, "</svg>")
  dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)
  writeLines(svg, out_file, useBytes = TRUE)
  message("Wrote ", out_file, " (", nrow(nodes), " nodes, ", nrow(edges), " edges)")
  invisible(list(nodes = nodes, edges = edges))
}
