library(dplyr)
library(tibble)
library(readxl)

# -------------------------------------------------
# Expected Loss Distribution
# -------------------------------------------------
sigma2 <- summary(sev_lognorm)$dispersion

sev_data <- sev_data %>%
  mutate(
    pred_severity = exp(pred_log_amount + 0.5 * sigma2)
  )

baseline_freq <- mean(freq_data$pred_count)
baseline_sev  <- mean(sev_data$pred_severity)

# -------------------------------------------------
# 1) Enter current information from quarry_inventory
# -------------------------------------------------
future_vessels <- tibble(
  vessel = c("DeepSpace Haul Box",
             "DockArc Freight Case",
             "HardSeal Transit Crate",
             "LongHaul Value Canister",
             "Quantum Crate Module"),
  max_volume = c(25000, 50000, 100000, 150000, 250000),
  helionis = c(58, 116, 580, 232, 174),
  bayesia  = c(56, 113, 564, 226, 169),
  oryn     = c(39, 77, 387, 155, 116)
)

total_quantity <- sum(
  future_vessels$helionis + 
    future_vessels$bayesia + 
    future_vessels$oryn
)

# -------------------------------------------------
# 2) Build capacity-weighted exposure proxy
# -------------------------------------------------
# Exposure proxy = sum(quantity × maximum volume)

system_exposure <- tibble(
  solar_system = c("Helionis Cluster", 
                   "Bayesia System",
                   "Oryn Delta"),
  capacity_proxy = c(
    sum(future_vessels$max_volume * future_vessels$helionis),
    sum(future_vessels$max_volume * future_vessels$bayesia),
    sum(future_vessels$max_volume * future_vessels$oryn)
  ),
  risk_index = c(1.05, 0.9, 1.15)
)

# -------------------------------------------------
# 3) Monte-Carlo Simulation: Project future loss by solar system
# -------------------------------------------------
# Frequency baseline is affected by total volume, exposure capacity and risk index
system_exposure <- system_exposure %>%
  mutate(
    exposure_index = capacity_proxy / sum(capacity_proxy),
    projected_freq = total_quantity * exposure_index * baseline_freq * risk_index,
    projected_sev = baseline_sev,
    projected_loss = projected_freq * projected_sev
  )

set.seed(123)
n_sim <- 100000
theta_nb <- freq_nb_dist$theta
sigma2 <- summary(sev_lognorm)$dispersion
sigma <- sqrt(sigma2)
mu_log <- log(baseline_sev) - 0.5 * sigma2
sim_results <- numeric(n_sim)
claim_cap <- 678000000

for (s in 1:n_sim) {
  total_loss <- 0
  
  for (j in 1:nrow(system_exposure)) {
    lambda_j <- system_exposure$projected_freq[j]
    n_claims_j <- rnbinom(1, size = theta_nb, mu = lambda_j)
    
    if (n_claims_j > 0) {
      claim_sizes <- pmin(
        rlnorm(n_claims_j, meanlog = mu_log, sdlog = sigma),
        claim_cap
      )
      total_loss <- total_loss + sum(claim_sizes)
    }
  }
  
  sim_results[s] <- total_loss
}

# -------------------------------------------------
# Inflation and Interest rate file
# -------------------------------------------------
library(readxl)
econ_data <- read_excel("Downloads/SOA_2026_Case_Study_Materials/srcsc-2026-interest-and-inflation.xlsx",
                        skip = 2)
colnames(econ_data) <- 
  c("year", "inflation", "overnight rate", "spot_1y", "spot_10y")

# -------------------------------------------------
# 1) Build short-term and long-term assumptions
# -------------------------------------------------
short_rate <- mean(econ_data$spot_1y)
long_rate <- mean(econ_data$spot_10y)
infl_rate <- mean(econ_data$inflation)

# Stress Testing
# short_rate <- mean(econ_data$spot_1y[econ_data$year %in% 2171:2173])
# long_rate <- mean(econ_data$spot_10y[econ_data$year %in% 2171:2173])
# infl_rate <- mean(econ_data$inflation[econ_data$year %in% 2171:2173])

# -------------------------------------------------
# 2) EPV of Aggregate cost
# -------------------------------------------------
sim_short <- sim_results * (1 + infl_rate) / (1 + short_rate)
pv_factor_10 <- sum(((1 + infl_rate)^(1:10)) / ((1 + long_rate)^(1:10)))
sim_long <- sim_results * pv_factor_10

quantile(sim_short, c(0.1, 0.50, 0.9))
quantile(sim_long,  c(0.1, 0.50, 0.9))

# -------------------------------------------------
# 3) Report Loss Distribution
# -------------------------------------------------
mean(sim_short == 0)
mean(sim_long == 0)
mean_short <- mean(sim_short)
mean_long <- mean(sim_long)
mean_short
mean_long

var(sim_short)
var(sim_long)

VaR_99_short <- quantile(sim_short, 0.99)
VaR_99_long <- quantile(sim_long, 0.99)

TVaR_99_short <- mean(sim_short[sim_short > VaR_99_short])
TVaR_99_long  <- mean(sim_long[sim_long > VaR_99_long])

VaR_99_short
VaR_99_long
TVaR_99_short
TVaR_99_long

h <- hist(sim_results,
          breaks = 100,
          plot = FALSE)

x_max <- quantile(sim_results, 0.985)

# Cargo Loss Distribution Graph
hist(sim_results,
     breaks = 100,
     xlim = c(0, x_max * 1.05),
     ylim = c(0, max(h$counts) * 1.1),
     main = "Aggregate Cargo Loss Distribution",
     xlab = "Loss (Đ Billions)",
     col = "lightblue",
     border = "white",
     xaxt = "n")
  axis(1,
       at = seq(0, x_max, length.out = 6),
       labels = paste0(round(seq(0, x_max, length.out = 6) / 1e9, 1)))
