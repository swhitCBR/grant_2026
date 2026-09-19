# assumption_checking Workflow Documentation

## Overview
The `assumption_checking` directory contains an R-based workflow for processing TagPro acoustic telemetry data and generating reports on tagger effects for survival estimates.

## Key Scripts

### 1. `01_tagpro_preprocessing.R`
- **Purpose**: Load raw TagPro data and preprocess for analysis
- **Source Data**: `data/clean/` (tags, events, nodes CSVs)
- **Function Used**: `preprocess_for_tagpro()` from `R/preprocess_for_tagpro.R`
- **Outputs**: Processed CSV files ready for ATLAS and statistical analysis
- **Key Decisions**:
  - Filters tags by subset (default: `tags_SURVUSE_OR_EUTH_&_ACTIVE`)
  - Creates subsets of events and nodes based on tag_code

### 2. `02_post_tagpro_preATLAS_subsets.R`
- **Purpose**: Create subsets of TagPro output by tagger (A, B, C, etc.)
- **Dependencies**: ATLAS files must exist (`RI_tagger_comparison_ATLAS.csv`, `PR_tagger_comparison_ATLAS.csv`)
- **Logic**:
  - Reads processed TagPro files
  - For each unique tagger, filters:
    - Tags by tagger_name
    - Events by tag_code
    - Nodes by node_code
    - ATLAS files by tag_code (V3 column)
  - Outputs tagger-specific ATLAS CSVs (e.g., `RI_tagger_comparison_ATLAS_tagger_A.csv`)
- **Output Structure**: `data/clean/post_tagpro/` directory

### 3. `04_compile_atlas_res.R`
- **Purpose**: Compile results from ATLAS analysis (final step)
- **Status**: 481B file (minimal/template)

## Report Generation Workflow

### Template-Based Report Assembly
Located in subdirectories like `round_1/`, `round_2/`, `round_3/`:

1. **Template File**: `tagger_table_template.md`
   - Empty markdown table skeleton with headers for reaches and taggers
   - Placeholders for estimates, standard errors, and p-values

2. **Filled Markdown**: `tagger_table_with_pvalues.md` or `tagger_table_filled.md`
   - Template populated with actual estimates and p-values
   - Contains survival estimates from CJS models
   - Includes F-test p-values for tagger effect testing

3. **Quarto Report Template**: `tagger_table_report.qmd`
   - YAML front matter:
     - Format: docx with `reference-doc` for Word styling
     - Page orientation: landscape
     - Execute echo: false
   - Structure:
     - Header: "Survival Comparison Plot"
     - Sections for each release location × species combination
     - Markdown tables embedded directly
   - Reference documents: `templates/ref_doc_w.docx` or `ref_doc.docx`

## Data Flow

```
Raw Data (tags, events, nodes)
    ↓
01_tagpro_preprocessing.R
    ↓
Processed TagPro CSVs + ATLAS files
    ↓
02_post_tagpro_preATLAS_subsets.R
    ↓
Tagger-specific ATLAS subsets
    ↓
[External ATLAS analysis]
    ↓
Markdown tables with estimates & p-values
    ↓
[Populate tagger_table_report.qmd]
    ↓
Render to DOCX
```

## Key Variables & Naming Conventions

| Variable | Type | Meaning |
|----------|------|---------|
| tag_code | character | Unique identifier for each tag |
| tagger_name | character | Tagger identifier (A, B, C, etc.) |
| node_code | integer | Acoustic receiver node |
| V3 | numeric | Column in ATLAS files containing tag_code |
| _tagger_X | suffix | Indicates tagger-specific subset |

## Important Notes

- **ATLAS Files**: External output from TagPro analysis; required for creating tagger subsets
- **CJS Models**: Cormack-Jolly-Seber survival models calculated externally; results scraped into markdown
- **Statistical Testing**: F-tests used to test homogeneity of tagger effects
- **Document Styling**: Uses Word reference documents for consistent formatting across rounds

## Rounds Organization

- `round_1/`: Initial analysis round
- `round_2/`: Previously completed (archived in `old/`)
- `round_3/`: Current/latest round with recent workflow updates
  - Contains `run_workflow.R` and `round_1_workflow.R` for reproducible analysis

## Templates Directory

- `ref_doc.docx`: Word reference document for DOCX output styling
- `ref_doc_w.docx`: Alternative Word reference document (wider format)
