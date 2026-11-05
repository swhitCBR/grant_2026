

### input
C:/repos/grant_2026/data/clean/pre_tagpro

### output
C:/repos/grant_2026/data/clean/post_tagpro



press "Load"

in "Releases" tab, select all four
click "Bulk Add"

in "Sites" tab, 
![[Pasted image 20260920153612.png]]

select all "Bulk Add"

in "Data" tab, click "Add Run"

enter "RI_all_sites"

in "Release Group Selection", click two Rock Island sites and click "Next"
Select all and click next


in "Data" tab, click "Add Run"

enter "PR_all_sites"
in "Release Group Selection", click two Priest Rapids and click "Next"
in Sites Definition selector pick "Lower Ringold" and "Hanford" 


## Now look only at a subset of sites
everything else the same

![[Pasted image 20260920154543.png]]

![[Pasted image 20260920154825.png]]

## NOTE: release group selection for the BRZsel runs
In the "BRZsel" runs, the `PR_BRZsel` run must select **only the two Priest Rapids release groups**
(Chinook and steelhead), and `RI_BRZsel` only the two Rock Island groups, exactly as for the
all_sites runs. On 2026-11-04 `PR_BRZsel_ATLAS.csv` was found to contain all four release groups
(identical to `COMB_REL_lrg_hanf_pooled_ATLAS.csv`). It was filtered to the Priest Rapids rows; the
original is in `data/clean/post_tagpro/old/PR_BRZsel_ATLAS_with_RI_rows_BACKUP_2026-11-04.csv`.
