CBR report that uses Fulton's condition factor
https://www.cbr.washington.edu/sites/default/files/papers/PNWD-4283_Differential_Delayed_Mortality_Final_Report_Appendices.pdfv

August 2026 PNNL report
https://www.pnnl.gov/main/publications/external/technical_reports/PNNL-39086.pdf

paper that seems to use a cube-root transofrmation to model egg weight increase
https://besjournals.onlinelibrary.wiley.com/doi/10.1111/j.1365-2435.2010.01790.x

"In addition the data of weight increase were linearized by cube root transformation. This transformation accounts for the relationship between size and weight which in fish generally has the form weight = _a_ × length3 (with _a_ being a scaling constant). The initial model used to analyse length and weight growth trajectories was ‘food treatment × egg size class × experimental day × experimental day2’. All behavioural data were analysed using GLMM. For the GLMMs we used the MASS package and the models were fitted with the glmmPQL function."

# The origin of Fulton's condition factor - Setting the record straight
https://www.researchgate.net/publication/233388972_The_origin_of_Fulton's_condition_factor_-_Setting_the_record_straight


FSA R package for looking up relative weight (W_r)
https://fishr-core-team.github.io/FSA/articles/Computing_Relative_Weights.html#calculate-relative-weights-for-all-of-one-species

Fish condition was indexed using a measure that assumes an allometric pattern of growth:
$$
 \text{Condition}=\frac{10 \times \text{Weight(g)}^{1/3}}{\text{Length(mm)}},
$$
where weight and length scale cubically and $10$ is an arbitrary scalar that ensures that values are between 0-1.







$$
 \text{Condition}=\frac{10 \times \sqrt[3]{\text{Weight}}}{\text{Length}}
$$


The "Fulton-type condition factor" from Anderson and Guteuter (1983).
$$
 \text{Condition}=\frac{\text{Weight}}{\text{Length}^3}\times C,
$$
where $C$ is a scaling constant that varies based on units of measure and is usually set so that values fall close to 1.0. A specific equation that has been applied to juvenile salmon is: 

$$
 \text{Condition}=\frac{\text{Weight(g)}}{\text{Fork Length(mm)}^3}\times 100,000
$$

Anderson, R., and S. J. Gutreuter. 1983. Length, weight, and associated structural indices.  In: Nielsen, L.A. and Johnson, D.L., Eds., Fisheries Techniques, American Fisheries Society, Bethesda, 283-300.



https://cdnsciencepub.com/doi/full/10.1139/F10-080

