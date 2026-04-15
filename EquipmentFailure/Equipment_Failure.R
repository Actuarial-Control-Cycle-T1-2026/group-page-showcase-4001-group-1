# Install packages 
install.packages("readxl")
install.packages("dplyr")
install.packages("janitor")
install.packages("ggplot2")

# Libabries
library(readxl)
library(dplyr)
library(janitor)
library(ggplot2)


# Read files 
file_path <- "C:/Users/Chloe/OneDrive - UNSW/UNSW/ACTL4001/SOA_2026_Case_Study_Materials/srcsc-2026-claims-equipment-failure.xlsx"

equipment_freq <- read_excel(file_path, sheet = "freq")
equipment_sev  <- read_excel(file_path, sheet = "sev")

################################ DATA CLEANING ################################

# -----------------------------
# Clean corrupted variables
# -----------------------------
equipment_freq <- equipment_freq %>%
  mutate(
    solar_system   = sub("_.*", "", solar_system),
    equipment_type = sub("_.*", "", equipment_type)
  )

equipment_sev <- equipment_sev %>%
  mutate(
    solar_system   = sub("_.*", "", solar_system),
    equipment_type = sub("_.*", "", equipment_type)
  )

# -----------------------------
# Remove white spaces
# -----------------------------
equipment_freq <- equipment_freq %>%
  mutate(
    solar_system   = trimws(solar_system),
    equipment_type = trimws(equipment_type)
  )

equipment_sev <- equipment_sev %>%
  mutate(
    solar_system   = trimws(solar_system),
    equipment_type = trimws(equipment_type)
  )

# -----------------------------
# Convert categorical variables to factors 
# -----------------------------
equipment_freq <- equipment_freq %>%
  mutate(
    equipment_type = as.factor(equipment_type),
    solar_system   = as.factor(solar_system)
  )

equipment_sev <- equipment_sev %>%
  mutate(
    equipment_type = as.factor(equipment_type),
    solar_system   = as.factor(solar_system)
  )

# -----------------------------
# Summary 
# -----------------------------
equipment_freq %>% dplyr::select(where(is.numeric)) %>% summary()
equipment_sev %>% dplyr::select(where(is.numeric)) %>% summary()

# -----------------------------
# Remove rows with illogical values 
# -----------------------------
equipment_freq_clean <- equipment_freq %>%
  filter(
    equipment_age >= 0,
    maintenance_int > 0,
    usage_int >= 0 & usage_int <= 24,
    exposure > 0 & exposure <= 1,
    claim_count >= 0,
    claim_count == floor(claim_count)   
  )

equipment_sev_clean <- equipment_sev %>%
  filter(
    equipment_age >= 0,
    maintenance_int > 0,
    usage_int >= 0 & usage_int <= 24,
    exposure > 0 & exposure <= 1,
    claim_amount > 0  
  )

# -----------------------------
# Drop missing values in data  
# -----------------------------
equipment_freq_cleaned <- equipment_freq_clean %>% filter(complete.cases(.))
equipment_sev_cleaned <- equipment_sev_clean %>%filter(complete.cases(.))

# -----------------------------
# Check removal amount 
# -----------------------------
(nrow(equipment_freq_clean)-nrow(equipment_freq_cleaned))/nrow(equipment_freq_clean) 
(nrow(equipment_sev_clean)-nrow(equipment_sev_cleaned))/nrow(equipment_sev_clean) 

# -----------------------------
# Remove outliers 
# -----------------------------

## Examine quantiles 
quantile(equipment_freq_cleaned$equipment_age,
         probs = c(0.90, 0.95, 0.99, 0.995, 0.999, 1),
         na.rm = TRUE)

quantile(equipment_sev_cleaned$equipment_age,
         probs = c(0.90, 0.95, 0.99, 0.995, 0.999, 1),
         na.rm = TRUE)

quantile(equipment_freq_cleaned$maintenance_int,
         probs = c(0.90, 0.95, 0.99, 0.995, 0.999, 1),
         na.rm = TRUE)

quantile(equipment_sev_cleaned$maintenance_int,
         probs = c(0.90, 0.95, 0.99, 0.995, 0.999, 1),
         na.rm = TRUE)

quantile(equipment_sev_cleaned$claim_amount,
         probs = c(0.90, 0.95, 0.99, 0.995, 0.999, 1),
         na.rm = TRUE)

## Frequency caps 
age_cap_freq   <- quantile(equipment_freq_cleaned$equipment_age, 0.995, na.rm = TRUE)
maint_cap_freq <- quantile(equipment_freq_cleaned$maintenance_int, 0.995, na.rm = TRUE)

## Severity caps
age_cap_sev <- quantile(equipment_sev_cleaned$equipment_age, 0.995, na.rm = TRUE)
maint_cap_sev <- quantile(equipment_sev_cleaned$maintenance_int, 0.995, na.rm = TRUE)
claim_cap_sev <- quantile(equipment_sev_cleaned$claim_amount, 0.999, na.rm = TRUE)

### Apply limits to data 
equipment_freq_capped <- equipment_freq_cleaned %>%
  mutate(
    equipment_age   = pmin(equipment_age, age_cap_freq),
    maintenance_int = pmin(maintenance_int, maint_cap_freq)
  )

equipment_sev_capped <- equipment_sev_cleaned %>%
  mutate(
    equipment_age = pmin(equipment_age, age_cap_sev),
    maintenance_int = pmin(maintenance_int, maint_cap_sev),
    claim_amount  = pmin(claim_amount, claim_cap_sev)
  )


############################### DATA EXPLORATION ###############################

# -----------------------------
# Claim frequency variable 
# -----------------------------
equipment_freq_capped <- equipment_freq_capped %>%
  mutate(
    claim_frequency = claim_count / exposure
  )

