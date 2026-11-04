
select paired release
![[Pasted image 20261103094808.png]]

All the files used are in this directory
 ![[Pasted image 20261103095116.png]]
 - Click on "Load Capture Histories" and then select COMB_REL_lrg_hanf_pooled_ATLAS.csv
 - Clicked "View Mixing" and added 72 hours for now
 - Click on "Define Release Groups" and figure out a proper species


## Steelhead
 - Here's the configuration for steelhead
 - ![[Pasted image 20261103095431.png]]
 - Click "Load Attributes" and select "new_rep_ID_attrib_ATLAS.csv"
 - Clicking "Select Attributes" reveals the replicate IDs
 - ![[Pasted image 20261103095855.png]]
 - Click "Load Taglife Data" and select "Pooled_taglife.csv"
 - set the model to Weibull 2 with 68 tags "truncated"
 - ![[Pasted image 20261103100313.png]]
 - Double-click "Tag Life Corrections" and select 10000
 - Double click "View Tag Life Corrections"
    - save to "analysis/pooled/STH_Tag Correction Report"
 - Here's the correction table
 - ![[Pasted image 20261103100757.png]]
- Weibull-2 parameters

| Param  | Est (SE)           |
| ------ | ------------------ |
| shape: | 5.15482 (0.875609) |
| scale: | 83.2426 (4.06419)  |
- Double click (Constrain Parmeters)
- ![[Pasted image 20261103101010.png]]
- 
- Click to constrain the priest rapids capture probability for R2 and then hit "apply"
- ![[Pasted image 20261103101037.png]]
- Click "Compute"
- Double click "Compute Full Variance" and enter 10000
- Double Click "Parameter Estimates"
    - save to "analysis/pooled/STH_Modeled Parameter Report"
- Click on "Generate report"
![[Pasted image 20261103101953.png]]

### Replicate-level steelhead

- Looking at "media\xlsx\replicate_regrouping\SW_replicate_level_DH_counts_11_1_26.xlsx"
    - the STH_20_21_22 replicate is the only one with Rock Island 01 & 1 histories
    - Click "Select Attributes"
    - Uncheck "Select All" then select STH_20_21_22 and hit "apply"
    - ![[Pasted image 20261103102836.png]]

    - Click "Calculate Tag Life Corrections" with 10000
    - Double click "compute"
    - Creating director to report new values
    ![[Pasted image 20261103103236.png]]
    reduce the total outputs for the replicate level![[Pasted image 20261103103304.png]]

- I've grouped the release groups based on non-zero cells
- ![[Pasted image 20261103104338.png]]
- Click "Select Attributes" and then choose STH_1
- Click "Calculate Tag Life Corrections" causes error
- ![[Pasted image 20261103104537.png]]
- Click Constrain Paramters
 ![[Pasted image 20261103104618.png]]
 Fixing R1
![[Pasted image 20261103104655.png]]
- Click "apply"
- Click "Compute"

RESTARTED ATLAS
Created "COMB_REL_lrg_hanf_pooled_ATLAS_nobins.csv"
- bins column replaced by all "1" instead of "1","2","3"
- Selected STH_1 and was able to rerun comp


- Moving on to spp=STH and repID=3
- Changed to STH_3 attributes
- Calculated tag corrections
- Hit "Compute"
- Hit "Full Variance"
- Export reports
- worked for all these
![[Pasted image 20261103111448.png]]


Starting a new round with STH_6

![[Pasted image 20261103111655.png]]
looking at contraint

![[Pasted image 20261103111548.png]]
![[Pasted image 20261103111620.png]]
![[Pasted image 20261103111655.png]]

Moving on to next set of estimates 
![[Pasted image 20261103112513.png]]
Staring the STH_2
Constraint decisions
![[Pasted image 20261103112602.png]]![[Pasted image 20261103112623.png]]

### **PROBLEM GROUPING (STH)**
Final grouping
![[Pasted image 20261103113651.png]]
Looking at constraints
![[Pasted image 20261103113804.png]]
![[Pasted image 20261103113820.png]]

(Looking at fixing some variables)
![[Pasted image 20261103113845.png]]
When I click "compute" after applying these constraint I get 

![[Pasted image 20261103115139.png]]



# Chinook

- Release location
![[Pasted image 20261103121436.png]]
- Constraining 
![[Pasted image 20261103121601.png]]

- 2nd set of models

![[Pasted image 20261103122609.png]]
![[Pasted image 20261103122722.png]]
- 3rd set of models
![[Pasted image 20261103123052.png]]
![[Pasted image 20261103123210.png]]

- 4th set of models
![[Pasted image 20261103124448.png]]
![[Pasted image 20261103124608.png]]

5th model set set (one model)
![[Pasted image 20261103125158.png]]
- unconstraining capture
![[Pasted image 20261103125253.png]]
- constraining survival
![[Pasted image 20261103125346.png]]

6th model set
![[Pasted image 20261103125554.png]]

unconstraining survival
![[Pasted image 20261103125700.png]]
reconstraining capture probability
![[Pasted image 20261103125644.png]]
last model set
![[Pasted image 20261103130349.png]]
added constraint
![[Pasted image 20261103130456.png]]
unchanged
![[Pasted image 20261103130520.png]]
![[Pasted image 20261103130552.png]]

Trying out
![[Pasted image 20261103130721.png]]
