[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/FxAEmrI0)
# SOA Case Competition: Policy Proposals for Cosmic Quarry Mining Operations

By Chloe Seu, Joy Zhang, Lachlan Liu, Maria Jang and Min-Suh Park

---

## Table of Contents
1. [Product Design](#product-design)
2. [Modelling Methodology](#modelling-methodology)
3. [EPV Loss, Returns and Net Revenue Calculation Method](#epv-loss-retuns-and-net-revenue-calculation-method)
4. [Key Assumptions](#key-assumptions)
5. [Aggregate Loss, Returns and Net Revenue](#aggregate-loss-returns-and-net-revenue)
6. [Scenario and Stress Testing](#scenario-and-stress-testing)
7. [Risk Assessment](#risk-assessment)
8. [Data Limitations](#data-limitations)
9. [Final Report](#final-report)

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



### Cargo Loss (Code can be accessed from [CargoLoss/](CargoLoss)!)
#### Data Cleaning: 
- Cleaned corrupted text entries (e.g. Policy ID_???9113) by removing the sequence after and including  _???
- Converted variables into appropriate types (numeric vs factor)
- Filtered observations based on valid ranges for numerical variables (eg. weight 1.5K-250K)
- About 10% of claim_amount values were outside the range where most were less than the minimum range, so I set the lower bound at the 0.5% quantile
- Restricted categorical variables to allowed levels (eg. route risk to levels 1-5)
- Removed missing numerical values and assigned "Unknown" value to missing categorical variables

#### Frequency modelling:
- Started with the Poisson GLM with full covariate set and log(exposure) offset — preferred for interpretability compared to accuracy.
- The presence of overdispersion indicated that Negative Binomial was the better model.
- The Poisson GLM was still used to conduct a robustness check
- To address multicollinearity, transit_duration was removed and distance was retained based on comparative model performance.
- Each model was compared using AIC, BIC and RMSE metrics to select the optimal model.
- Final Model: Negative-Binomial Model

#### Severity modelling:
- Compared models Gamma and Lognormal models considering the positive and heavily right skewed claim amounts.
- To address multicollinearity, transit_duration was removed and distance was kept.
- Each model was compared using AIC, BIC and RMSE metrics.
- Final model: Lognormal Model

#### Monte-Carlo Simulation
- Claim counts are simulated using the Negative-Binomial distribution
- Frequency is adjusted according to total cargo volume and cargo distribution across different solar systems using data from srcsc-2026-cosmic-quarry-inventory
- Claim severities are simulated using the log-normal distribution
- Severity is adjusted according to average claim amount from the historical datasheet
- Claims are simulated across all current cargo types and volume
- Aggregated total losses per simulation through claim count * claim severity
- 100,000 simulations run to obtain a loss distribution


## EPV Loss, Returns and Net Revenue Calculation Method
#### EPV Loss
- Expected Present Value of Loss was calculated by the summation of all cashflows projected using inflation rates and discounted back by interest rates
  - The inflation rate was determined by finding the historical average across all years
  - The short-term interest rate was determined by finding the historical average of 1 year spot rate
  - The long-term interest rate was determined by finding the historical average of 10 year spot rate
<img width="629" height="163" alt="Screen Shot 2026-04-15 at 12 38 00 pm" src="https://github.com/user-attachments/assets/35aaa18f-20b3-4db1-8c89-f8c1a20a30bc" />

#### Returns and Net Revenue
- Returns was defined as the premium calculated by summing the EPV Loss with additional considerations of the following margins; risk, expense and profit margin
- Based on the industry average, the expense margin set as 20% and profit margin as 8%
- The risk margin was calculated by multiplying a risk factor of k to the standard deviation of the loss distribution
  - Hazards with the highest risk were assigned the largest risk factor
  - Risk factor k: Cargo = 2, Business Interruption = 1.75, Workers Compensation = 1.5, Equipment Failure = 1.25
<img width="739" height="212" alt="Screen Shot 2026-04-15 at 12 48 35 pm" src="https://github.com/user-attachments/assets/1f852f1e-cef5-45a1-9362-451a09e81fca" />

## Key Assumptions 

- Claim events are assumed independent, simplifying modelling and simulation processes.
- Historical claim severity is capped at the 99.5th percentile to reduce impacts of extreme outliers.
- The relationship between risk factors and claim outcomes is assumed consistent across solar systems.
- Expense, profit and risk margins are applied as a percentage loading to expected losses.
- The Risk Index derived from quarry inventory data reflects underlying environmental risks in each solar system, independent of productivity risk. 

## Aggregate Loss, Returns and Net Revenue

### Aggregate Loss

All values are in Đ millions.

<table>
  <thead>
    <tr>
      <td>Hazard</td>
      <td>Term</td>
      <td>Expected Loss</td>
      <td>p10</td>
      <td>p90</td>
      <td>Variance</td>
      <td>VaR99</td>
      <td>TVaR99</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th rowspan = "2">Cargo Loss</th>
      <th>Short</th>
      <th>10,412.7</th>
      <th>95.5</th>
      <th>28,640.1</th>
      <th>2.48e+14</th>
      <th>75,022.6</th>
      <th>96,115.7</th>
    </tr>
    <tr>
      <th>Long</th>
      <th>101,089.3</th>
      <th>41,011.7</th>
      <th>278,045.6</th>
      <th>2.34e+16</th>
      <th>728,339.5</th>
      <th>933,116.7</th>
    </tr>
    <tr>
      <th rowspan = "2">Equipment Failure</th>
      <th>Short</th>
      <th>84.8</th>
      <th>81.0</th>
      <th>88.6</th>
      <th>8.84e+6</th>
      <th>91.8</th>
      <th>92.9</th>
    </tr>
    <tr>
      <th>Long</th>
      <th>835.8</th>
      <th>798.2</th>
      <th>873.2</th>
      <th>8.58e+8</th>
      <th>905.1</th>
      <th>915.8</th>
    </tr>
    <tr>
      <th rowspan = "2">Worker's Compensation</th>
      <th>Short</th>
      <th>4.9</th>
      <th>2.7</th>
      <th>9.1</th>
      <th>5.18e+7</th>
      <th>37.8</th>
      <th>55.1</th>
    </tr>
    <tr>
      <th>Long</th>
      <th>47.4</th>
      <th>26.3</th>
      <th>88.5</th>
      <th>4.88e+9</th>
      <th>367.4</th>
      <th>534.6</th>
    </tr>
    <tr>
      <th rowspan = "2">Business Interruption</th>
      <th>Short</th>
      <th>34,127.3</th>
      <th>33,254.6</th>
      <th>35,007.0</th>
      <th>4.62e+11</th>
      <th>35,712.8</th>
      <th>35,951</th>
    </tr>
    <tr>
      <th>Long</th>
      <th>361,832.2</th>
      <th>352579.6</th>
      <th>371,158.6</th>
      <th>5.19e+13</th>
      <th>378,642.8</th>
      <th>381,167.3</th>
    </tr>
  </tbody>
</table>

### Returns and Net Revenue

All values are in Đ millions.

<table>
  <thead>
    <tr>
      <td>Hazard</td>
      <td>Terms</td>
      <td>Returns</td>
      <td>Net Revenue</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th rowspan = "2">Cargo Loss</th>
      <th>Short</th>
      <th>58,217.8</th>
      <th>36,161.5</th>
    </tr>
    <tr>
      <th>Long</th>
      <th>565,193.6</th>
      <th>351,065.6</th>
    </tr>
    <tr>
      <th rowspan = "2">Equipment Failure</th>
      <th>Short</th>
      <th>122.9</th>
      <th>13.6</th>
    </tr>
    <tr>
      <th>Long</th>
      <th>1,211.7</th>
      <th>133.6</th>
    </tr>
    <tr>
      <th rowspan = "2">Worker's Compensation</th>
      <th>Short</th>
      <th>21.8</th>
      <th>12.6</th>
    </tr>
    <tr>
      <th>Long</th>
      <th>211.4</th>
      <th>121.7</th>
    </tr>
    <tr>
      <th rowspan = "2">Business Interruption</th>
      <th>Short</th>
      <th>49,050.4</th>
      <th>5113</th>
    </tr>
    <tr>
      <th>Long</th>
      <th>520,053</th>
      <th>54,210.4</th>
    </tr>
    <tr>
      <th rowspan = "2">Total</th>
      <th>Short</th>
      <th>107,412.9</th>
      <th>41,300.7</th>
    </tr>
    <tr>
      <th>Long</th>
      <th>521,476.1</th>
      <th>405,531.3</th>
    </tr>
  </tbody>
</table>

## Scenario and Stress Testing

### Scenario Testing

The scenario testing showed a clear and consistent increase in net revenue as both the expense loading and risk factor k increased. Higher expense loadings directly raised premiums, leading to higher net revenue across all scenarios. Similarly, increasing k scaled the risk margin based on variability, resulting in higher premiums and therefore higher net revenue for all hazard areas.

#### Short Term

<table>
  <thead>
    <tr>
      <th>Short Term</th>
      <th colspan = "5">Expense Margin as % of Premiums</th>
    </tr>
    <tr>
      <th>Risk Factor</th>
      <th>0.1</th>
      <th>0.15</th>
      <th>0.2</th>
      <th>0.25</th>
      <th>0.3</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>-0.5</td>
      <td>775,990.3</td>
      <td>780,726.9</td>
      <td>786,121.4</td>
      <td>792,321.0</td>
      <td>799,520.6</td>
    </tr>
    <tr>
      <td>-0.25</td>
      <td>966,738.4</td>
      <td>972,576.0</td>
      <td>979,224.4</td>
      <td>986,865.2</td>
      <td>995,738.2</td>
    </tr>
    <tr>
      <td>k</td>
      <td>1,157,486.6</td>
      <td>1,164,425.2</td>
      <td>1,172,327.5</td>
      <td>1,181,409.2</td>
      <td>1,191,955.9</td>
    </tr>
    <tr>
      <td>0.25</td>
      <td>1,348,234.7</td>
      <td>1,356,274.3</td>
      <td>1,365,430.6</td>
      <td>1,375,953.4</td>
      <td>1,388,173.5</td>
    </tr>
    <tr>
      <td>0.5</td>
      <td>1,538,982.8</td>
      <td>1,548,123.4</td>
      <td>1,558,533.6</td>
      <td>1,570,497.6</td>
      <td>1,584,391.1</td>
    </tr>
  </tbody>
</table>

#### Long Term

<table>
  <thead>
    <tr>
      <th>Long Term</th>
      <th colspan = "5">Expense Margin as % of Premiums</th>
    </tr>
    <tr>
      <th>Risk Factor</th>
      <th>0.1</th>
      <th>0.15</th>
      <th>0.2</th>
      <th>0.25</th>
      <th>0.3</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>-0.5</td>
      <td>8,203,260.1</td>
      <td>8,253,286.4</td>
      <td>8,310,260.9</td>
      <td>8,375,739.0</td>
      <td>8,451,778.0</td>
    </tr>
    <tr>
      <td>-0.25</td>
      <td>10,221,783.7</td>
      <td>10,283,461.2</td>
      <td>10,353,704.8</td>
      <td>10,434,432.3</td>
      <td>10,528,181.3</td>
    </tr>
    <tr>
      <td>k</td>
      <td>12,240,308.7</td>
      <td>12,313,637.0</td>
      <td>12,397,149.6</td>
      <td>12,493,126.6</td>
      <td>12,604,583.6</td>
    </tr>
    <tr>
      <td>0.25</td>
      <td>14,258,832.7</td>
      <td>14,343,811.8</td>
      <td>14,440,593.3</td>
      <td>14,551,820.8</td>
      <td>14,680,986.8</td>
    </tr>
    <tr>
      <td>0.5</td>
      <td>16,277,356.7</td>
      <td>16,373,986.6</td>
      <td>16,484,037.1</td>
      <td>16,610,514.0</td>
      <td>16,757,390.1</td>
    </tr>
  </tbody>
</table>

### Stress Testing

All values are in Đ millions.

<table>
  <thead>
    <tr>
      <td>Sum across all Hazard Areas</td>
      <td>Stress Cases</td>
      <td>Costs</td>
      <td>Returns (Premiums)</td>
      <td>Net Revenue</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan = "2">Short Term</td>
      <td>Basis</td>
      <td>44,629.7</td>
      <td>107,412.9</td>
      <td>41,300.7</td>
    </tr>
    <tr>
      <td>Extreme</td>
      <td>45,621.6</td>
      <td>108,850.6</td>
      <td>41,458.8</td>
    </tr>
    <tr>
      <td rowspan = "2">Long Term</td>
      <td>Basis</td>
      <td>463,804.7</td>
      <td>521,476.1</td>
      <td>405,631.3</td>
    </tr>
    <tr>
      <td>Extreme</td>
      <td>483,135.3</td>
      <td>1,152,589.7</td>
      <td>438,936.4</td>
    </tr>
  </tbody>
</table>

## Risk Assessment

### Helionis Cluster

<table>
  <thead>
    <tr>
      <th>Hazard</th>
      <th>Risk</th>
      <th>Definition</th>
      <th>Mitigation</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Cargo Loss</strong></td>
      <td>Cargo Volume Risk</td>
      <td>Helionis has the highest concentration of cargo volume, increasing the likelihood of claims due to greater quantity and value of goods in transit.</td>
      <td>Adjust premiums to reflect the volume of cargo being transported, and set limits on the maximum insured capacity to control potential losses.</td>
    </tr>
    <tr>
      <td><strong>Equipment Failure</strong></td>
      <td>Irregular gravitational resonances </td>
      <td>Unstable gravitational interactions within a solar system caused by surrounding celestial bodies, accelerating equipment age and stressful usage intensity.</td>
      <td>Adjust premiums and underwriting controls based on proactive, rather than reactive, maintenance standards.</td>
    </tr>
    <tr>
      <td rowspan = "2"><strong>Worker’s compensation</strong></td>
      <td>Claims Risk</td>
      <td>Increased risk of claims due to injuries caused by erratic drift patterns, micro-collisions, and shifting debris clouds.</td>
      <td>Mandatory quantum-enhanced prediction models integrated into navigation systems to track shifting debris linked to underwriting eligibility.</td>
    </tr>
    <tr>
      <td>Claims Delay & Escalation Risk</td>
      <td>Delayed communication may lead to late reporting and escalation of injuries, increasing claim severity due to worsened medical conditions.</td>
      <td>Expansion of the Interplanetary Claims Grid for real-time claims reporting via orbital AI adjudicators.</td>
    </tr>
    <tr>
      <td><strong>Business Interruption</strong></td>
      <td>Rapid Spatial Cluttering</td>
      <td>Communications system is prone to asteroid damage. Loss of communication may halt mining production increasing the change of business interruption.</td>
      <td>Deploy multiple independent relay satellites in diverse orbits to prevent a single cluster fragmentation from cutting off all communication.</td>
    </tr>
    <tr>
      <td><strong>Cargo Loss, Equipment Failure, Business Interruption</strong></td>
      <td>Asteroid Collisions</td>
      <td>Asteroid collisions and debris clouds create navigation challenges, damage equipment quality, and wipe out multiple rigs or satellites.</td>
      <td>Enforce protocols on low-risk route selection, verified equipment shielding systems and flexible modular operations with relocatable rigs.</td>
    </tr>
  </tbody>
</table>

### Bayesia System

<table>
  <thead>
    <tr>
      <th>Hazard</th>
      <th>Risk</th>
      <th>Definition</th>
      <th>Mitigation</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan = "2"><strong>Equipment Failure, Cargo Loss, Business Interruption</strong></td>
      <td>Radiation damage </td>
      <td>Binary star system leads to radiation spikes during orbital alignments, increasing claims on electronic damage and incidents during transportation. This may disable entire mining operations simultaneously leading to large losses in business interruption.</td>
      <td>Sub-limits on radiation losses, with premium incentives for radiation-resistant equipment and low-exposure routing.</td>
    </tr>
    <tr>
      <td>Extreme temperatures</td>
      <td>Extreme temperatures drive equipment failure, cargo degradation, and production downtime, increasing both claim frequency and severity.</td>
      <td>Stricter durability and heat-resistant packaging requirements, with premiums adjusted for accelerated wear and temperature-related risks.</td>
    </tr>
    <tr>
      <td rowspan = "2"><strong>Worker’s compensation</strong></td>
      <td>Catastrophic Claims Risk</td>
      <td>Exposure to elevated ambient radiation and temperature extremes results in extreme-severity claims, including long-term disability and chronic illness benefits.</td>
      <td>External risks are hard to predict so it is preferable to cede the catastrophic risk to a reinsurer. These claims can have a severe impact on profitability. </td>
    </tr>
    <tr>
      <td>Claims Accumulation Risk</td>
      <td>Working extended periods in a high-gravity environment generates more frequent claims, leading to extended wage replacement lengths.</td>
      <td>Underwriting control for a mandatory cap on hours worked per week to limit exposure accumulation.</td>
    </tr>
  </tbody>
</table>

### Oryn Delta

<table>
  <thead>
    <tr>
      <th>Hazard</th>
      <th>Risk</th>
      <th>Definition</th>
      <th>Mitigation</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan = "2"><strong>Cargo Loss</strong></td>
      <td>Navigation Instability</td>
      <td>Weak signals disrupt communication with towers, reducing navigation reliability and increasing delays or cargo loss.</td>
      <td>Premium incentives for operators using high-reliability routes, with loadings applied to routes with historically weak signal coverage.</td>
    </tr>
    <tr>
      <td>Low Visibility Conditions</td>
      <td>Environmental factors such as fog and dust reduce visibility, impairing navigation and increasing accident risk.</td>
      <td>Strict underwriting controls requiring transportation vehicles to be equipped with advanced sensors such as radar.</td>
    </tr>
    <tr>
      <td rowspan = "2"><strong>Equipment Failure, Business Interruption</strong></td>
      <td>Unpredictable Stellar Flares</td>
      <td>Sudden and irregular bursts of stellar radiation can damage equipment .</td>
      <td>Real-time monitoring systems to detect flare events and adjust pricing models early. Coverage limits for extreme flare events.</td>
    </tr>
    <tr>
      <td>Gravitational Shear Zones</td>
      <td>Regions where uneven gravitational forces lead to structural instability and increased failure risk.</td>
      <td>Regular reporting requirements on reinforced equipment for shear zones.</td>
    </tr>
    <tr>
      <td rowspan = "2"><strong>Worker’s compensation</strong></td>
      <td>Future Catastrophic Claims Risk</td>
      <td>Increased risk of extreme-severity claims, due to future expansions into the asymmetric asteroid ring, where rapid orbital shear and fluctuating gravitational gradients.</td>
      <td>External risks are hard to predict so it is preferable to cede the catastrophic risk to a reinsurer. These claims can have a severe impact on profitability.</td>
    </tr>
    <tr>
      <td>Rapid Infrastructure Development</td>
      <td>Higher likelihood of claims due to rapid expansion of infrastructure indicating increases in short-term operational instability.</td>
      <td>Underwriting control for mandatory quality safety training and protective gear prior to worker deployment.</td>
    </tr>
  </tbody>
</table>


## Data Limitations

- Data cleaning was not expected to materially bias the results. 
- Historical datasets were drawn from a different set of solar systems than those being modelled (Helionis Cluster, Bayesia System and Oryn Delta), leading to potentual structural differences, particularly under extreme conditions.
- The lack of clear quantitative distinctions between solar systems in quarry personnel meant an exposure index could not be constructed, so it was proposed that an arbitrary loading factor be applied with Helionis Cluster acting as the benchmark.
- The historical cargo loss data lacked clear distinctions between solar systems, limiting the model's ability to capture structural differences beyond qualitative adjustments. 

## Final Report
The final report can be found [here](https://github.com/Actuarial-Control-Cycle-T1-2026/group-page-showcase-4001-group-1/blob/main/ACTL4001%20Report.pdf).

