Tag Correction Report

Detection Site Key:

|   |   |
|---|---|
|A1:|Lower Ringold|
|A2:|Hanford|

  

|   |   |   |   |   |
|---|---|---|---|---|
|Release|   |   |Detection Sites|   |
|Group|Site|Bin|A1|A2|
|R1|Rock Island Tailrace STH|1|0.9985 (0.001473)|1.0000 (0.001475)|
|2|1.0000 (0.001459)|0.9995 (0.001480)|
|3|1.0000 (0.001465)|1.0000 (0.001471)|
|R2|Priest Rapids Tailrace STH|1|0.9999 (0.001232)|0.9999 (0.001255)|
|2|0.9999 (0.001242)|0.9999 (0.001260)|
|3|0.9999 (0.001249)|0.9999 (0.001275)|

  

Tag Life Dataset: Pooled_taglife

|   |   |
|---|---|
|Fit Curve:|Weibull 2-parameter|
|Truncations:|68 at 68.98|
|Log-Likelihood:|-174.0116|
|Bootstrap iterations:|10000|

Parameters:

|   |   |
|---|---|
|shape:|5.15482 (0.875609)|
|scale:|83.2426 (4.06419)|

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
|Survival parameters logististically constrained|none|
|Capture parameters fixed at 1.0|none|
|First common survival site|NA|
|First common capture site|NA|
|Final product parameters|unique|