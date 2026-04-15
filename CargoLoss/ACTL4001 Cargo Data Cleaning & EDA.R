library(readxl)
library(skimr)
library(dplyr)
library(stringr)
library(tidyr)

cargo_file_path <- "Downloads/SOA_2026_Case_Study_Materials/srcsc-2026-claims-cargo.xlsx"
freq_data <- read_excel(cargo_file_path, sheet = "freq")
sev_data <- read_excel(cargo_file_path, sheet = "sev")

# -----------------------------
# Clean the frequency tab datasheet
# -----------------------------
n_before <- nrow(freq_data)

# -----------------------------
# 1) Handle missing categorical values
# -----------------------------
freq_data <- freq_data %>% 
  filter(!is.na(policy_id), !is.na(shipment_id))

freq_data$cargo_type[is.na(freq_data$cargo_type)] <-"Unknown"
freq_data$cargo_type <- as.factor(freq_data$cargo_type)

freq_data$container_type[is.na(freq_data$container_type)] <- "Unknown"
freq_data$container_type <- as.factor(freq_data$container_type)

# -----------------------------
# 2) Drop rows with missing numeric values
# -----------------------------
numeric_var <- c("cargo_value", "weight", "route_risk", "distance", "transit_duration", "pilot_experience",
                 "vessel_age", "solar_radiation", "debris_density", "exposure", "claim_count")

freq_data <- freq_data %>% drop_na(all_of(numeric_var))

# -----------------------------
# 3) Check validity of numerical values
# -----------------------------
freq_data <- freq_data %>%
  filter(
    between(cargo_value, 50000, 680000000),
    between(weight, 1500, 250000),
    route_risk %in% 1:5,
    between(distance, 1, 100),
    between(transit_duration, 1, 60),
    between(pilot_experience, 1, 30),
    between(vessel_age, 1, 50),
    between(solar_radiation, 0, 1),
    between(debris_density, 0, 1),
    between(exposure, 0, 1),
    between(claim_count, 0, 5)
  )

# -----------------------------
# 4) Ensure valid categorical structure
# -----------------------------
freq_data <- freq_data %>%
  mutate(
    policy_id = str_trim(policy_id),
    shipment_id = str_trim(shipment_id),
    policy_id = str_remove(policy_id, "_.*"),
    shipment_id = str_remove(shipment_id, "_.*"),
    container_type = str_trim(container_type),
    container_type = str_remove(container_type, "_.*"),
    cargo_type = str_trim(cargo_type),
    cargo_type = str_remove(cargo_type, "_.*"),
    container_type = as.factor(container_type),
    cargo_type = as.factor(cargo_type)
  )

# -----------------------------
# 5) Analysis of frequency datasheet 
# -----------------------------
n_after <- nrow(freq_data)

# 4.9759% of rows have been removed
cat("Rows removed:", n_before - n_after, "\n")
cat("Percent removed:", round((n_before - n_after)/n_before * 100, 4), "%\n")

skim(freq_data)
mean(freq_data$claim_count)
var(freq_data$claim_count)

# -----------------------------
# Clean the severity datasheet
# -----------------------------
n_before_sev <- nrow(sev_data)

# -----------------------------
# 1) Drop rows with missing values
# -----------------------------
sev_data <- sev_data %>%
  filter(!is.na(claim_id), !is.na(policy_id), !is.na(shipment_id), !is.na(claim_seq),
         !is.na(cargo_type), !is.na(container_type))
n_after_sev <- nrow(sev_data)

numeric_var <- c("cargo_value", "weight", "route_risk", "distance", "transit_duration", "pilot_experience",
                 "vessel_age", "solar_radiation", "debris_density", "exposure", "claim_amount")

sev_data <- sev_data %>% drop_na(all_of(numeric_var))

# -----------------------------
# 2) Check validity of numerical values
# -----------------------------
sev_data <- sev_data %>%
  filter(
    between(cargo_value, 50000, 680000000),
    between(weight, 1500, 250000),
    route_risk %in% 1:5,
    between(distance, 1, 100),
    between(transit_duration, 1, 60),
    between(pilot_experience, 1, 30),
    between(vessel_age, 1, 50),
    between(solar_radiation, 0, 1),
    between(debris_density, 0, 1),
    between(exposure, 0, 1)
  )

# -----------------------------
# 3) Check claim sequence validity
# -----------------------------
sev_data <- sev_data %>%
  filter(
    claim_seq >= 1,
    claim_seq == floor(claim_seq))

# -----------------------------
# 4) Check validity of categorical structure
# -----------------------------
sev_data <- sev_data %>%
  mutate(
    claim_id = str_trim(claim_id),
    policy_id = str_trim(policy_id),
    shipment_id = str_trim(shipment_id),
    claim_id = str_remove(claim_id, "_.*"),
    policy_id = str_remove(policy_id, "_.*"),
    shipment_id = str_remove(shipment_id, "_.*"),
    cargo_type = str_trim(cargo_type),
    container_type = str_trim(container_type),
    cargo_type = str_remove(cargo_type, "_.*"),
    container_type = str_remove(container_type, "_.*"),
    cargo_type = as.factor(cargo_type),
    container_type = as.factor(container_type)
  )
n_after_sev <- nrow(sev_data)

# lower range of claim_amount is the lower 0.5% quantile
lower <- quantile(sev_data$claim_amount, 0.005, na.rm = TRUE)

sev_data <- sev_data %>%
  filter(
    !is.na(claim_amount),
    claim_amount >= lower,
    claim_amount <= 678000000
  )

# -----------------------------
# 5) Analysis of severity datasheet 
# -----------------------------
n_after_sev <- nrow(sev_data)

# Lost 6.5253% of my data
cat("Rows removed:", n_before_sev - n_after_sev, "\n")
cat("Percent removed:", round((n_before_sev - n_after_sev)/n_before_sev * 100, 4), "%\n")

