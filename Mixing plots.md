
**Preparing for 1st mixing plot**

1) In tagpro
	- set Data Folder: C:/repos/grant_2026/data/clean/pre_tagpro
	- C:/repos/grant_2026/data/clean/post_tagpro
		- same as path used for assumption checking: 
	- in "Releases" tab
		- ![[Pasted image 20261015085802.png]]
- in "Sites" tab
		- ![[Pasted image 20261015085857.png]]
- back to "Data" tab
	- Click "add run" 
	-  Named file "COMB_REL_lrg_hanf_pooled"
	- in Add Run D![[Pasted image 20261015090856.png]]
	- In Sites Definition
	- ![[Pasted image 20261015090946.png]]
	- ![[Pasted image 20261015091038.png]]
	- Click "Run" (Gear button)
		- Status log says "Wrote 6568 rows"
- In ATLAS
	- go to "paired release" study design
	- ![[Pasted image 20261015092147.png]]
	- Load capture histories
	- In Define release group. Selecting Chinook first
	- ![[Pasted image 20261015093400.png]]
	- Select Downstream sites shows (Require displayed on hover for both)
	- ![[Pasted image 20261015092646.png]]
	- Adding Pooled taglife Weibull 2 with 68 censored tags![[Pasted image 20261015091218.png]]
	- Click "Load Capture Histories"
		- 




![[Pasted image 20261015093128.png]]



- You would have to make a virtual release using what tagpro gives you 
	-
	- 
	- 

Opening Tagpro
C:/repos/grant_2026/data/clean/pre_tagpro




![[Pasted image 20261014150355.png]]
wanto

In Tagpro



1) Live fix mixing plot

Live fish Mixing plots
- Checking mixing for Live fish in Atlas
	- I have to put in the offset value
		- RICH: I think it's an average
			- It is probably close to 72 hours
			- the other group
		- RAB:
			- R2 tags will be much sooner if you don't do a offset
			- What is the average difference betweenthem
			**Do the replicate averages**
not using the travel time data but the release time 
difference in release time at the replicate level 
average release time delay at the replicate level

compute the offsets by replicate
weighted average

# once you have those 
Weibull-2 68 tags removed
taglife functions 4 plots total 

The timing of live fish release with crosses marking dead fish release. All fish assumed alive
Shows the number of of live fish detected each day 

Priest rapids tailrace
Timing of dead fish released at priest rapids

only concerned with the timing for fish reeased at rock island
- Figure 3.4 taglife vs. arrival distribution
![[Pasted image 20261014152811.png]]

Only those fish that were released upstream 

![[Pasted image 20261014152907.png]]
V1 is virtual dead fish release
D1 is dead fish release

snd R2
put all of the pooled data into atlas
pooled data
hanford and lower ringold


- Probability of an acoustic tag being active when smolts arrive at low ringold and hanford
- Table 3.3
	- output from atlas
	- it is t
- Look for PIT tag detections of fish not detected downstream
we off set computed for each replicate and zwe 
The final estimate is a replicate level weighted average
weighted average




CLICK THROUGH ALL THAT STUFF

Only use the survival use= TRUE

