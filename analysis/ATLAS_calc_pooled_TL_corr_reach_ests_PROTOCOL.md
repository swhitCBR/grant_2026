
accessing release-site specific BRZ-site based pooled ATLAS Data (not tagger specific) data sets

load rock island data 
C:\repos\grant_2026\data\clean\post_tagpro\RI_BRZsel_ATLAS.csv
DO NOT PICK: RI_all_sites_MOD_ATLAS.csv

# Rock Island
## Chinook

![[Pasted image 20261109115034.png]]

Loading taglife data from: C:\repos\grant_2026\data\Nov_run\Pooled_taglife.csv

fit weibull-2 model 
calculate tag life corrections

Constrain parameters
![[Pasted image 20261109115705.png]]
fixing some probabilities
![[Pasted image 20261109115724.png]]
it compute and it did not work


Tried manually subsetting and creating
PR_BRZsel_ATLAS_nov_edit.csv
RI_BRZsel_ATLAS_nov_edit.csv

**Retry with single release selected**

Selected "Single Release"
selected actual
![[Pasted image 20261109120541.png]]
rock island CHN to start
![[Pasted image 20261109120632.png]]

![[Pasted image 20261109120740.png]]
Compute
Compute Full Variance

created directory for reports
![[Pasted image 20261109121031.png]]


![[Pasted image 20261109121058.png]]

Going up to "Define Release Groups"
![[Pasted image 20261109121228.png]]
Opening C:\repos\grant_2026\data\clean\post_tagpro\RI_BRZsel_ATLAS.csv again

![[Pasted image 20261109121347.png]]
Constraining some paramters
![[Pasted image 20261109121458.png]]
![[Pasted image 20261109121601.png]]
# Priest Rapids
PR_BRZsel_ATLAS.csv

![[Pasted image 20261109121730.png]]
Contraining some
![[Pasted image 20261109121820.png]]
Switched release group to STH
![[Pasted image 20261109122000.png]]