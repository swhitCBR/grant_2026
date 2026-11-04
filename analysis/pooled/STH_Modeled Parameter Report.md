Modeled Parameter Report

Estimates:

Log Likelihood: -32.2374

Num Parameters: 5

AIC: 74.4747

Paired Survival:

|   |   |   |
|---|---|---|
||Estimate|s.e.†|
|Paired Survival:|0.7504|0.021833|

Survival Detail for Fitted Model:

|   |   |   |
|---|---|---|
||Release to Lower Ringold|   |
||Estimate|s.e.†|
|Rock Island Tailrace STH|0.6549|0.016678|
|Priest Rapids Tailrace STH|0.8728|0.012706|

Capture Detail for Fitted Model:

|   |   |   |   |   |
|---|---|---|---|---|
||Lower Ringold|   |Hanford Survival*Capture|   |
||Estimate|s.e.*|Estimate|s.e.*|
|Rock Island Tailrace STH|0.9981|0.001886|0.9806|0.005802|
|Priest Rapids Tailrace STH|1.0000|0.000000|0.9708|0.006775|

Notes:

* Standard error is based on only the inverse Hessian.

† Standard error is based on bootstrapping.

Configuration:

|   |   |
|---|---|
|Dataset|COMB_REL_lrg_hanf_pooled_ATLAS|
|Tag Life Curves|Bin 1 / Pooled_taglife; Weibull 2-parameter, 68 truncated at 68.98|
|Bin 2 / Pooled_taglife; Weibull 2-parameter, 68 truncated at 68.98|
|Bin 3 / Pooled_taglife; Weibull 2-parameter, 68 truncated at 68.98|
|Groups|R1: Rock Island Tailrace STH|
|R2: Priest Rapids Tailrace STH|
|Active Detection Sites|A0: Lower Ringold|
|A1: Hanford|
|Optimizer|Fletch, maxIterations=200, stepSize=1e-06, precision=1e-06|
|Number of Variance Bootstrap Iterations|10000|
|Survival parameters logististically constrained|none|
|Capture parameters fixed at 1.0|R2_Lower Ringold|
|First common survival site|NA|
|First common capture site|NA|
|Final product parameters|unique|