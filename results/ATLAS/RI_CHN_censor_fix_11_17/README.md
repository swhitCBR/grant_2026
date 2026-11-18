# RI_CHN_censor_fix_11_17/

ATLAS reports from the November 17, 2026 rerun of the Rock Island Chinook TLSR (tag-life adjusted single release) model: `RI_rerun_after_G72790346_fix_ATLAS_{CaptHist,Cjs,CjsCum,Modeled,ModeledCum,TagLife}.rtf`.

These are the current reports (the corrected rerun, saved at 17:39). They are identical copies of the files in `../Single Release Pooled TL/CHN/RI/`, which is the folder the extraction scripts read. ATLAS output is saved here first and then moved to that folder. The earlier rerun, in which I mistakenly omitted rows for the wrong tag, is not in this folder; it is in `../Single Release Pooled TL/CHN/RI/wrong_tag_hist_edit/`.

"RAB" had me recompute the TLSR Chinook estimates because the product of the reach probabilities did not match the total survival estimates. See `data/reach_spec_censor_fix/README.md` for the censoring decisions on the two flagged tags (undone for `G72790346`, kept for `G72B4A509`), and `rixTagPro_and_ATLAS_PROTOCOL.md` (repo root) for the instructions and screenshots.