## Histogram of claim count 
summary(equipment_freq_capped$claim_count)

ggplot(equipment_freq_capped, aes(x = claim_count)) +
  geom_histogram(bins = 30) +
  labs(x = "Claim Count", y = "Number of Policies")

## Histogram of claim frequency 
summary(equipment_freq_capped$claim_frequency)

ggplot(equipment_freq_capped, aes(x = claim_frequency)) +
  geom_histogram(bins = 30) +
  labs(x = "Claim Frequency", y = "Number of Policies")

# -----------------------------
# Equipment Age
# -----------------------------
equipment_freq_capped %>%
  mutate(age_band = cut(equipment_age, breaks = 6)) %>%
  group_by(age_band) %>%
  summarise(
    claims = sum(claim_count),
    exposure = sum(exposure),
    frequency = claims / exposure
  )

## Histogram 
equipment_freq_capped %>%
  mutate(age_band = cut(equipment_age, breaks = 6)) %>%
  group_by(age_band) %>%
  summarise(
    claims = sum(claim_count),
    exposure = sum(exposure),
    frequency = claims / exposure
  ) %>%
  ggplot(aes(x = age_band, y = frequency)) +
  geom_col() +
  labs(x = "Equipment Age Band", y = "Claim Frequency")

# -----------------------------
# Usage Intensity
# ----------------------------- 
usage_summary <- equipment_freq_capped %>%
  mutate(
    usage_band = cut(usage_int, breaks = 6, include.lowest = TRUE)
  ) %>%
  group_by(usage_band) %>%
  summarise(
    claims = sum(claim_count),
    exposure = sum(exposure),
    freq = claims / exposure,
    .groups = "drop"
  )

