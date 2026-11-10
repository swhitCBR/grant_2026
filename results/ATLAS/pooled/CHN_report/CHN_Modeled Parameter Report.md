Modeled Parameter Report

Estimates:

Log Likelihood: -11.5055

Num Parameters: 5

AIC: 33.0109

Paired Survival:

|   |   |   |
|---|---|---|
||Estimate|s.e.†|
|Paired Survival:|0.7936|0.018032|

Survival Detail for Fitted Model:

|   |   |   |
|---|---|---|
||Release to Lower Ringold|   |
||Estimate|s.e.†|
|Rock Island Tailrace CHN|0.7252|0.014468|
|Priest Rapids Tailrace CHN|0.9138|0.009940|

Capture Detail for Fitted Model:

|   |   |   |   |   |
|---|---|---|---|---|
||Lower Ringold|   |Hanford Survival*Capture|   |
||Estimate|s.e.*|Estimate|s.e.*|
|Rock Island Tailrace CHN|0.9985|0.001457|0.9928|0.003229|
|Priest Rapids Tailrace CHN|1.0000|0.000000|0.9807|0.005075|

Notes:

* Standard error is based on only the inverse Hessian.

† Standard error is based on bootstrapping.

Configuration:

|                                                 |                                                                    |
| ----------------------------------------------- | ------------------------------------------------------------------ |
| Dataset                                         | COMB_REL_lrg_hanf_pooled_ATLAS_nobins                              |
| Tag Life Curves                                 | Bin 1 / Pooled_taglife; Weibull 2-parameter, 68 truncated at 68.98 |
| Groups                                          | R1: Rock Island Tailrace CHN                                       |
| R2: Priest Rapids Tailrace CHN                  |                                                                    |
| Active Detection Sites                          | A0: Lower Ringold                                                  |
| A1: Hanford                                     |                                                                    |
| Optimizer                                       | Fletch, maxIterations=200, stepSize=1e-06, precision=1e-06         |
| Number of Variance Bootstrap Iterations         | 10000                                                              |
| Survival parameters logististically constrained | none                                                               |
| Capture parameters fixed at 1.0                 | R2_Lower Ringold                                                   |
| First common survival site                      | NA                                                                 |
| First common capture site                       | NA                                                                 |
| Final product parameters                        | unique                                                             |