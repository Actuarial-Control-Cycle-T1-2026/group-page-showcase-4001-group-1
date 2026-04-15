library(MASS)
library(dplyr)

# -----------------------------
# Claim_count: Create Poisson Model
# -----------------------------
# With distance
freq_pois_dist <- glm(
  claim_count ~ route_risk +
    pilot_experience +
    vessel_age +
    solar_radiation +
    debris_density +
    cargo_type +
    container_type +
    cargo_value +
    weight +
    distance,
  family = poisson(link = "log"),
  offset = log(exposure),
  data = freq_data
)

# With transit_duration
freq_pois_tran <- glm(
  claim_count ~ route_risk +
    pilot_experience +
    vessel_age +
    solar_radiation +
    debris_density +
    cargo_type +
    container_type +
    cargo_value +
    weight +
    transit_duration,
  family = poisson(link = "log"),
  offset = log(exposure),
  data = freq_data
)

# -----------------------------
# Claim_count: Create Negative Binomial Model
# -----------------------------
freq_data$log_exposure <- log(freq_data$exposure)

# With distance
freq_nb_dist <- glm.nb(
  claim_count ~ route_risk +
    pilot_experience +
    vessel_age +
    solar_radiation +
    debris_density +
    cargo_type +
    container_type +
    cargo_value +
    weight +
    distance +
    offset(log_exposure),
  data = freq_data
)

# With transit_duration
freq_nb_tran <- glm.nb(
  claim_count ~ route_risk +
    pilot_experience +
    vessel_age +
    solar_radiation +
    debris_density +
    cargo_type +
    container_type +
    cargo_value +
    weight +
    transit_duration +
    offset(log_exposure),
  data = freq_data
)

# -----------------------------
# Test model performance and predict outcomes
# -----------------------------
AIC(freq_pois_dist, freq_pois_tran, freq_nb_dist, freq_nb_tran)
BIC(freq_pois_dist, freq_pois_tran, freq_nb_dist, freq_nb_tran)

freq_data <- freq_data %>%
  mutate(
    pred_count = predict(freq_nb_dist, newdata = freq_data, type = "response")
  )

# -----------------------------
# Claim_amount: Create Gamma Model
# -----------------------------
sev_gamma <- glm(
  claim_amount ~ route_risk +
    pilot_experience +
    vessel_age +
    solar_radiation +
    debris_density +
    cargo_type +
    container_type +
    cargo_value +
    weight +
    distance,
  family = Gamma(link = "log"),
  data = sev_data
)

# -----------------------------
# Claim_amount: Create Lognormal Model
# -----------------------------
sev_lognorm <- glm(
  log(claim_amount) ~ route_risk +
    pilot_experience +
    vessel_age +
    solar_radiation +
    debris_density +
    cargo_type +
    container_type +
    cargo_value +
    weight +
    distance,
  family = gaussian(),
  data = sev_data
)

# -----------------------------
# Test model performance and predict future outcomes
# -----------------------------
AIC(sev_gamma, sev_lognorm)
BIC(sev_gamma, sev_lognorm)

sev_data$pred_log_amount <- predict(sev_lognorm, newdata = sev_data, type = "response")
