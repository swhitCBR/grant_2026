# Taglife TODO

## Task: Modify vitality.ku Right Censoring Model Output

**Status**: Pending

**Description**: 
Currently, the vitality.ku models are fit separately for censored and non-censored datasets, requiring two separate function calls to compare results. 

**Goal**: 
Modify the approach to have the vitality.ku right censoring model return parameter estimates with **and without** censoring in a single call or streamlined comparison.

**Details**:
- Currently using the vitality package's `vitality.ku()` function
- Censoring threshold: 75 days (observations > 75 days are right-censored)
- Need to return both:
  - Non-censored estimates (rc.data = FALSE)
  - Censored estimates (rc.data = TRUE)
- Should facilitate direct comparison of parameter estimates across censoring scenarios

**Current Implementation**: 
Script `03_vitality_ku_raw_fits.R` currently fits both models separately and compares them post-hoc with percent difference calculations.

**Next Steps**:
1. Explore wrapper function to simultaneously fit and return both censored and non-censored models
2. Compare results side-by-side for each lot and pooled dataset
3. Assess impact of censoring on r, s, k, and u parameter estimates
