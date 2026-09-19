
#' Function: add_DH_qsec3_elwise
#'
#' Generates Quarto code block for a detection history table filtered by
#' species and status. Returns formatted markdown/R code suitable for inclusion
#' in Quarto reports.
#'
#' @param tag_DH_ls_nm_in Name of the detection history list element to use
#'   (default: "raw_RI_summ")
#' @param header_in Header text for the table section
#' @param spp_in Species code to filter on (e.g., "CHN", "STH")
#' @param status_in Status value to filter on (e.g., "Alive")
#' @param header_level Markdown header level (e.g., "####")
#' @param status_is Logical. If TRUE, filters for rows where status equals
#'   status_in. If FALSE, filters for rows where status does not equal
#'   status_in (default: TRUE).
#'
#' @return Character vector of Quarto markdown code
#'
#' @keywords QAQC quarto
#' @export
add_DH_qsec3_elwise <- function(tag_DH_ls_nm_in = "raw_RI_summ",
                                header_in,
                                spp_in,
                                status_in,
                                header_level,
                                status_is = TRUE) {
  c(
    paste(header_level, header_in),
    "```{r,echo=F,eval=T}",
    if(status_is) {
      paste0("knitr::kable(tag_DH_ls$'", tag_DH_ls_nm_in, "' |> filter(spp=='", spp_in, "' & status=='", status_in, "'))")
    } else {
      paste0("knitr::kable(tag_DH_ls$'", tag_DH_ls_nm_in, "' |> filter(spp=='", spp_in, "' & status!='", status_in, "'))")
    },
    "```"
  )
}