ggplot(usage_summary, aes(x = usage_band, y = freq)) +
  geom_col() +
  geom_text(aes(label = round(freq,3)), vjust = -0.4) +
  labs(
    x = "Usage Intensity Band",
    y = "Claim Frequency (claims per year)",
    title = "Exposure-weighted Claim Frequency by Usage Intensity"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# -----------------------------
# Maintenance Intensity
# ----------------------------- 
maint_summary <- equipment_freq_capped %>%
  mutate(
    maint_band = cut(maintenance_int, breaks = 6, include.lowest = TRUE)
  ) %>%
  group_by(maint_band) %>%
  summarise(
    claims = sum(claim_count),
    exposure = sum(exposure),
    freq = claims / exposure,
    .groups = "drop"
  )

ggplot(maint_summary, aes(x = maint_band, y = freq)) +
  geom_col() +
  geom_text(aes(label = round(freq,3)), vjust = -0.4) +
  labs(
    x = "Maintenance Intensity Band",
    y = "Claim Frequency (claims per year)",
    title = "Exposure-weighted Claim Frequency by Maintenance Intensity"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# -----------------------------
# Equipment Type
# -----------------------------  
type_summary <- equipment_freq_capped %>%
  group_by(equipment_type) %>%
  summarise(
    claims = sum(claim_count),
    exposure = sum(exposure),
    freq = claims / exposure
  )

ggplot(type_summary, aes(x = equipment_type, y = freq)) +
  geom_col() +
  geom_text(aes(label = round(freq,3)), vjust = -0.4) +
  labs(
    x = "Equipment Type",
    y = "Claim Frequency (claims per year)",
    title = "Exposure-weighted Claim Frequency by Equipment Type"
  )

# -----------------------------
# Solar system 
# -----------------------------  
solar_summary <- equipment_freq_capped %>%
  group_by(solar_system) %>%
  summarise(
    claims = sum(claim_count),
    exposure = sum(exposure),
    freq = claims / exposure
  )

ggplot(solar_summary, aes(x = solar_system, y = freq)) +
  geom_col() +
  geom_text(aes(label = round(freq,3)), vjust = -0.4) +
  labs(
    x = "Solar System",
    y = "Claim Frequency (claims per year)",
    title = "Exposure-weighted Claim Frequency by Solar System"
  )

# -----------------------------
# Correlation Matrix
# ----------------------------- 
equipment_freq_capped %>%
  select(equipment_age, maintenance_int, usage_int) %>%
  cor()

# -----------------------------
# Claim severity 
# ----------------------------- 
ggplot(equipment_sev_capped,
       aes(x = cut(equipment_age, breaks = 6),
           y = log(claim_amount))) +
  geom_boxplot() +
  labs(
    x = "Equipment Age Band",
    y = "Log Claim Amount",
    title = "Severity vs Equipment Age"
  )

# -----------------------------
# Equipment Age
# ----------------------------- 
ggplot(equipment_sev_capped,
       aes(x = cut(equipment_age, breaks = 6),
           y = log(claim_amount))) +
  geom_boxplot() +
  labs(
    x = "Equipment Age Band",
    y = "Log Claim Amount",
    title = "Severity vs Equipment Age"
  )

## Stats 
equipment_sev_capped %>%
  mutate(age_band = cut(equipment_age, breaks = 5)) %>%
  group_by(age_band) %>%
  summarise(
    mean_severity = mean(claim_amount),
    median_severity = median(claim_amount),
    n_claims = n()
  )

# -----------------------------
# Usage Intensity
# -----------------------------
ggplot(equipment_sev_capped,
       aes(x = cut(usage_int, breaks = 6),
           y = log(claim_amount))) +
  geom_boxplot() +
  labs(
    x = "Usage Intensity Band",
    y = "Log Claim Amount",
    title = "Severity vs Usage Intensity"
  )
## Stats
equipment_sev_capped %>%
  mutate(usage_band = cut(
    usage_int,
    breaks = 5
  )) %>%
  group_by(usage_band) %>%
  summarise(
    mean_severity   = mean(claim_amount),
    median_severity = median(claim_amount),
    sd_severity     = sd(claim_amount),
    n_claims        = n()
  )

# -----------------------------
# Maintenance Intensity
# ----------------------------- 
ggplot(equipment_sev_capped,
       aes(x = cut(maintenance_int, breaks = 6),
           y = log(claim_amount))) +
  geom_boxplot() +
  labs(
    x = "Maintenance Intensity Band",
    y = "Log Claim Amount",
    title = "Severity vs Maintenance Intensity"
  )
## Stats
equipment_sev_capped %>%
  mutate(maintenance_band = cut(maintenance_int, breaks = 5)) %>%
  group_by(maintenance_band) %>%
  summarise(
    mean_severity   = mean(claim_amount),
    median_severity = median(claim_amount),
    sd_severity     = sd(claim_amount),
    n_claims        = n()
  )

# -----------------------------
# Equipment Type
# ----------------------------- 
ggplot(equipment_sev_capped,
       aes(x = equipment_type,
           y = log(claim_amount))) +
  geom_boxplot() +
  labs(
    x = "Equipment Type",
    y = "Log Claim Amount",
    title = "Severity vs Equipment Type"
  )

## Stats
equipment_sev_capped %>%
  group_by(equipment_type) %>%
  summarise(
    mean_severity   = mean(claim_amount),
    median_severity = median(claim_amount),
    sd_severity     = sd(claim_amount),
    min_severity    = min(claim_amount),
    max_severity    = max(claim_amount),
    n_claims        = n()
  )

# -----------------------------
# Solar system 
# ----------------------------- 
ggplot(equipment_sev_capped,
       aes(x = solar_system,
           y = log(claim_amount))) +
  geom_boxplot() +
  labs(
    x = "Solar System",
    y = "Log Claim Amount",
    title = "Severity vs Solar System"
  )
## Stats
equipment_sev_capped %>%
  group_by(solar_system) %>%
  summarise(
    mean_severity   = mean(claim_amount),
    median_severity = median(claim_amount),
    sd_severity     = sd(claim_amount),
    n_claims        = n()
  )


############################## MODELLING FREQUENCY #############################

# Baseline model: Poisson
freq_poisson <- glm(
  claim_count ~ equipment_age +
    maintenance_int +
    usage_int +
    equipment_type +
    solar_system +
    offset(log(exposure)),
  family = poisson(link = "log"),
  data = equipment_freq_capped
)

summary(freq_poisson) # All variables are significantly 

## Check overdispersion 
dispersion <- sum(residuals(freq_poisson, type = "pearson")^2) / df.residual(freq_poisson)
dispersion

# Install package 
install.packages("MASS")   # only once
library(MASS)

# Comparison model: NB 
freq_nb <- glm.nb(
  claim_count ~ equipment_age +
    maintenance_int +
    usage_int +
    equipment_type +
    solar_system +
    offset(log(exposure)),
  data = equipment_freq_capped
)
AIC(freq_poisson, freq_nb) #NB is not better 

## Final interpretation 
exp(cbind(
  Rate_Ratio = coef(freq_poisson),
  confint(freq_poisson)
))

############################## MODELLING SEVERITY #############################

# Gamma GLM 
sev_gamma <- glm(
  claim_amount ~ equipment_age +
    maintenance_int +
    usage_int +
    equipment_type +
    solar_system,
  family = Gamma(link = "log"),
  data = equipment_sev_capped
)

summary(sev_gamma) # maintenance intensity insignificant 

# Gamma GLM without maintenance 
sev_gamma2 <- glm(
  claim_amount ~ equipment_age +
    usage_int +
    equipment_type +
    solar_system,
  family = Gamma(link = "log"),
  data = equipment_sev_capped
)

summary(sev_gamma2)

# Lognormal model  
sev_lognormal <- lm(
  log(claim_amount) ~ equipment_age +
    usage_int +
    equipment_type +
    solar_system,
  data = equipment_sev_capped
)

summary(sev_lognormal)


# Residual plots 
par(mfrow = c(2,2))
plot(sev_lognormal)


############################## FREQUENCY ADJUSTMENT ############################


library(dplyr)
library(tidyr)

# ============================================================
# 1) QUARRY DATA PREP
# ============================================================

# --- Inventory ---
inventory <- tibble(
  solar_system = rep(c("Helionis Cluster", "Bayesia System", "Oryn Delta"), each = 6),
  equipment_type = rep(c("Quantum Bore", "Graviton Extractor", "FexStram Carrier",
                         "ReglAggregators", "Flux Rider", "Ion Pulverizer"), times = 3),
  units = c(
    300, 240, 150, 300, 1500, 90,
    150, 120, 75, 150, 750, 45,
    100, 80, 50, 100, 500, 30
  )
)

# --- Service years ---
service_years <- tribble(
  ~solar_system, ~age_band, ~`Quantum Bore`, ~`Graviton Extractor`, ~`FexStram Carrier`, ~`ReglAggregators`, ~`Flux Rider`, ~`Ion Pulverizer`,
  "Helionis Cluster", "<5",    30, 24, 15, 30, 150, 9,
  "Helionis Cluster", "5-9",   45, 36, 23, 45, 225, 14,
  "Helionis Cluster", "10-14", 180,144, 89,180, 900, 53,
  "Helionis Cluster", "15-19", 30, 24, 15, 30, 150, 9,
  "Helionis Cluster", "20+",   15, 12,  8, 15,  75, 5,
  
  "Bayesia System",   "<5",    45, 36, 23, 45, 225, 14,
  "Bayesia System",   "5-9",   38, 30, 19, 38, 187, 11,
  "Bayesia System",   "10-14", 59, 48, 29, 59, 300, 18,
  "Bayesia System",   "15-19", 8,   6,  4,  8,  38, 2,
  "Bayesia System",   "20+",   0,   0,  0,  0,   0, 0,
  
  "Oryn Delta",       "<5",    75, 60, 37, 75, 375, 22,
  "Oryn Delta",       "5-9",   15, 12,  8, 15,  75, 5,
  "Oryn Delta",       "10-14", 10,  8,  5, 10,  50, 3,
  "Oryn Delta",       "15-19", 0,   0,  0,  0,   0, 0,
  "Oryn Delta",       "20+",   0,   0,  0,  0,   0, 0
)

# --- Usage / maintenance ---
usage_maint <- tribble(
  ~solar_system, ~equipment_type, ~pct_in_operation, ~maintenance_int,
  "Helionis Cluster", "Quantum Bore",         0.95,  750,
  "Helionis Cluster", "Graviton Extractor",   0.95,  750,
  "Helionis Cluster", "FexStram Carrier",     0.90,  375,
  "Helionis Cluster", "ReglAggregators",      0.80, 1500,
  "Helionis Cluster", "Flux Rider",           0.80, 1500,
  "Helionis Cluster", "Ion Pulverizer",       0.50, 1000,
  
  "Bayesia System",   "Quantum Bore",         0.80,  600,
  "Bayesia System",   "Graviton Extractor",   0.80,  600,
  "Bayesia System",   "FexStram Carrier",     0.75,  400,
  "Bayesia System",   "ReglAggregators",      0.75, 1000,
  "Bayesia System",   "Flux Rider",           0.80, 1000,
  "Bayesia System",   "Ion Pulverizer",       0.60,  750,
  
  "Oryn Delta",       "Quantum Bore",         0.75,  500,
  "Oryn Delta",       "Graviton Extractor",   0.75,  500,
  "Oryn Delta",       "FexStram Carrier",     0.70,  250,
  "Oryn Delta",       "ReglAggregators",      0.70,  300,
  "Oryn Delta",       "Flux Rider",           0.75,  300,
  "Oryn Delta",       "Ion Pulverizer",       0.50,  500
)

# --- External risk index ---
risk_index <- tribble(
  ~solar_system, ~equipment_type, ~risk_index,
  "Helionis Cluster", "Quantum Bore",         0.69,
  "Helionis Cluster", "Graviton Extractor",   0.48,
  "Helionis Cluster", "FexStram Carrier",     0.67,
  "Helionis Cluster", "ReglAggregators",      0.24,
  "Helionis Cluster", "Flux Rider",           0.24,
  "Helionis Cluster", "Ion Pulverizer",       0.64,
  
  "Bayesia System",   "Quantum Bore",         0.77,
  "Bayesia System",   "Graviton Extractor",   0.57,
  "Bayesia System",   "FexStram Carrier",     0.71,
  "Bayesia System",   "ReglAggregators",      0.26,
  "Bayesia System",   "Flux Rider",           0.21,
  "Bayesia System",   "Ion Pulverizer",       0.66,
  
  "Oryn Delta",       "Quantum Bore",         0.93,
  "Oryn Delta",       "Graviton Extractor",   0.73,
  "Oryn Delta",       "FexStram Carrier",     0.78,
  "Oryn Delta",       "ReglAggregators",      0.35,
  "Oryn Delta",       "Flux Rider",           0.20,
  "Oryn Delta",       "Ion Pulverizer",       0.75
)

# ============================================================
# 2) SUMMARISE QUARRY CHARACTERISTICS AT CELL LEVEL
# ============================================================

quarry_age <- service_years %>%
  pivot_longer(
    cols = -c(solar_system, age_band),
    names_to = "equipment_type",
    values_to = "units_age_band"
  ) %>%
  mutate(
    equipment_age = case_when(
      age_band == "<5"    ~ 2.5,
      age_band == "5-9"   ~ 7.0,
      age_band == "10-14" ~ 12.0,
      age_band == "15-19" ~ 17.0,
      age_band == "20+"   ~ 22.0
    )
  )

age_summary <- quarry_age %>%
  group_by(solar_system, equipment_type) %>%
  summarise(
    avg_age = weighted.mean(equipment_age, w = units_age_band),
    .groups = "drop"
  )

quarry_summary <- inventory %>%
  left_join(age_summary, by = c("solar_system", "equipment_type")) %>%
  left_join(usage_maint, by = c("solar_system", "equipment_type")) %>%
  left_join(risk_index, by = c("solar_system", "equipment_type")) %>%
  mutate(
    usage_int = pct_in_operation * 24
  )

# ============================================================
# 3) STANDARDISE PRODUCTIVITY AND RISK INDICES
# ============================================================

# Productivity should scale exposure, not be multiplied again into the rate
quarry_summary <- quarry_summary %>%
  mutate(
    productivity_index = pct_in_operation / mean(pct_in_operation),
    risk_factor_raw    = risk_index / mean(risk_index)
  )

# Optional damping of the external risk adjustment only
# Keeps external adjustments modest and avoids over-scaling
risk_damping <- 0.50

quarry_summary <- quarry_summary %>%
  mutate(
    risk_factor = 1 + risk_damping * (risk_factor_raw - 1)
  )

# ============================================================
# 4) MAP NEW BUSINESS SOLAR SYSTEMS TO MODEL LEVELS
# ============================================================

# Historical model only knows Helionis / Epsilon / Zeta.
# For unseen systems, map to a neutral baseline level.
# Choose whichever level is your reference / most neutral historical level.
quarry_projection <- quarry_summary %>%
  mutate(
    solar_system_model = case_when(
      solar_system == "Helionis Cluster" ~ "Helionis Cluster",
      TRUE ~ "Epsilon"
    )
  )

# Make factors consistent with the fitted Poisson model
quarry_projection$equipment_type <- factor(
  quarry_projection$equipment_type,
  levels = levels(equipment_freq_capped$equipment_type)
)

quarry_projection$solar_system_model <- factor(
  quarry_projection$solar_system_model,
  levels = levels(equipment_freq_capped$solar_system)
)

# ============================================================
# 5) PREDICT BASE CLAIM RATE PER UNIT-EXPOSURE
# ============================================================

# IMPORTANT:
# Set exposure = 1 so the prediction is a rate for one full unit-year of exposure
quarry_projection$base_rate_per_unit <- predict(
  freq_poisson,
  newdata = quarry_projection %>%
    transmute(
      equipment_age   = avg_age,
      maintenance_int = maintenance_int,
      usage_int       = usage_int,
      equipment_type  = equipment_type,
      solar_system    = solar_system_model,
      exposure        = 1
    ),
  type = "response"
)

# ============================================================
# 6) APPLY PRODUCTIVITY TO EXPOSURE, NOT TO THE RATE
# ============================================================

quarry_projection <- quarry_projection %>%
  mutate(
    effective_exposure = units * productivity_index,
    adjusted_rate_per_unit = base_rate_per_unit * risk_factor,
    expected_claims = adjusted_rate_per_unit * effective_exposure
  )

# ============================================================
# 7) OUTPUTS / CHECKS
# ============================================================

# Total expected annual claims
sum(quarry_projection$expected_claims)

# By solar system
freq_by_system <- quarry_projection %>%
  group_by(solar_system) %>%
  summarise(
    total_units = sum(units),
    effective_exposure = sum(effective_exposure),
    expected_claims = sum(expected_claims),
    implied_frequency = expected_claims / effective_exposure,
    .groups = "drop"
  )

freq_by_system

# By equipment type
freq_by_equipment <- quarry_projection %>%
  group_by(equipment_type) %>%
  summarise(
    total_units = sum(units),
    effective_exposure = sum(effective_exposure),
    expected_claims = sum(expected_claims),
    implied_frequency = expected_claims / effective_exposure,
    .groups = "drop"
  )

freq_by_equipment

# Cell-level projection table for severity / aggregate modelling
quarry_projection %>%
  dplyr::select(
    solar_system,
    equipment_type,
    units,
    avg_age,
    usage_int,
    maintenance_int,
    productivity_index,
    risk_factor,
    base_rate_per_unit,
    adjusted_rate_per_unit,
    effective_exposure,
    expected_claims
  )

############################## #SEVERITY ADJUSTMENT ############################


quarry_severity_data <- quarry_projection %>%
  transmute(
    equipment_age = avg_age,
    usage_int = usage_int,
    equipment_type = factor(
      equipment_type,
      levels = levels(equipment_sev_capped$equipment_type)
    ),
    solar_system = factor(
      solar_system_model,
      levels = levels(equipment_sev_capped$solar_system)
    )
  )

quarry_projection$log_severity_pred <- predict(
  sev_lognormal,
  newdata = quarry_severity_data
)

sigma2 <- summary(sev_lognormal)$sigma^2

quarry_projection$expected_severity <- exp(
  quarry_projection$log_severity_pred + 0.5 * sigma2
)

# ============================================================
# 1) PREP NEW-BUSINESS DATA FOR SEVERITY PREDICTION
# ============================================================

# Optional safeguard:
# Historical equipment_age range in the equipment-failure data dictionary is 0-10 years.
# Cap projected ages at the historical max to avoid excessive extrapolation.
quarry_projection <- quarry_projection %>%
  mutate(
    avg_age_capped = pmin(avg_age, max(equipment_sev_capped$equipment_age, na.rm = TRUE))
  )

quarry_severity_data <- quarry_projection %>%
  transmute(
    equipment_age = avg_age_capped,
    usage_int = usage_int,
    equipment_type = factor(
      equipment_type,
      levels = levels(equipment_sev_capped$equipment_type)
    ),
    solar_system = factor(
      solar_system_model,
      levels = levels(equipment_sev_capped$solar_system)
    )
  )

# ============================================================
# 2) PREDICT BASE SEVERITY
# ============================================================

quarry_projection$log_severity_pred <- predict(
  sev_lognormal,
  newdata = quarry_severity_data
)

sigma2 <- summary(sev_lognormal)$sigma^2
sigma  <- sqrt(sigma2)

# Lognormal mean correction: E[X] = exp(mu + 0.5*sigma^2)
quarry_projection$expected_severity <- exp(
  quarry_projection$log_severity_pred + 0.5 * sigma2
)

# Optional reasonableness check
quarry_projection %>%
  summarise(
    min_expected_severity = min(expected_severity),
    mean_expected_severity = mean(expected_severity),
    max_expected_severity = max(expected_severity)
  )

############################## INFLATION SCENARIOS ##############################

# ============================================================
# 3) HISTORICAL INFLATION DATA
# ============================================================

inflation_hist <- tibble(
  year = 2160:2174,
  inflation = c(
    0.0377, 0.0232, 0.0148, 0.0108, 0.0022,
    0.0071, 0.0155, 0.0216, 0.0181, 0.0073,
    0.0294, 0.0708, 0.0598, 0.0276, 0.0239
  )
)

# ============================================================
# 4) FORWARD INFLATION SCENARIOS
# ============================================================

projection_years <- 2175:2184
base_inflation_mean <- mean(inflation_hist$inflation)

inflation_scenarios <- tibble(
  year = projection_years,
  low  = rep(0.020, length(projection_years)),
  base = rep(base_inflation_mean, length(projection_years)),
  high = rep(0.035, length(projection_years))
)

inflation_factors <- inflation_scenarios %>%
  mutate(
    low_factor  = cumprod(1 + low),
    base_factor = cumprod(1 + base),
    high_factor = cumprod(1 + high)
  )

############################## SEVERITY PROJECTION ##############################

# ============================================================
# 5) APPLY INFLATION TO PROJECTED SEVERITY
# ============================================================

severity_projection <- quarry_projection %>%
  dplyr::select(
    solar_system,
    equipment_type,
    units,
    expected_claims,
    expected_severity
  ) %>%
  tidyr::crossing(inflation_factors) %>%
  mutate(
    severity_low  = expected_severity * low_factor,
    severity_base = expected_severity * base_factor,
    severity_high = expected_severity * high_factor
  )

# Weighted average severity by year
severity_summary <- severity_projection %>%
  group_by(year) %>%
  summarise(
    avg_severity_low  = weighted.mean(severity_low,  w = expected_claims),
    avg_severity_base = weighted.mean(severity_base, w = expected_claims),
    avg_severity_high = weighted.mean(severity_high, w = expected_claims),
    .groups = "drop"
  )

severity_summary

# Optional: severity by solar system
severity_by_system <- severity_projection %>%
  group_by(year, solar_system) %>%
  summarise(
    avg_severity_low  = weighted.mean(severity_low,  w = expected_claims),
    avg_severity_base = weighted.mean(severity_base, w = expected_claims),
    avg_severity_high = weighted.mean(severity_high, w = expected_claims),
    .groups = "drop"
  )

severity_by_system

# Optional plot
severity_summary_long <- severity_summary %>%
  pivot_longer(
    cols = starts_with("avg_severity"),
    names_to = "scenario",
    values_to = "avg_severity"
  )

ggplot(severity_summary_long, aes(x = year, y = avg_severity, color = scenario)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Projected Average Claim Severity Under Inflation Scenarios",
    x = "Year",
    y = "Weighted Average Severity"
  )

############################## PROJECTED EXPECTED LOSS ##############################

# ============================================================
# 6) EXPECTED LOSSES BY YEAR
# ============================================================

loss_projection <- severity_projection %>%
  mutate(
    expected_loss_low  = expected_claims * severity_low,
    expected_loss_base = expected_claims * severity_base,
    expected_loss_high = expected_claims * severity_high
  )

loss_summary <- loss_projection %>%
  group_by(year) %>%
  summarise(
    aggregate_loss_low  = sum(expected_loss_low),
    aggregate_loss_base = sum(expected_loss_base),
    aggregate_loss_high = sum(expected_loss_high),
    .groups = "drop"
  )

loss_summary

# Optional: by solar system
loss_by_system <- loss_projection %>%
  group_by(year, solar_system) %>%
  summarise(
    aggregate_loss_low  = sum(expected_loss_low),
    aggregate_loss_base = sum(expected_loss_base),
    aggregate_loss_high = sum(expected_loss_high),
    .groups = "drop"
  )

loss_by_system

# Optional: by equipment type
loss_by_equipment <- loss_projection %>%
  group_by(year, equipment_type) %>%
  summarise(
    aggregate_loss_low  = sum(expected_loss_low),
    aggregate_loss_base = sum(expected_loss_base),
    aggregate_loss_high = sum(expected_loss_high),
    .groups = "drop"
  )

loss_by_equipment

############################## AGGREGATE LOSS SIMULATION ##############################

set.seed(123)
n_sims <- 100000

# ============================================================
# 7) INTEREST RATE DATA
# ============================================================

interest_data <- read_excel("srcsc-2026-interest-and-inflation.xlsx") %>%
  clean_names()

short_rate_base <- mean(interest_data$x1_year_risk_free_annual_spot_rate)
long_rate_base  <- mean(interest_data$x10_year_risk_free_annual_spot_rate)

# For consistency with your base scenario
base_inflation <- mean(tail(inflation_hist$inflation, 10))

projection_horizon <- 10
projection_years <- 2175:(2175 + projection_horizon - 1)

# ============================================================
# 8) BUILD SIMULATION INPUT
# ============================================================

# expected_claims already includes:
# - base frequency prediction
# - risk adjustment
# - productivity-adjusted exposure
sim_input_base <- quarry_projection %>%
  dplyr::select(
    solar_system,
    equipment_type,
    units,
    expected_claims,
    log_severity_pred
  )

# ============================================================
# 9) HELPER FUNCTION: SIMULATE ONE YEAR OF AGGREGATE LOSSES
# ============================================================

simulate_aggregate_loss <- function(lambdas, mus, sigma, n_sims = 100000) {
  total_loss <- numeric(n_sims)
  
  for (j in seq_along(lambdas)) {
    counts <- rpois(n_sims, lambda = lambdas[j])
    total_claims <- sum(counts)
    
    if (total_claims > 0) {
      sev <- rlnorm(total_claims, meanlog = mus[j], sdlog = sigma)
      sim_id <- rep.int(seq_len(n_sims), counts)
      cell_totals <- rowsum(sev, group = sim_id, reorder = FALSE)
      
      total_loss[as.integer(rownames(cell_totals))] <-
        total_loss[as.integer(rownames(cell_totals))] + as.numeric(cell_totals)
    }
  }
  
  total_loss
}

# ============================================================
# 10) HELPER FUNCTION: SUMMARISE DISTRIBUTION
# ============================================================

summarise_losses <- function(losses) {
  var95 <- unname(quantile(losses, 0.95))
  var99 <- unname(quantile(losses, 0.99))
  
  tibble(
    expected_loss = mean(losses),
    variance = var(losses),
    sd = sd(losses),
    p10 = unname(quantile(losses, 0.10)),
    p50 = unname(quantile(losses, 0.50)),
    p90 = unname(quantile(losses, 0.90)),
    VaR95 = var95,
    VaR99 = var99,
    TVaR95 = mean(losses[losses >= var95]),
    TVaR99 = mean(losses[losses >= var99])
  )
}

# ============================================================
# 11) SIMULATE YEAR-1 ANNUAL AGGREGATE LOSS
# ============================================================

annual_losses_year1 <- simulate_aggregate_loss(
  lambdas = sim_input_base$expected_claims,
  mus     = sim_input_base$log_severity_pred,
  sigma   = sigma,
  n_sims  = n_sims
)

annual_cost_summary <- summarise_losses(annual_losses_year1)
annual_cost_summary

# ============================================================
# 12) PROJECT FUTURE NOMINAL ANNUAL COSTS
# ============================================================

nominal_loss_matrix <- sapply(1:projection_horizon, function(t) {
  annual_losses_year1 * (1 + base_inflation)^(t - 1)
})

colnames(nominal_loss_matrix) <- paste0("Year_", projection_years)

expected_nominal_costs <- tibble(
  year = projection_years,
  expected_nominal_cost = colMeans(nominal_loss_matrix)
)

expected_nominal_costs

# ============================================================
# 13) SHORT-TERM COST: 1-YEAR NPV
# ============================================================

short_term_npv <- nominal_loss_matrix[, 1] / (1 + short_rate_base)^1

short_term_summary <- summarise_losses(short_term_npv) %>%
  mutate(
    horizon = "short_term",
    years = 1,
    inflation_assumption = base_inflation,
    discount_rate = short_rate_base
  )

short_term_summary

# ============================================================
# 14) LONG-TERM COST: 10-YEAR NPV
# ============================================================

discounted_loss_matrix <- sapply(1:projection_horizon, function(t) {
  nominal_loss_matrix[, t] / (1 + long_rate_base)^t
})

long_term_npv <- rowSums(discounted_loss_matrix)

long_term_summary <- summarise_losses(long_term_npv) %>%
  dplyr::mutate(
    horizon = "long_term_10yr_npv",
    years = projection_horizon,
    inflation_assumption = base_inflation,
    discount_rate = long_rate_base
  )

long_term_summary

# ============================================================
# 15) COMBINED COST SUMMARY
# ============================================================

objective1_cost_summary <- bind_rows(short_term_summary, long_term_summary) %>%
  dplyr::select(
    horizon, years, inflation_assumption, discount_rate,
    expected_loss, variance, sd,
    p10, p50, p90,
    VaR95, VaR99, TVaR95, TVaR99
  )

objective1_cost_summary

objective1_ranges <- objective1_cost_summary %>%
  transmute(
    horizon,
    years,
    low_cost  = p10,
    base_cost = expected_loss,
    high_cost = p90,
    range_width = p90 - p10
  )

objective1_ranges

# ============================================================
# 16) OPTIONAL PLOTS
# ============================================================

hist(
  short_term_npv,
  breaks = 60,
  main = "Short-Term (1-Year) Aggregate Cost NPV Distribution",
  xlab = "NPV of Aggregate Cost"
)

hist(
  year10_npv,
  breaks = 60,
  main = "Long-Term (Year-10) Aggregate Cost NPV Distribution",
  xlab = "NPV of Aggregate Cost"
)

############################## PRICING CALCULATION ##############################

# Assumptions
e <- 0.20
p <- 0.08
k <- 1.25

pricing_summary <- objective1_cost_summary %>%
  mutate(
    risk_margin = k * sd,
    premium = (expected_loss + risk_margin) / (1 - e - p),
    returns = premium,
    expenses = e * premium,
    profit_loading = p * premium,
    net_revenue = premium - expected_loss - expenses,
    return_on_premium = net_revenue / premium   # <-- ADD THIS
  ) %>%
  dplyr::select(
    horizon,
    expected_loss,
    sd,
    risk_margin,
    premium,
    returns,
    expenses,
    profit_loading,
    net_revenue,
    return_on_premium
  )

pricing_summary

################################ STRESS TESTING ################################

# ============================================================
# 17) MACROECONOMIC STRESS ASSUMPTIONS
# ============================================================

library(tibble)

macro_stress_assumptions <- tibble(
  scenario = "Macroeconomic Shock",
  inflation = 0.0528,
  short_rate = 0.0456,
  long_rate = 0.0407
)

macro_stress_assumptions

# ============================================================
# 18) HELPER FUNCTION: BUILD SIMULATION INPUT
# ============================================================

build_macro_sim_input <- function(quarry_projection) {
  
  quarry_projection %>%
    dplyr::select(
      solar_system,
      equipment_type,
      units,
      expected_claims,
      log_severity_pred
    )
}

# ============================================================
# 19) HELPER FUNCTION: RUN MACROECONOMIC STRESS SCENARIO
# ============================================================

run_macro_stress_scenario <- function(
    scenario_name,
    inflation,
    short_rate,
    long_rate,
    quarry_projection,
    sigma,
    n_sims = 100000,
    projection_horizon = 10,
    start_year = 2175,
    e = 0.20,
    p = 0.08,
    k = 1.50
) {
  
  projection_years <- start_year:(start_year + projection_horizon - 1)
  
  # Build simulation input
  sim_input <- build_macro_sim_input(quarry_projection = quarry_projection)
  
  # Simulate year-1 annual aggregate losses
  annual_losses_year1 <- simulate_aggregate_loss(
    lambdas = sim_input$expected_claims,
    mus     = sim_input$log_severity_pred,
    sigma   = sigma,
    n_sims  = n_sims
  )
  
  # Project nominal losses over the horizon using stressed inflation
  nominal_loss_matrix <- sapply(1:projection_horizon, function(t) {
    annual_losses_year1 * (1 + inflation)^(t - 1)
  })
  
  colnames(nominal_loss_matrix) <- paste0("Year_", projection_years)
  
  # ==========================================================
  # SHORT-TERM: YEAR 1 DISCOUNTED AGGREGATE LOSS
  # ==========================================================
  
  short_term_npv <- nominal_loss_matrix[, 1] / (1 + short_rate)^1
  
  short_term_cost <- summarise_losses(short_term_npv) %>%
    mutate(
      scenario = scenario_name,
      horizon = "short_term",
      years = 1,
      inflation_assumption = inflation,
      discount_rate = short_rate
    )
  
  # ==========================================================
  # LONG-TERM: 10-YEAR DISCOUNTED AGGREGATE LOSS
  # ==========================================================
  
  discounted_loss_matrix <- sapply(1:projection_horizon, function(t) {
    nominal_loss_matrix[, t] / (1 + long_rate)^t
  })
  
  long_term_npv <- rowSums(discounted_loss_matrix)
  
  long_term_cost <- summarise_losses(long_term_npv) %>%
    mutate(
      scenario = scenario_name,
      horizon = "long_term_10yr_npv",
      years = projection_horizon,
      inflation_assumption = inflation,
      discount_rate = long_rate
    )
  
  # ==========================================================
  # COMBINED COST SUMMARY
  # ==========================================================
  
  cost_summary <- bind_rows(short_term_cost, long_term_cost) %>%
    dplyr::select(
      scenario,
      horizon,
      years,
      inflation_assumption,
      discount_rate,
      expected_loss,
      variance,
      sd,
      p10,
      p50,
      p90,
      VaR95,
      VaR99,
      TVaR95,
      TVaR99
    )
  
  # ==========================================================
  # RETURNS AND NET REVENUE SUMMARY
  # ==========================================================
  
  pricing_summary <- cost_summary %>%
    mutate(
      risk_margin = k * sd,
      premium = (expected_loss + risk_margin) / (1 - e - p),
      returns = premium,
      expenses = e * premium,
      profit_loading = p * premium,
      net_revenue = premium - expected_loss - expenses,
      return_on_premium = net_revenue / premium
    ) %>%
    dplyr::select(
      scenario,
      horizon,
      expected_loss,
      returns,
      net_revenue
    )
  
  list(
    annual_losses_year1 = annual_losses_year1,
    cost_summary = cost_summary,
    pricing_summary = pricing_summary
  )
}

# ============================================================
# 20) RUN MACROECONOMIC SHOCK ONLY
# ============================================================

macro_stress_results <- run_macro_stress_scenario(
  scenario_name = "Macroeconomic Shock",
  inflation = 0.0528,
  short_rate = 0.0456,
  long_rate = 0.0407,
  quarry_projection = quarry_projection,
  sigma = sigma,
  n_sims = n_sims,
  projection_horizon = 10,
  start_year = 2175,
  e = e,
  p = p,
  k = k
)

# ============================================================
# 21) FINAL OUTPUT: AGGREGATE LOSS, RETURNS, NET REVENUE
# ============================================================

macro_results_summary <- macro_stress_results$pricing_summary %>%
  dplyr::select(
    horizon,
    expected_loss,
    returns,
    net_revenue
  )

macro_results_summary

############################## SCENARIO TESTING ##############################

# ------------------------------------------------------------
# 1) Define scenario grids
# ------------------------------------------------------------

expense_grid <- c(0.10, 0.15, 0.20, 0.25, 0.30)

# k - 0.25, k, k + 0.25
k_grid <- c(k - 0.5, k - 0.25, k, k + 0.25, k + 0.5)

# ------------------------------------------------------------
# 2) Run pricing sensitivity on net revenue
# ------------------------------------------------------------

scenario_testing_results <- objective1_cost_summary %>%
  dplyr::select(horizon, expected_loss, sd) %>%
  crossing(
    expense_ratio = expense_grid,
    k_value = k_grid
  ) %>%
  mutate(
    risk_margin = k_value * sd,
    premium = (expected_loss + risk_margin) / (1 - expense_ratio - p),
    returns = premium,
    expenses = expense_ratio * premium,
    profit_loading = p * premium,
    net_revenue = premium - expected_loss - expenses
  )

scenario_testing_results

# ------------------------------------------------------------
# 3) Short-term net revenue table
# ------------------------------------------------------------

short_term_net_revenue_table <- scenario_testing_results %>%
  filter(horizon == "short_term") %>%
  mutate(expense_ratio = as.character(expense_ratio)) %>%
  dplyr::select(k_value, expense_ratio, net_revenue) %>%
  pivot_wider(
    names_from = expense_ratio,
    values_from = net_revenue
  ) %>%
  arrange(k_value)

short_term_net_revenue_table

# Rounded version
short_term_net_revenue_table_round <- short_term_net_revenue_table %>%
  mutate(across(-k_value, ~ round(.x, 0)))

short_term_net_revenue_table_round

# ------------------------------------------------------------
# 4) Long-term net revenue table
# ------------------------------------------------------------

long_term_net_revenue_table <- scenario_testing_results %>%
  filter(horizon == "long_term_10yr_npv") %>%
  mutate(expense_ratio = as.character(expense_ratio)) %>%
  dplyr::select(k_value, expense_ratio, net_revenue) %>%
  pivot_wider(
    names_from = expense_ratio,
    values_from = net_revenue
  ) %>%
  arrange(k_value)

long_term_net_revenue_table

# Rounded version
long_term_net_revenue_table_round <- long_term_net_revenue_table %>%
  mutate(across(-k_value, ~ round(.x, 0)))

long_term_net_revenue_table_round

