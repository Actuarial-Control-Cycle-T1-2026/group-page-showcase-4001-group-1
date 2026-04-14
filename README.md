[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/FxAEmrI0)
# SOA Case Competition: Policy Proposals for Cosmic Quarry Mining Operations

By Chloe Seu, Joy Zhang, Lachlan Liu, Maria Jang and Min-Suh Park

---

## Table of Contents
1. [Product Design](#product-design)
2. [Modelling Methodology](#modelling-methodology)
3. [Key Assumptions](#key-assumptions)
4. [Aggregate Loss, Returns and Net Revenue](#aggregate-loss,-returns-and-net-revenue)
5. [Stress Testing and Scenario Testing](#stress-testing-and-scenario-testing)
6. [Risk Assessment](#risk-assessment)
7. [Data Limitations](#data-limitations)
8. [Conclusion](#conclusion)

---

## Product Design
Premiums are paid to Galaxy General Insurance Company annually at the beginning of each year, starting from 2175. Claims are settled annually at the end of each year, with claims arising in 2175 paid in January 2176. The short-term policy has a duration of one year, while the long-term policy spans ten years, with final claims paid in January 2186. 

### Cargo Loss   

The cargo loss product follows an indemnity-based benefit structure, where the insurer reimburses the value of cargo lost or damaged, up to the declared cargo value, ensuring claims are capped to prevent overcompensation. Cargo loss insurance covers goods transported via road, sea, air and rail with payouts triggered by loss, damage or delay from unforeseen events during transit. Key triggers include transport accidents such as collisions and overturning, particularly on high debris routes, as well as theft, hijacking and piracy for high-value cargo and high-risk routes (GSK Insurance, 2023). Environmental triggers include severe weather (e.g. floods, bushfires) and exposure to extreme conditions such as high solar radiation. Coverage also extends to accidental damage during handling, including loading and unloading of cargo. The policy excludes losses arising from improper packaging or storage, as these are preventable and are due to the failure to adhere to safe practices. This also excludes litigation expenses where the conveyance is unauthorised to drive or is driving under the influence (National Transport Insurance, 2023). A flexible risk factor is applied to each solar system during pricing, allowing the product to adapt as risk levels change over time. Bayesia System has the lowest risk due to reliable communication and well-mapped asteroid routes. This is followed by Helionis Cluster, with moderate risk from asteroid clusters and navigation challenges. Oryn Delta has the highest risk due to weak signals and low visibility which directly threaten communication and safe transportation. The product uses pricing parameters to ensure scalability based on expected cargo volume by solar system, while maintaining adaptability to adjustments in navigation systems, safety features and environmental conditions through the risk factor. 

### Equipment Failure   

To protect against the financial impact of mechanical and operational breakdowns across mining equipment, the product is designed as an indemnity-based cover. Given the modelling of equipment-related claims showing high frequency with moderate severity, the benefit structure covers repair and replacement costs subject to policy limits and deductibles to manage attritional losses. A tiered coverage structure is incorporated to offer varying levels of protection, ranging from basic repair only cover to comprehensive replacement and downtime cover. Coverage is triggered by unforeseen and sudden equipment failure during operation with triggers linked to key risk drivers used in modelling.  Coverage is subject to compliance with prescribed operational standards differentiated by solar systems such as radiation hardening certified equipment in the Bayesia system and reporting gravitational shear zones in Oryn Delta. Deductibles are structured to reduce the frequency of minor claims on Helionis Cluster where debris-related damage is much more frequent. This structure allows the policy to be tailored to operational differences across solar systems and varying risk profiles.  

Exclusions apply to losses arising from inadequate or delayed maintenance, operational misuse or operating outside of implied thresholds, or gradual wear and tear, ensuring consistency with underwriting assumptions and mitigating moral hazard. Severe stellar flare events or large-scale gravitational disturbances are also subject to exclusions or coverage limits. To reflect the differing operational environments across the Helionis Cluster, Bayesia system and Oryn Delta, product parameters on pricing are derived from these system-specific risk profiles whilst also incorporating exposure-based pricing linked to the quarry’s equipment volume and productivity growth to account for the company’s plans for enlarged scalability. Adaptability through flexible index factors can be adjusted in response to evolving technological advancements, maintenance standards and environmental conditions.  

### Worker Compensation   

The workers compensation product provides comprehensive protection against accidents, injuries, and illnesses which arise out of and in the course of employment, consistent with established workers compensation systems (Knoblauch, 2023).  With the support of automated technology like Interplanetary Claims Grid and Q-RISK Engine for efficient claims management and accurate risk assessment, the benefit structure is based on the extent of incapacity and recovery requirements, ensuring flexibility across a wide range of injury outcomes. This includes full coverage of medical, hospital and rehabilitation expenses, weekly wage replacement proportional to lost earning capacity during periods of incapacity, and additional compensation for permanent impairment or fatal outcomes (SIRA, 2025). Coverage is triggered when an injury or illness arises out of employment, including workplace accidents, hazardous environmental exposure, and operational incidents, reflecting the standard no-fault principle underpinning workers’ compensation schemes (Knoblauch, 2023). To mitigate cases of moral hazard, exclusions apply to non-work-related injuries, intentional harm, fraudulent claims, and incidents resulting from failure to comply with mandated safety protocols and meet a certain level of safety training and protective gear quality. A system-specific loading factor is applied to reflect differing operational risks across solar systems, with Helionis receiving the lowest loading due to established and predictable conditions, Bayesia System a moderate loading due to environmental stresses such as radiation and temperature extremes, and Oryn Delta the highest loading due to poor infrastructure and heightened uncertainty, allowing for recalibration with evolving hazard conditions, data documentation, and infrastructure. Claim losses are simulated based on the insurer’s current company size, allowing the model to be recalibrated as the company grows, ensuring pricing remains accurate and proportionate as workforce scale and operational footprint increase over time. 

### Business Interruption    

For the business interruption hazard area, a loss of gross profit benefit structure is being adopted, payments will be made throughout an indemnity period, closely reflecting the actual financial impact of disruptions. Given the extreme volatility of mining yields in the interstellar setting, this benefit structure was chosen as it provides flexibility and reduces the risk of material under/over compensation compared to fixed sum insured benefit structures. Coverage is triggered by defined interruption events that halt or materially reduce operations. Triggers can be categorised as internal hazards such as mechanical failure of critical extraction equipment, transport vessel breakdowns and external hazards such as meteorite impacts or solar radiation storms. Catastrophic incidents such as explosions stemming from equipment failure are also covered in this hazard area. However, the policy will incorporate exclusions to manage moral hazard and uninsurable risks. Similarly to the exclusions covered in equipment failure, claims cannot be made if halt in production is due to gradual wear and tear, lack of maintenance or known design defects. Interruptions caused by regulatory breaches, warlike or politically motivated acts and insolvency of the insured are also critical exclusions in this hazard area. Furthermore, coverage excludes losses stemming from predictable environmental conditions inherent to specific mining zones where adequate mitigation measures were not implemented. 

## Modelling Methodology

### Workers Compensation (Code can be accessed from [WorkersCompensation/](WorkersCompensation)!)
#### Data Cleaning: 
- Cleaned corrupted text entries (e.g. Drill Operator_???2905) by removing the sequence after and including  _???
- Converted variables into appropriate types (numeric vs factor)
- Filtered observations based on valid ranges for numerical variables (eg. experience years 0.2–40)
- Restricted categorical variables to allowed levels (eg. safety training index to levels 1-5)
- Removed missing values

#### Frequency modelling:
- Started with the Poisson GLM with full covariate set and log(exposure) offset — preferred for interpretability compared to accuracy.
- Overdispersion computed to assess Poisson adequacy; Negative Binomial is not necessary.
- However, Negative Binomial was also fitted as a robustness check.
- Each model was refined using stepwise selection, evaluated using cross-validation and compared using AIC and RMSE metrics to select the optimal model.
- Each model was checked and adjusted for correlated covariates through VIF measuring the level of multicollinearity among predictors.
- Final Model: step-wise Poisson Model

#### Severity modelling:
- Compared models Gamma, Lognormal and Weibull models considering the positive and heavily right skewed claim amounts.
- Each model was refined using stepwise selection, evaluated using cross-validation and compared using AIC, RMSE and MAE metrics.
- Each model was checked and adjusted for correlated covariates through VIF measuring the level of multicollinearity among predictors.
- Final model: step-wise Lognormal

#### Monte-Carlo Simulation
- Claim counts are simulated using the Poisson distribution
- Frequency is adjusted according to employee distribution for occupations using the data from srcsc-2026-cosmic-quarry-personnel
- Claim severities are simulated using the log-normal distribution
- Severity is adjusted according to average salaries for occupations using the data from srcsc-2026-cosmic-quarry-personnel
- Claims are simulated across all current employees and occupations
- Aggregated total losses per simulation through claim count * claim severity
- 100,000 simulations run to obtain a loss distribution

## Key Assumptions 
- Claim events are assumed independent, simplifying modelling and simulation processes.
- Historical claim severity is capped at the 99.5th percentile to reduce impacts of extreme outliers.
- The relationship between risk factors and claim outcomes is assumed consistent across solar systems.
- Expense, profit and risk margins are applied as a percentage loading to expected losses.
- The Risk Index derived from quarry inventory data reflects underlying environmental risks in each solar system, independent of productivity risk. 

## Aggregate Loss, Returns and Net Revenue
Aggregate Loss...

<p align="center">
<img width="752" height="258" alt="Screen Shot 2026-04-12 at 9 54 42 pm" src="https://github.com/user-attachments/assets/3ebff707-1bf2-4fcf-81c9-a8a6101035df" />

Returns and Net Revenue...

<p align="center">
<img width="758" height="276" alt="Screen Shot 2026-04-12 at 9 55 34 pm" src="https://github.com/user-attachments/assets/c33cddb0-c607-4fa8-9533-00a157923c8c" />


## Stress Testing and Scenario Testing

## Risk Assessment

## Data Limitations
- Data cleaning was not expected to materially bias the results. 
- Historical datasets were drawn from a different set of solar systems than those being modelled (Helionis Cluster, Bayesia System and Oryn Delta), leading to potentual structural differences, particularly under extreme conditions.
- The lack of clear quantitative distinctions between solar systems in quarry personnel meant an exposure index could not be constructed, so it was proposed that an arbitrary loading factor be applied with Helionis Cluster acting as the benchmark.
- The historical cargo loss data lacked clear distinctions between solar systems, limiting the model's ability to capture structural differences beyond qualitative adjustments. 

## Conclusion
The final report can be found [here](https://github.com/Actuarial-Control-Cycle-T1-2026/group-page-showcase-4001-group-1/blob/main/ACTL4001%20Report.pdf).


![](Actuarial.gif)
