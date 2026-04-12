[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/FxAEmrI0)
# SOA Case Competition: Policy Proposals for Cosmic Quarry Mining Operations

By Chloe Sue, Joy Zhang, Lachlan Liu, Maria Jang and Min-Suh Park

---

### Our finalised team report can be found here: [Final report](https://www.soa.org/research/opportunities/2026-student-research-case-study-challenge/)!
### Summary

> Now it's time to build your own website to showcase your work.  
> Creating a website using GitHub Pages is simple and a great way to present your project.

This page is written in Markdown.
- Click the [assignment link](https://classroom.github.com/a/FxAEmrI0) to accept your assignment.

---

### Product Design

### Methodology of our Model

#### Workers Compensation
##### Data Cleaning: 
- Cleaned corrupted text entries (e.g. Drill Operator_???2905) by removing the sequence after and including  _???
- Converted variables into appropriate types (numeric vs factor)
- Filtered observations based on valid ranges for numerical variables (eg. experience years 0.2–40)
- Restricted categorical variables to allowed levels (eg. safety training index to levels 1-5)
- Removed missing values

##### Frequency modelling:
- Started with the Poisson GLM with full covariate set and log(exposure) offset — preferred for interpretability compared to accuracy.
- Overdispersion computed to assess Poisson adequacy; Negative Binomial is not necessary.
- However, Negative Binomial was also fitted as a robustness check.
- Each model was refined using stepwise selection, evaluated using cross-validation and compared using AIC and RMSE metrics to select the optimal model.
- Each model was checked and adjusted for correlated covariates through VIF measuring the level of multicollinearity among predictors.
- Final Model: step-wise Poisson Model

##### Severity modelling:
- Compared models Gamma, Lognormal and Weibull models considering the positive and heavily right skewed claim amounts.
- Each model was refined using stepwise selection, evaluated using cross-validation and compared using AIC, RMSE and MAE metrics.
- Each model was checked and adjusted for correlated covariates through VIF measuring the level of multicollinearity among predictors.
- Final model: step-wise Lognormal

##### Monte-Carlo Simulation
- Claim counts are simulated using the Poisson distribution
- Frequency is adjusted according to employee distribution for occupations using the data from srcsc-2026-cosmic-quarry-personnel
- Claim severities are simulated using the log-normal distribution
- Severity is adjusted according to average salaries for occupations using the data from srcsc-2026-cosmic-quarry-personnel
- Claims are simulated across all current employees and occupations
- Aggregated total losses per simulation through claim count * claim severity
- 100,000 simulations run to obtain a loss distribution

### Assumptions and Data Limitations

### Aggregate Loss, Returns and Net Revenue
Aggregate Loss...

<img width="752" height="258" alt="Screen Shot 2026-04-12 at 9 54 42 pm" src="https://github.com/user-attachments/assets/3ebff707-1bf2-4fcf-81c9-a8a6101035df" />

Returns and Net Revenue...

<img width="758" height="276" alt="Screen Shot 2026-04-12 at 9 55 34 pm" src="https://github.com/user-attachments/assets/c33cddb0-c607-4fa8-9533-00a157923c8c" />



### Stress Testing and Scenario Testing

### Risk Assessment

### Conclusion


> Be creative! You can embed or link your [data](player_data_salaries_2020.csv), [code](sample-data-clean.ipynb), and [images](ACC.png) here.

More information on GitHub Pages can be found [here](https://pages.github.com/).

![](Actuarial.gif)
