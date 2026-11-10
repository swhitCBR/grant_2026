# CHN_9

set optimizer
![[Pasted image 20261106122527.png]]

loading
COMB_REL_lrg_hanf_pooled_ATLAS_nobins.csv
![[Pasted image 20261106122633.png]]

load attributes
new_rep_ID_attrib_ATLAS.csv

Adding taglife data and fitting weibull-2

run "Calculate Tag Life Corrections"

Constrain
![[Pasted image 20261106122837.png]]
Compute
Back to Select Attributes
![[Pasted image 20261106122950.png]]
Calculate Tag Life Correction
Contraining
![[Pasted image 20261106123036.png]]
Compute
uncheck CHN_20
![[Pasted image 20261106123123.png]]
Calculate Tag Life Correction
Compute (failed)
Constrain Params
![[Pasted image 20261106123219.png]]
Compute
Compute Full Variance
![[Pasted image 20261106123251.png]]

# STH_4

Select Release Site Roles
![[Pasted image 20261106123443.png]]
select attributes
![[Pasted image 20261106123514.png]]

Calculate Tag Life Correction
Compute
Compute Full Variance

![[Pasted image 20261106123651.png]]