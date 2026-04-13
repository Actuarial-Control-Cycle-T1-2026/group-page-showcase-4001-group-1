library(tidyverse)
library(readxl)

#Set working directory to continue

## Reading in the data
bi_freq = read_excel("srcsc-2026-claims-business-interruption.xlsx", sheet = 1)
bi_sev  = read_excel("srcsc-2026-claims-business-interruption.xlsx", sheet = 2)

cargo_freq = read_excel("srcsc-2026-claims-cargo.xlsx", sheet = 1)
cargo_sev  = read_excel("srcsc-2026-claims-cargo.xlsx", sheet = 2)

equip_freq = read_excel("srcsc-2026-claims-equipment-failure.xlsx", sheet = 1)
equip_sev  = read_excel("srcsc-2026-claims-equipment-failure.xlsx", sheet = 2)

work_freq = read_excel("srcsc-2026-claims-workers-comp.xlsx", sheet = 1)
work_sev  = read_excel("srcsc-2026-claims-workers-comp.xlsx", sheet = 2)

# the below remaps the numerical data to their correct ranges. 

# Cleaning BI data
##### 
summary(bi_freq)
cols_to_plot = setdiff(names(bi_freq), c("policy_id", "station_id", "solar_system"))
for(col in cols_to_plot) {
  hist(bi_freq[[col]],
       main = paste("Histogram of", col),
       xlab = col,
       ylab = "Frequency",
       col = "lightblue",
       breaks = 30)
}

sapply(bi_freq, function(x) sum(is.na(x)))

# filling in NAs for policy number.
# noted that pol num is iterative, blanks can be filled in with the index
bi_freq$policy_id = ifelse(
  is.na(bi_freq$policy_id),
  sprintf("BI-%06d", seq_len(nrow(bi_freq))),
  bi_freq$policy_id
)
# checking uniqueness
length(unique(bi_freq$policy_id))
dim(bi_freq)

# fixing solar system
bi_freq$solar_system = sub("_.*$", "", bi_freq$solar_system)
table(bi_freq$solar_system)

# mapping production load to correct values, range from 0 to 1
bi_freq$production_load = pmin(pmax(bi_freq$production_load, 0), 1)

# mapping energy backup to correct values, {1, 2, 3, 4, 5}
bi_freq$energy_backup_score = pmin(pmax(bi_freq$energy_backup_score, 1), 5)

# mapping supply chain to correct values, range from 0 to 1
bi_freq$supply_chain_index = pmin(pmax(bi_freq$supply_chain_index, 0), 1)

# mapping avg crew exp to correct values, range from 1 to 30
bi_freq$avg_crew_exp = pmin(pmax(bi_freq$avg_crew_exp, 1), 30)

# mapping maintenance to correct values, range from 0 to 6
bi_freq$maintenance_freq = pmin(pmax(bi_freq$maintenance_freq, 0), 6)

# mapping safety_compliance to correct values, {1, 2, 3, 4, 5}
bi_freq$safety_compliance = pmin(pmax(bi_freq$safety_compliance, 1), 5)

# mapping exposure to correct values, range from 0 to 1
bi_freq$exposure = pmin(pmax(bi_freq$exposure, 0), 1)

# mapping claim count to correct values, range from 0 to 4
bi_freq$claim_count = pmin(pmax(bi_freq$claim_count, 0), 4)


summary(bi_freq)
for(col in cols_to_plot) {
  hist(bi_freq[[col]],
       main = paste("Histogram of", col),
       xlab = col,
       ylab = "Frequency",
       col = "lightblue",
       breaks = 30)
}


# sev data
summary(bi_sev)

bi_sev$claim_id <- ifelse(
  is.na(bi_sev$claim_id),
  sprintf("BI-C-%07d", seq_len(nrow(bi_sev))),
  bi_sev$claim_id
)

length(unique(bi_sev$claim_id))
dim(bi_sev)

bi_sev$solar_system = sub("_.*$", "", bi_sev$solar_system)
bi_sev$production_load = pmin(pmax(bi_sev$production_load, 0), 1)
bi_sev$exposure = pmin(pmax(bi_sev$exposure, 0), 1)
bi_sev$energy_backup_score = pmin(pmax(bi_sev$energy_backup_score, 1), 5)
bi_sev$safety_compliance = pmin(pmax(bi_sev$safety_compliance, 1), 5)
bi_sev$neg_claim = bi_sev$claim_amount < 0
bi_sev = bi_sev %>%
  group_by(policy_id) %>%
  mutate(claim_seq = ifelse(
    is.na(policy_id),
    1,                  # NA policy_id -> claim_seq = 1
    row_number()        # non-NA policy_id -> 1,2,3...
  )) %>%
  ungroup()


cols = c("solar_system", "production_load", "exposure",
         "energy_backup_score", "safety_compliance")
bi_sev = bi_sev %>%
  left_join(
    bi_freq %>% select(policy_id, all_of(cols)),
    by = "policy_id",
    suffix = c("", "_freq")
  ) %>%
  mutate(
    mismatch_flag = as.integer(
      pmap_lgl(
        select(., all_of(cols), ends_with("_freq")),
        function(...) {
          vals = list(...)
          n = length(vals)/2
          any(sapply(1:n, function(i) {
            x = vals[[i]]
            y = vals[[i + n]]
            is.na(x) != is.na(y) || (!is.na(x) & !is.na(y) & x != y)
          }))
        }
      )
    )
  ) %>%
  select(-ends_with("_freq"))

claim_count = bi_sev %>%
  group_by(policy_id) %>%
  summarise(
    claim_count = max(claim_seq, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(claim_count = pmax(0, claim_count))

bi_freq = bi_freq %>%
  select(-claim_count) %>%
  left_join(claim_count, by = "policy_id")
bi_freq$claim_count[is.na(bi_freq$claim_count)] = 0

summary(bi_freq)
summary(bi_sev)

#####



# Cleaning cargo data
#####
summary(cargo_freq)
cols_to_plot = setdiff(names(cargo_freq), c("policy_id", "shipment_id", "cargo_type", "container_type"))
for(col in cols_to_plot) {
  hist(cargo_freq[[col]],
       main = paste("Histogram of", col),
       xlab = col,
       ylab = "Frequency",
       col = "lightblue",
       breaks = 30)
}

sapply(cargo_freq, function(x) sum(is.na(x)))

cargo_freq$cargo_value[cargo_freq$cargo_value < 50000] = 50000
cargo_freq$weight[cargo_freq$weight < 1500] = 1500
cargo_freq$route_risk = pmin(pmax(cargo_freq$route_risk, 1), 5)
cargo_freq$distance = pmin(pmax(cargo_freq$distance, 1), 100)
cargo_freq$transit_duration = pmin(pmax(cargo_freq$transit_duration, 1), 60)
cargo_freq$pilot_experience = pmin(pmax(cargo_freq$pilot_experience, 1), 30)
cargo_freq$vessel_age = pmin(pmax(cargo_freq$vessel_age, 1), 50)
cargo_freq$solar_radiation = pmin(pmax(cargo_freq$solar_radiation, 0), 1)
cargo_freq$debris_density = pmin(pmax(cargo_freq$debris_density, 0), 1)
cargo_freq$exposure = pmin(pmax(cargo_freq$exposure, 0), 1)
cargo_freq$claim_count = pmin(pmax(cargo_freq$claim_count, 0), 5)
cargo_freq$policy_shipment_id = paste(cargo_freq$policy_id, cargo_freq$shipment_id, sep = "_")

dim(cargo_freq)
length(unique(cargo_freq$policy_shipment_id))

# sev data
summary(cargo_sev)
cargo_sev$policy_shipment_id = paste(cargo_sev$policy_id, cargo_sev$shipment_id, sep = "_")
cargo_sev = cargo_sev %>%
  group_by(policy_id) %>%
  mutate(claim_seq = ifelse(
    is.na(policy_id),
    1,                  # NA policy_id -> claim_seq = 1
    row_number()        # non-NA policy_id -> 1,2,3...
  )) %>%
  ungroup()
cargo_sev$cargo_value[cargo_sev$cargo_value < 50000] = 50000
cargo_sev$weight[cargo_sev$weight < 1500] = 1500
cargo_sev$route_risk = pmin(pmax(cargo_sev$route_risk, 1), 5)
cargo_sev$distance = pmin(pmax(cargo_sev$distance, 1), 100)
cargo_sev$transit_duration = pmin(pmax(cargo_sev$transit_duration, 1), 60)
cargo_sev$pilot_experience = pmin(pmax(cargo_sev$pilot_experience, 1), 30)
cargo_sev$vessel_age = pmin(pmax(cargo_sev$vessel_age, 1), 50)
cargo_sev$solar_radiation = pmin(pmax(cargo_sev$solar_radiation, 0), 1)
cargo_sev$debris_density = pmin(pmax(cargo_sev$debris_density, 0), 1)
cargo_sev$exposure = pmin(pmax(cargo_sev$exposure, 0), 1)
cargo_sev$neg_claim = cargo_sev$claim_amount < 0


cols = c("cargo_type", "cargo_value", "weight", "route_risk",
         "distance", "transit_duration", "pilot_experience", "vessel_age", 
         "container_type", "solar_radiation", "debris_density", "exposure")
cargo_sev = cargo_sev %>%
  left_join(
    cargo_freq %>% select(policy_shipment_id, all_of(cols)),
    by = "policy_shipment_id",
    suffix = c("", "_freq")
  ) %>%
  mutate(
    mismatch_flag = as.integer(
      pmap_lgl(
        select(., all_of(cols), ends_with("_freq")),
        function(...) {
          vals = list(...)
          n = length(vals)/2
          any(sapply(1:n, function(i) {
            x = vals[[i]]
            y = vals[[i + n]]
            is.na(x) != is.na(y) || (!is.na(x) & !is.na(y) & x != y)
          }))
        }
      )
    )
  ) %>%
  select(-ends_with("_freq"))
cargo_sev$claim_id = ifelse(
  is.na(cargo_sev$claim_id),
  sprintf("CAR-C-%07d", seq_len(nrow(cargo_sev))),
  cargo_sev$claim_id
)

claim_count = cargo_sev %>%
  group_by(policy_id) %>%
  summarise(
    claim_count = max(claim_seq, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(claim_count = pmax(0, claim_count))

cargo_freq = cargo_freq %>%
  select(-claim_count) %>%
  left_join(claim_count, by = "policy_id")
cargo_freq$claim_count[is.na(cargo_freq$claim_count)] = 0

length(unique(cargo_sev$claim_id))
dim(cargo_sev)

summary(cargo_freq)
summary(cargo_sev)
#####



# cleaning equipment failure data
#####
summary(equip_freq)
cols_to_plot = setdiff(names(equip_freq), c("policy_id", "equipment_id", "equipment_type", "solar_system"))
for(col in cols_to_plot) {
  hist(equip_freq[[col]],
       main = paste("Histogram of", col),
       xlab = col,
       ylab = "Frequency",
       col = "lightblue",
       breaks = 30)
}

sapply(equip_freq, function(x) sum(is.na(x)))

equip_freq$equipment_id = sub("_.*$", "", equip_freq$equipment_id)
equip_freq$equipment_type = sub("_.*$", "", equip_freq$equipment_type)
equip_freq$equipment_age = pmin(pmax(equip_freq$equipment_age, 0), 10)
equip_freq$solar_system = sub("_.*$", "", equip_freq$solar_system)
equip_freq$maintenance_int = pmin(pmax(equip_freq$maintenance_int, 100), 5000)
equip_freq$usage_int = pmin(pmax(equip_freq$usage_int, 0), 24)
equip_freq$exposure = pmin(pmax(equip_freq$exposure, 0), 1)
equip_freq$policy_equip_id = paste(equip_freq$policy_id, equip_freq$equipment_id, sep = "_")

# sev data
summary(equip_sev)

equip_sev$claim_id_2 = sprintf("EF-C-%07d", seq_len(nrow(equip_sev)))
equip_sev$equipment_id = sub("_.*$", "", equip_sev$equipment_id)
equip_sev$equipment_type = sub("_.*$", "", equip_sev$equipment_type)
equip_sev$equipment_age = pmin(pmax(equip_sev$equipment_age, 0), 10)
equip_sev$solar_system = sub("_.*$", "", equip_sev$solar_system)
equip_sev$maintenance_int = pmin(pmax(equip_sev$maintenance_int, 100), 5000)
equip_sev$usage_int = pmin(pmax(equip_sev$usage_int, 0), 24)
equip_sev$exposure = pmin(pmax(equip_sev$exposure, 0), 1)
equip_sev$neg_claim = equip_sev$claim_amount < 0
equip_sev$policy_equip_id = paste(equip_sev$policy_id, equip_sev$equipment_id, sep = "_")
equip_sev = equip_sev %>%
  group_by(policy_id) %>%
  mutate(claim_seq = ifelse(
    is.na(policy_id),
    1,                  # NA policy_id -> claim_seq = 1
    row_number()        # non-NA policy_id -> 1,2,3...
  )) %>%
  ungroup()

cols = c("equipment_id", "equipment_type", "equipment_age", "solar_system",
         "maintenance_int", "usage_int", "exposure")
equip_sev = equip_sev %>%
  left_join(
    equip_freq %>% select(policy_equip_id, all_of(cols)),
    by = "policy_equip_id",
    suffix = c("", "_freq")
  ) %>%
  mutate(
    mismatch_flag = as.integer(
      pmap_lgl(
        select(., all_of(cols), ends_with("_freq")),
        function(...) {
          vals = list(...)
          n = length(vals)/2
          any(sapply(1:n, function(i) {
            x = vals[[i]]
            y = vals[[i + n]]
            is.na(x) != is.na(y) || (!is.na(x) & !is.na(y) & x != y)
          }))
        }
      )
    )
  ) %>%
  select(-ends_with("_freq"))

claim_count = equip_sev %>%
  group_by(policy_id) %>%
  summarise(
    claim_count = max(claim_seq, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(claim_count = pmax(0, claim_count))

equip_freq = equip_freq %>%
  select(-claim_count) %>%
  left_join(claim_count, by = "policy_id")
equip_freq$claim_count[is.na(equip_freq$claim_count)] = 0

summary(equip_freq)
summary(equip_sev)


# Noted that claim_id in the raw data is not unique. 
# Some pols have the same claim_id for many rows
# In the cleaning process claim ID was made unique. This inflated claim_seq for some pols
equip_sev %>%
  group_by(policy_id) %>%
  filter(max(claim_seq, na.rm = TRUE) > 3) %>%
  ungroup() %>%
  arrange(policy_id, claim_seq)

#####


# Cleaning workers comp data
#####
summary(work_freq)
cols_to_plot = setdiff(names(work_freq), c("policy_id", "worker_id", "solar_system", "station_id", 
                                           "occupation", "employment_type"))
for(col in cols_to_plot) {
  hist(work_freq[[col]],
       main = paste("Histogram of", col),
       xlab = col,
       ylab = "Frequency",
       col = "lightblue",
       breaks = 30)
}

sapply(work_freq, function(x) sum(is.na(x)))

work_freq$policy_id = sub("_.*$", "", work_freq$policy_id)
work_freq = work_freq %>%
  fill(policy_id, .direction = "down")
work_freq$worker_id = sub("_.*$", "", work_freq$worker_id)
work_freq$worker_id = ifelse(
  is.na(work_freq$worker_id),
  sprintf("W-%05d", seq_len(nrow(work_freq))),
  work_freq$worker_id
)
work_freq$solar_system = sub("_.*$", "", work_freq$solar_system)
work_freq$occupation = sub("_.*$", "", work_freq$occupation)
work_freq$employment_type = sub("_.*$", "", work_freq$employment_type)
work_freq$experience_yrs = pmin(pmax(work_freq$experience_yrs, 0.2), 40)
work_freq$accident_history_flag = pmin(pmax(work_freq$accident_history_flag, 0), 1)
work_freq$psych_stress_index = pmin(pmax(work_freq$psych_stress_index, 1), 5)
work_freq$hours_per_week = pmin(pmax(work_freq$hours_per_week, 20), 40)
work_freq$supervision_level = pmin(pmax(work_freq$supervision_level, 0), 1)
work_freq$gravity_level = pmin(pmax(work_freq$gravity_level, 0.75), 1.50)
work_freq$safety_training_index = pmin(pmax(work_freq$safety_training_index, 1), 5)
work_freq$protective_gear_quality = pmin(pmax(work_freq$protective_gear_quality, 1), 5)
work_freq$base_salary = pmax(work_freq$base_salary, 0)
work_freq$exposure = pmin(pmax(work_freq$exposure, 0), 1)
work_freq$policy_work_id = paste(work_freq$policy_id, work_freq$worker_id, sep = "_")

# sev data
summary(work_sev)
work_sev$policy_id = sub("_.*$", "", work_sev$policy_id)
work_sev$worker_id = sub("_.*$", "", work_sev$worker_id)
work_sev$solar_system = sub("_.*$", "", work_sev$solar_system)
work_sev$occupation = sub("_.*$", "", work_sev$occupation)
work_sev$employment_type = sub("_.*$", "", work_sev$employment_type)
work_sev$experience_yrs = pmin(pmax(work_sev$experience_yrs, 0.2), 40)
work_sev$accident_history_flag = pmin(pmax(work_sev$accident_history_flag, 0), 1)
work_sev$psych_stress_index = pmin(pmax(work_sev$psych_stress_index, 1), 5)
work_sev$hours_per_week = pmin(pmax(work_sev$hours_per_week, 20), 40)
work_sev$supervision_level = pmin(pmax(work_sev$supervision_level, 0), 1)
work_sev$gravity_level = pmin(pmax(work_sev$gravity_level, 0.75), 1.50)
work_sev$safety_training_index = pmin(pmax(work_sev$safety_training_index, 1), 5)
work_sev$protective_gear_quality = pmin(pmax(work_sev$protective_gear_quality, 1), 5)
work_sev$base_salary = pmax(work_sev$base_salary, 0)
work_sev$exposure = pmin(pmax(work_sev$exposure, 0), 1)
work_sev$injury_type = sub("_.*$", "", work_sev$injury_type)
work_sev$injury_cause = sub("_.*$", "", work_sev$injury_cause)
work_sev$claim_length = pmin(pmax(work_sev$claim_length, 3), 1000)

work_sev$policy_work_id = paste(work_sev$policy_id, work_sev$worker_id, sep = "_")
work_sev = work_sev %>%
  group_by(policy_work_id) %>%
  mutate(claim_seq = ifelse(
    is.na(policy_work_id),
    1,                  # NA policy_id -> claim_seq = 1
    row_number()        # non-NA policy_id -> 1,2,3...
  )) %>%
  ungroup()

cols = setdiff(names(work_freq), c("policy_id", "worker_id", "claim_count"))
work_sev = work_sev %>%
  left_join(
    work_freq %>% select(policy_work_id, all_of(cols)),
    by = "policy_work_id",
    suffix = c("", "_freq")
  ) %>%
  mutate(
    mismatch_flag = as.integer(
      pmap_lgl(
        select(., all_of(cols), ends_with("_freq")),
        function(...) {
          vals = list(...)
          n = length(vals)/2
          any(sapply(1:n, function(i) {
            x = vals[[i]]
            y = vals[[i + n]]
            is.na(x) != is.na(y) || (!is.na(x) & !is.na(y) & x != y)
          }))
        }
      )
    )
  ) %>%
  select(-ends_with("_freq"))


claim_count = work_sev %>%
  group_by(policy_work_id) %>%
  summarise(
    claim_count = max(claim_seq, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(claim_count = pmax(0, claim_count))

work_freq = work_freq %>%
  select(-claim_count) %>%
  left_join(claim_count, by = "policy_work_id")
equip_freq$claim_count[is.na(equip_freq$claim_count)] = 0

# work_sev %>%
#   filter(mismatch_flag == T)

summary(work_freq)
summary(work_sev)
#####


##########
#EDA
##########

theme_set(
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5),
      axis.title = element_text(face = "bold"),
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid.minor = element_blank()
    )
)

#####
# BUSINESS INTERRUPTION EDA
#####

dir.create("EDA_BI", showWarnings = FALSE)

bi_freq$solar_system <- as.factor(bi_freq$solar_system)
bi_freq$energy_backup_score <- as.factor(bi_freq$energy_backup_score)
bi_freq$safety_compliance <- as.factor(bi_freq$safety_compliance)

bi_sev$solar_system <- as.factor(bi_sev$solar_system)
bi_sev$energy_backup_score <- as.factor(bi_sev$energy_backup_score)
bi_sev$safety_compliance <- as.factor(bi_sev$safety_compliance)

p1 <- ggplot(bi_freq, aes(x = solar_system)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "BI Frequency: Solar System", x = "Solar System", y = "Count")
p1
ggsave("EDA_BI/bi_freq_solar_system.png", p1, width = 7, height = 5)

p2 <- ggplot(bi_freq, aes(x = energy_backup_score)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "BI Frequency: Energy Backup Score", x = "Energy Backup Score", y = "Count")
p2
ggsave("EDA_BI/bi_freq_energy_backup_score.png", p2, width = 7, height = 5)

p3 <- ggplot(bi_freq, aes(x = safety_compliance)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "BI Frequency: Safety Compliance", x = "Safety Compliance", y = "Count")
p3
ggsave("EDA_BI/bi_freq_safety_compliance.png", p3, width = 7, height = 5)

p4 <- ggplot(bi_freq, aes(x = production_load)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "BI Frequency: Production Load", x = "Production Load", y = "Frequency")
p4
ggsave("EDA_BI/bi_freq_production_load.png", p4, width = 7, height = 5)

p5 <- ggplot(bi_freq, aes(x = supply_chain_index)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "BI Frequency: Supply Chain Index", x = "Supply Chain Index", y = "Frequency")
p5
ggsave("EDA_BI/bi_freq_supply_chain_index.png", p5, width = 7, height = 5)

p6 <- ggplot(bi_freq, aes(x = avg_crew_exp)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "BI Frequency: Average Crew Experience", x = "Average Crew Experience", y = "Frequency")
p6
ggsave("EDA_BI/bi_freq_avg_crew_exp.png", p6, width = 7, height = 5)

p7 <- ggplot(bi_freq, aes(x = maintenance_freq)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "BI Frequency: Maintenance Frequency", x = "Maintenance Frequency", y = "Frequency")
p7
ggsave("EDA_BI/bi_freq_maintenance_freq.png", p7, width = 7, height = 5)

p8 <- ggplot(bi_freq, aes(x = exposure)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "BI Frequency: Exposure", x = "Exposure", y = "Frequency")
p8
ggsave("EDA_BI/bi_freq_exposure.png", p8, width = 7, height = 5)

p9 <- ggplot(bi_freq, aes(x = claim_count)) +
  geom_histogram(binwidth = 1, fill = "skyblue3", colour = "black", boundary = -0.5) +
  labs(title = "BI Frequency: Claim Count", x = "Claim Count", y = "Frequency")
p9
ggsave("EDA_BI/bi_freq_claim_count.png", p9, width = 7, height = 5)

p10 <- ggplot(bi_sev, aes(x = claim_amount)) +
  geom_histogram(bins = 30, fill = "mediumpurple3", colour = "black") +
  labs(title = "BI Severity: Claim Amount", x = "Claim Amount", y = "Frequency")
p10
ggsave("EDA_BI/bi_sev_claim_amount.png", p10, width = 7, height = 5)

p11 <- ggplot(bi_sev %>% filter(claim_amount > 0), aes(x = log(claim_amount))) +
  geom_histogram(bins = 30, fill = "mediumpurple3", colour = "black") +
  labs(title = "BI Severity: Log Claim Amount", x = "log(Claim Amount)", y = "Frequency")
p11
ggsave("EDA_BI/bi_sev_log_claim_amount.png", p11, width = 7, height = 5)

p12 <- ggplot(bi_freq, aes(x = solar_system, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Solar System", x = "Solar System", y = "Claim Count")
p12
ggsave("EDA_BI/bi_freq_claimcount_by_solar_system.png", p12, width = 7, height = 5)

p13 <- ggplot(bi_freq, aes(x = energy_backup_score, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Energy Backup Score", x = "Energy Backup Score", y = "Claim Count")
p13
ggsave("EDA_BI/bi_freq_claimcount_by_energy_backup_score.png", p13, width = 7, height = 5)

p14 <- ggplot(bi_freq, aes(x = safety_compliance, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Safety Compliance", x = "Safety Compliance", y = "Claim Count")
p14
ggsave("EDA_BI/bi_freq_claimcount_by_safety_compliance.png", p14, width = 7, height = 5)

p15 <- ggplot(bi_freq, aes(x = production_load, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Production Load", x = "Production Load", y = "Claim Count")
p15
ggsave("EDA_BI/bi_freq_claimcount_vs_production_load.png", p15, width = 7, height = 5)

p16 <- ggplot(bi_freq, aes(x = supply_chain_index, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Supply Chain Index", x = "Supply Chain Index", y = "Claim Count")
p16
ggsave("EDA_BI/bi_freq_claimcount_vs_supply_chain_index.png", p16, width = 7, height = 5)

p17 <- ggplot(bi_freq, aes(x = avg_crew_exp, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Average Crew Experience", x = "Average Crew Experience", y = "Claim Count")
p17
ggsave("EDA_BI/bi_freq_claimcount_vs_avg_crew_exp.png", p17, width = 7, height = 5)

p18 <- ggplot(bi_freq, aes(x = maintenance_freq, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Maintenance Frequency", x = "Maintenance Frequency", y = "Claim Count")
p18
ggsave("EDA_BI/bi_freq_claimcount_vs_maintenance_freq.png", p18, width = 7, height = 5)

p19 <- ggplot(bi_freq, aes(x = exposure, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Exposure", x = "Exposure", y = "Claim Count")
p19
ggsave("EDA_BI/bi_freq_claimcount_vs_exposure.png", p19, width = 7, height = 5)

p20 <- ggplot(bi_sev, aes(x = solar_system, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Solar System", x = "Solar System", y = "Claim Amount")
p20
ggsave("EDA_BI/bi_sev_claimamount_by_solar_system.png", p20, width = 7, height = 5)

p21 <- ggplot(bi_sev, aes(x = energy_backup_score, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Energy Backup Score", x = "Energy Backup Score", y = "Claim Amount")
p21
ggsave("EDA_BI/bi_sev_claimamount_by_energy_backup_score.png", p21, width = 7, height = 5)

p22 <- ggplot(bi_sev, aes(x = safety_compliance, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Safety Compliance", x = "Safety Compliance", y = "Claim Amount")
p22
ggsave("EDA_BI/bi_sev_claimamount_by_safety_compliance.png", p22, width = 7, height = 5)

p23 <- ggplot(bi_sev, aes(x = production_load, y = claim_amount)) +
  geom_point(alpha = 0.5, colour = "darkorchid3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Amount vs Production Load", x = "Production Load", y = "Claim Amount")
p23
ggsave("EDA_BI/bi_sev_claimamount_vs_production_load.png", p23, width = 7, height = 5)

p24 <- ggplot(bi_sev, aes(x = exposure, y = claim_amount)) +
  geom_point(alpha = 0.5, colour = "darkorchid3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Amount vs Exposure", x = "Exposure", y = "Claim Amount")
p24
ggsave("EDA_BI/bi_sev_claimamount_vs_exposure.png", p24, width = 7, height = 5)

# frequency numeric covariance matrix
bi_freq_num <- bi_freq %>%
  select(production_load, supply_chain_index, avg_crew_exp,
         maintenance_freq, exposure, claim_count)

cov_bi_freq <- cov(bi_freq_num, use = "complete.obs")
cov_bi_freq

write.csv(cov_bi_freq, "EDA_BI/cov_bi_freq.csv")

# severity numeric covariance matrix
bi_sev_num <- bi_sev %>%
  select(production_load, exposure, claim_amount)

cov_bi_sev <- cov(bi_sev_num, use = "complete.obs")
cov_bi_sev

write.csv(cov_bi_sev, "EDA_BI/cov_bi_sev.csv")

# correlation matrices
cor_bi_freq <- cor(bi_freq_num, use = "complete.obs")
cor_bi_freq
write.csv(cor_bi_freq, "EDA_BI/cor_bi_freq.csv")

cor_bi_sev <- cor(bi_sev_num, use = "complete.obs")
cor_bi_sev
write.csv(cor_bi_sev, "EDA_BI/cor_bi_sev.csv")

# solar_system vs energy_backup_score
tab1 <- table(bi_freq$solar_system, bi_freq$energy_backup_score)
chi1 <- suppressWarnings(chisq.test(tab1)$statistic)
n1 <- sum(tab1)
r1 <- nrow(tab1)
k1 <- ncol(tab1)
cramers_v_1 <- sqrt(chi1 / (n1 * min(r1 - 1, k1 - 1)))
cramers_v_1

# solar_system vs safety_compliance
tab2 <- table(bi_freq$solar_system, bi_freq$safety_compliance)
chi2 <- suppressWarnings(chisq.test(tab2)$statistic)
n2 <- sum(tab2)
r2 <- nrow(tab2)
k2 <- ncol(tab2)
cramers_v_2 <- sqrt(chi2 / (n2 * min(r2 - 1, k2 - 1)))
cramers_v_2

# energy_backup_score vs safety_compliance
tab3 <- table(bi_freq$energy_backup_score, bi_freq$safety_compliance)
chi3 <- suppressWarnings(chisq.test(tab3)$statistic)
n3 <- sum(tab3)
r3 <- nrow(tab3)
k3 <- ncol(tab3)
cramers_v_3 <- sqrt(chi3 / (n3 * min(r3 - 1, k3 - 1)))
cramers_v_3

# summary table
cramers_v_results <- data.frame(
  variable_1 = c("solar_system", "solar_system", "energy_backup_score"),
  variable_2 = c("energy_backup_score", "safety_compliance", "safety_compliance"),
  cramers_v = c(cramers_v_1, cramers_v_2, cramers_v_3)
)

cramers_v_results
write.csv(cramers_v_results, "EDA_BI/cramers_v_results.csv", row.names = FALSE)

##########
# CARGO EDA
##########

dir.create("EDA_Cargo", showWarnings = FALSE)

cargo_freq$cargo_type <- as.factor(cargo_freq$cargo_type)
cargo_freq$container_type <- as.factor(cargo_freq$container_type)
cargo_freq$route_risk <- as.factor(cargo_freq$route_risk)

cargo_sev$cargo_type <- as.factor(cargo_sev$cargo_type)
cargo_sev$container_type <- as.factor(cargo_sev$container_type)
cargo_sev$route_risk <- as.factor(cargo_sev$route_risk)

p1 <- ggplot(cargo_freq, aes(x = cargo_type)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Cargo Frequency: Cargo Type", x = "Cargo Type", y = "Count")
p1
ggsave("EDA_Cargo/cargo_freq_cargo_type.png", p1, width = 7, height = 5)

p2 <- ggplot(cargo_freq, aes(x = container_type)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Cargo Frequency: Container Type", x = "Container Type", y = "Count")
p2
ggsave("EDA_Cargo/cargo_freq_container_type.png", p2, width = 7, height = 5)

p3 <- ggplot(cargo_freq, aes(x = route_risk)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Cargo Frequency: Route Risk", x = "Route Risk", y = "Count")
p3
ggsave("EDA_Cargo/cargo_freq_route_risk.png", p3, width = 7, height = 5)

p4 <- ggplot(cargo_freq, aes(x = cargo_value)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Cargo Frequency: Cargo Value", x = "Cargo Value", y = "Frequency")
p4
ggsave("EDA_Cargo/cargo_freq_cargo_value.png", p4, width = 7, height = 5)

p5 <- ggplot(cargo_freq, aes(x = weight)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Cargo Frequency: Weight", x = "Weight", y = "Frequency")
p5
ggsave("EDA_Cargo/cargo_freq_weight.png", p5, width = 7, height = 5)

p6 <- ggplot(cargo_freq, aes(x = distance)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Cargo Frequency: Distance", x = "Distance", y = "Frequency")
p6
ggsave("EDA_Cargo/cargo_freq_distance.png", p6, width = 7, height = 5)

p7 <- ggplot(cargo_freq, aes(x = transit_duration)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Cargo Frequency: Transit Duration", x = "Transit Duration", y = "Frequency")
p7
ggsave("EDA_Cargo/cargo_freq_transit_duration.png", p7, width = 7, height = 5)

p8 <- ggplot(cargo_freq, aes(x = pilot_experience)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Cargo Frequency: Pilot Experience", x = "Pilot Experience", y = "Frequency")
p8
ggsave("EDA_Cargo/cargo_freq_pilot_experience.png", p8, width = 7, height = 5)

p9 <- ggplot(cargo_freq, aes(x = vessel_age)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Cargo Frequency: Vessel Age", x = "Vessel Age", y = "Frequency")
p9
ggsave("EDA_Cargo/cargo_freq_vessel_age.png", p9, width = 7, height = 5)

p10 <- ggplot(cargo_freq, aes(x = solar_radiation)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Cargo Frequency: Solar Radiation", x = "Solar Radiation", y = "Frequency")
p10
ggsave("EDA_Cargo/cargo_freq_solar_radiation.png", p10, width = 7, height = 5)

p11 <- ggplot(cargo_freq, aes(x = debris_density)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Cargo Frequency: Debris Density", x = "Debris Density", y = "Frequency")
p11
ggsave("EDA_Cargo/cargo_freq_debris_density.png", p11, width = 7, height = 5)

p12 <- ggplot(cargo_freq, aes(x = exposure)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Cargo Frequency: Exposure", x = "Exposure", y = "Frequency")
p12
ggsave("EDA_Cargo/cargo_freq_exposure.png", p12, width = 7, height = 5)

p13 <- ggplot(cargo_freq, aes(x = claim_count)) +
  geom_histogram(binwidth = 1, fill = "skyblue3", colour = "black", boundary = -0.5) +
  labs(title = "Cargo Frequency: Claim Count", x = "Claim Count", y = "Frequency")
p13
ggsave("EDA_Cargo/cargo_freq_claim_count.png", p13, width = 7, height = 5)

p14 <- ggplot(cargo_sev, aes(x = claim_amount)) +
  geom_histogram(bins = 30, fill = "mediumpurple3", colour = "black") +
  labs(title = "Cargo Severity: Claim Amount", x = "Claim Amount", y = "Frequency")
p14
ggsave("EDA_Cargo/cargo_sev_claim_amount.png", p14, width = 7, height = 5)

p15 <- ggplot(cargo_sev %>% filter(claim_amount > 0), aes(x = log(claim_amount))) +
  geom_histogram(bins = 30, fill = "mediumpurple3", colour = "black") +
  labs(title = "Cargo Severity: Log Claim Amount", x = "log(Claim Amount)", y = "Frequency")
p15
ggsave("EDA_Cargo/cargo_sev_log_claim_amount.png", p15, width = 7, height = 5)

p16 <- ggplot(cargo_freq, aes(x = cargo_type, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Cargo Type", x = "Cargo Type", y = "Claim Count")
p16
ggsave("EDA_Cargo/cargo_freq_claimcount_by_cargo_type.png", p16, width = 7, height = 5)

p17 <- ggplot(cargo_freq, aes(x = container_type, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Container Type", x = "Container Type", y = "Claim Count")
p17
ggsave("EDA_Cargo/cargo_freq_claimcount_by_container_type.png", p17, width = 7, height = 5)

p18 <- ggplot(cargo_freq, aes(x = route_risk, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Route Risk", x = "Route Risk", y = "Claim Count")
p18
ggsave("EDA_Cargo/cargo_freq_claimcount_by_route_risk.png", p18, width = 7, height = 5)

p19 <- ggplot(cargo_freq, aes(x = cargo_value, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Cargo Value", x = "Cargo Value", y = "Claim Count")
p19
ggsave("EDA_Cargo/cargo_freq_claimcount_vs_cargo_value.png", p19, width = 7, height = 5)

p20 <- ggplot(cargo_freq, aes(x = weight, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Weight", x = "Weight", y = "Claim Count")
p20
ggsave("EDA_Cargo/cargo_freq_claimcount_vs_weight.png", p20, width = 7, height = 5)

p21 <- ggplot(cargo_freq, aes(x = distance, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Distance", x = "Distance", y = "Claim Count")
p21
ggsave("EDA_Cargo/cargo_freq_claimcount_vs_distance.png", p21, width = 7, height = 5)

p22 <- ggplot(cargo_freq, aes(x = transit_duration, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Transit Duration", x = "Transit Duration", y = "Claim Count")
p22
ggsave("EDA_Cargo/cargo_freq_claimcount_vs_transit_duration.png", p22, width = 7, height = 5)

p23 <- ggplot(cargo_freq, aes(x = pilot_experience, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Pilot Experience", x = "Pilot Experience", y = "Claim Count")
p23
ggsave("EDA_Cargo/cargo_freq_claimcount_vs_pilot_experience.png", p23, width = 7, height = 5)

p24 <- ggplot(cargo_freq, aes(x = vessel_age, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Vessel Age", x = "Vessel Age", y = "Claim Count")
p24
ggsave("EDA_Cargo/cargo_freq_claimcount_vs_vessel_age.png", p24, width = 7, height = 5)

p25 <- ggplot(cargo_freq, aes(x = solar_radiation, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Solar Radiation", x = "Solar Radiation", y = "Claim Count")
p25
ggsave("EDA_Cargo/cargo_freq_claimcount_vs_solar_radiation.png", p25, width = 7, height = 5)

p26 <- ggplot(cargo_freq, aes(x = debris_density, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Debris Density", x = "Debris Density", y = "Claim Count")
p26
ggsave("EDA_Cargo/cargo_freq_claimcount_vs_debris_density.png", p26, width = 7, height = 5)

p27 <- ggplot(cargo_sev, aes(x = cargo_type, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Cargo Type", x = "Cargo Type", y = "Claim Amount")
p27
ggsave("EDA_Cargo/cargo_sev_claimamount_by_cargo_type.png", p27, width = 7, height = 5)

p28 <- ggplot(cargo_sev, aes(x = container_type, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Container Type", x = "Container Type", y = "Claim Amount")
p28
ggsave("EDA_Cargo/cargo_sev_claimamount_by_container_type.png", p28, width = 7, height = 5)

p29 <- ggplot(cargo_sev, aes(x = route_risk, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Route Risk", x = "Route Risk", y = "Claim Amount")
p29
ggsave("EDA_Cargo/cargo_sev_claimamount_by_route_risk.png", p29, width = 7, height = 5)

p30 <- ggplot(cargo_sev, aes(x = cargo_value, y = claim_amount)) +
  geom_point(alpha = 0.5, colour = "darkorchid3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Amount vs Cargo Value", x = "Cargo Value", y = "Claim Amount")
p30
ggsave("EDA_Cargo/cargo_sev_claimamount_vs_cargo_value.png", p30, width = 7, height = 5)

p31 <- ggplot(cargo_sev, aes(x = weight, y = claim_amount)) +
  geom_point(alpha = 0.5, colour = "darkorchid3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Amount vs Weight", x = "Weight", y = "Claim Amount")
p31
ggsave("EDA_Cargo/cargo_sev_claimamount_vs_weight.png", p31, width = 7, height = 5)

cargo_freq_num <- cargo_freq %>%
  select(cargo_value, weight, distance, transit_duration, pilot_experience,
         vessel_age, solar_radiation, debris_density, exposure, claim_count)

cov_cargo_freq <- cov(cargo_freq_num, use = "complete.obs")
cov_cargo_freq
write.csv(cov_cargo_freq, "EDA_Cargo/cov_cargo_freq.csv")

cargo_sev_num <- cargo_sev %>%
  select(cargo_value, weight, distance, transit_duration, pilot_experience,
         vessel_age, solar_radiation, debris_density, exposure, claim_amount)

cov_cargo_sev <- cov(cargo_sev_num, use = "complete.obs")
cov_cargo_sev
write.csv(cov_cargo_sev, "EDA_Cargo/cov_cargo_sev.csv")

cor_cargo_freq <- cor(cargo_freq_num, use = "complete.obs")
cor_cargo_freq
write.csv(cor_cargo_freq, "EDA_Cargo/cor_cargo_freq.csv")

cor_cargo_sev <- cor(cargo_sev_num, use = "complete.obs")
cor_cargo_sev
write.csv(cor_cargo_sev, "EDA_Cargo/cor_cargo_sev.csv")

tab1 <- table(cargo_freq$cargo_type, cargo_freq$container_type)
chi1 <- suppressWarnings(chisq.test(tab1)$statistic)
n1 <- sum(tab1)
r1 <- nrow(tab1)
k1 <- ncol(tab1)
cramers_v_1 <- sqrt(chi1 / (n1 * min(r1 - 1, k1 - 1)))

tab2 <- table(cargo_freq$cargo_type, cargo_freq$route_risk)
chi2 <- suppressWarnings(chisq.test(tab2)$statistic)
n2 <- sum(tab2)
r2 <- nrow(tab2)
k2 <- ncol(tab2)
cramers_v_2 <- sqrt(chi2 / (n2 * min(r2 - 1, k2 - 1)))

tab3 <- table(cargo_freq$container_type, cargo_freq$route_risk)
chi3 <- suppressWarnings(chisq.test(tab3)$statistic)
n3 <- sum(tab3)
r3 <- nrow(tab3)
k3 <- ncol(tab3)
cramers_v_3 <- sqrt(chi3 / (n3 * min(r3 - 1, k3 - 1)))

cramers_v_results <- data.frame(
  variable_1 = c("cargo_type", "cargo_type", "container_type"),
  variable_2 = c("container_type", "route_risk", "route_risk"),
  cramers_v = c(cramers_v_1, cramers_v_2, cramers_v_3)
)

cramers_v_results
write.csv(cramers_v_results, "EDA_Cargo/cramers_v_results.csv", row.names = FALSE)

##########
# EQUIPMENT FAILURE EDA
##########

equip_freq$equipment_type <- as.factor(equip_freq$equipment_type)
equip_freq$solar_system <- as.factor(equip_freq$solar_system)

equip_sev$equipment_type <- as.factor(equip_sev$equipment_type)
equip_sev$solar_system <- as.factor(equip_sev$solar_system)

p1 <- ggplot(equip_freq, aes(x = equipment_type)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Equipment Frequency: Equipment Type", x = "Equipment Type", y = "Count")
p1
ggsave("EDA_Equip/equip_freq_equipment_type.png", p1, width = 7, height = 5)

p2 <- ggplot(equip_freq, aes(x = solar_system)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Equipment Frequency: Solar System", x = "Solar System", y = "Count")
p2
ggsave("EDA_Equip/equip_freq_solar_system.png", p2, width = 7, height = 5)

p3 <- ggplot(equip_freq, aes(x = equipment_age)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Equipment Frequency: Equipment Age", x = "Equipment Age", y = "Frequency")
p3
ggsave("EDA_Equip/equip_freq_equipment_age.png", p3, width = 7, height = 5)

p4 <- ggplot(equip_freq, aes(x = maintenance_int)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Equipment Frequency: Maintenance Interval", x = "Maintenance Interval", y = "Frequency")
p4
ggsave("EDA_Equip/equip_freq_maintenance_int.png", p4, width = 7, height = 5)

p5 <- ggplot(equip_freq, aes(x = usage_int)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Equipment Frequency: Usage Intensity", x = "Usage Intensity", y = "Frequency")
p5
ggsave("EDA_Equip/equip_freq_usage_int.png", p5, width = 7, height = 5)

p6 <- ggplot(equip_freq, aes(x = exposure)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Equipment Frequency: Exposure", x = "Exposure", y = "Frequency")
p6
ggsave("EDA_Equip/equip_freq_exposure.png", p6, width = 7, height = 5)

p7 <- ggplot(equip_freq, aes(x = claim_count)) +
  geom_histogram(binwidth = 1, fill = "skyblue3", colour = "black", boundary = -0.5) +
  labs(title = "Equipment Frequency: Claim Count", x = "Claim Count", y = "Frequency")
p7
ggsave("EDA_Equip/equip_freq_claim_count.png", p7, width = 7, height = 5)

p8 <- ggplot(equip_sev, aes(x = claim_amount)) +
  geom_histogram(bins = 30, fill = "mediumpurple3", colour = "black") +
  labs(title = "Equipment Severity: Claim Amount", x = "Claim Amount", y = "Frequency")
p8
ggsave("EDA_Equip/equip_sev_claim_amount.png", p8, width = 7, height = 5)

p9 <- ggplot(equip_sev %>% filter(claim_amount > 0), aes(x = log(claim_amount))) +
  geom_histogram(bins = 30, fill = "mediumpurple3", colour = "black") +
  labs(title = "Equipment Severity: Log Claim Amount", x = "log(Claim Amount)", y = "Frequency")
p9
ggsave("EDA_Equip/equip_sev_log_claim_amount.png", p9, width = 7, height = 5)

p10 <- ggplot(equip_freq, aes(x = equipment_type, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Equipment Type", x = "Equipment Type", y = "Claim Count")
p10
ggsave("EDA_Equip/equip_freq_claimcount_by_equipment_type.png", p10, width = 7, height = 5)

p11 <- ggplot(equip_freq, aes(x = solar_system, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Solar System", x = "Solar System", y = "Claim Count")
p11
ggsave("EDA_Equip/equip_freq_claimcount_by_solar_system.png", p11, width = 7, height = 5)

p12 <- ggplot(equip_freq, aes(x = equipment_age, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Equipment Age", x = "Equipment Age", y = "Claim Count")
p12
ggsave("EDA_Equip/equip_freq_claimcount_vs_equipment_age.png", p12, width = 7, height = 5)

p13 <- ggplot(equip_freq, aes(x = maintenance_int, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Maintenance Interval", x = "Maintenance Interval", y = "Claim Count")
p13
ggsave("EDA_Equip/equip_freq_claimcount_vs_maintenance_int.png", p13, width = 7, height = 5)

p14 <- ggplot(equip_freq, aes(x = usage_int, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Usage Intensity", x = "Usage Intensity", y = "Claim Count")
p14
ggsave("EDA_Equip/equip_freq_claimcount_vs_usage_int.png", p14, width = 7, height = 5)

p15 <- ggplot(equip_sev, aes(x = equipment_type, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Equipment Type", x = "Equipment Type", y = "Claim Amount")
p15
ggsave("EDA_Equip/equip_sev_claimamount_by_equipment_type.png", p15, width = 7, height = 5)

p16 <- ggplot(equip_sev, aes(x = solar_system, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Solar System", x = "Solar System", y = "Claim Amount")
p16
ggsave("EDA_Equip/equip_sev_claimamount_by_solar_system.png", p16, width = 7, height = 5)

p17 <- ggplot(equip_sev, aes(x = equipment_age, y = claim_amount)) +
  geom_point(alpha = 0.5, colour = "darkorchid3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Amount vs Equipment Age", x = "Equipment Age", y = "Claim Amount")
p17
ggsave("EDA_Equip/equip_sev_claimamount_vs_equipment_age.png", p17, width = 7, height = 5)

p18 <- ggplot(equip_sev, aes(x = maintenance_int, y = claim_amount)) +
  geom_point(alpha = 0.5, colour = "darkorchid3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Amount vs Maintenance Interval", x = "Maintenance Interval", y = "Claim Amount")
p18
ggsave("EDA_Equip/equip_sev_claimamount_vs_maintenance_int.png", p18, width = 7, height = 5)

equip_freq_num <- equip_freq %>%
  select(equipment_age, maintenance_int, usage_int, exposure, claim_count)

cov_equip_freq <- cov(equip_freq_num, use = "complete.obs")
cov_equip_freq
write.csv(cov_equip_freq, "EDA_Equip/cov_equip_freq.csv")

equip_sev_num <- equip_sev %>%
  select(equipment_age, maintenance_int, usage_int, exposure, claim_amount)

cov_equip_sev <- cov(equip_sev_num, use = "complete.obs")
cov_equip_sev
write.csv(cov_equip_sev, "EDA_Equip/cov_equip_sev.csv")

cor_equip_freq <- cor(equip_freq_num, use = "complete.obs")
cor_equip_freq
write.csv(cor_equip_freq, "EDA_Equip/cor_equip_freq.csv")

cor_equip_sev <- cor(equip_sev_num, use = "complete.obs")
cor_equip_sev
write.csv(cor_equip_sev, "EDA_Equip/cor_equip_sev.csv")

tab1 <- table(equip_freq$equipment_type, equip_freq$solar_system)
chi1 <- suppressWarnings(chisq.test(tab1)$statistic)
n1 <- sum(tab1)
r1 <- nrow(tab1)
k1 <- ncol(tab1)
cramers_v_1 <- sqrt(chi1 / (n1 * min(r1 - 1, k1 - 1)))

cramers_v_results <- data.frame(
  variable_1 = "equipment_type",
  variable_2 = "solar_system",
  cramers_v = cramers_v_1
)

cramers_v_results
write.csv(cramers_v_results, "EDA_Equip/cramers_v_results.csv", row.names = FALSE)

##########
# WORKERS' COMPENSATION EDA
##########

work_freq$solar_system <- as.factor(work_freq$solar_system)
work_freq$station_id <- as.factor(work_freq$station_id)
work_freq$occupation <- as.factor(work_freq$occupation)
work_freq$employment_type <- as.factor(work_freq$employment_type)
work_freq$accident_history_flag <- as.factor(work_freq$accident_history_flag)
work_freq$psych_stress_index <- as.factor(work_freq$psych_stress_index)
work_freq$safety_training_index <- as.factor(work_freq$safety_training_index)
work_freq$protective_gear_quality <- as.factor(work_freq$protective_gear_quality)

work_sev$solar_system <- as.factor(work_sev$solar_system)
work_sev$station_id <- as.factor(work_sev$station_id)
work_sev$occupation <- as.factor(work_sev$occupation)
work_sev$employment_type <- as.factor(work_sev$employment_type)
work_sev$accident_history_flag <- as.factor(work_sev$accident_history_flag)
work_sev$psych_stress_index <- as.factor(work_sev$psych_stress_index)
work_sev$safety_training_index <- as.factor(work_sev$safety_training_index)
work_sev$protective_gear_quality <- as.factor(work_sev$protective_gear_quality)
work_sev$injury_type <- as.factor(work_sev$injury_type)
work_sev$injury_cause <- as.factor(work_sev$injury_cause)

p1 <- ggplot(work_freq, aes(x = solar_system)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Workers Comp Frequency: Solar System", x = "Solar System", y = "Count")
p1
ggsave("EDA_Work/work_freq_solar_system.png", p1, width = 7, height = 5)

p2 <- ggplot(work_freq, aes(x = occupation)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Workers Comp Frequency: Occupation", x = "Occupation", y = "Count")
p2
ggsave("EDA_Work/work_freq_occupation.png", p2, width = 7, height = 5)

p3 <- ggplot(work_freq, aes(x = employment_type)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Workers Comp Frequency: Employment Type", x = "Employment Type", y = "Count")
p3
ggsave("EDA_Work/work_freq_employment_type.png", p3, width = 7, height = 5)

p4 <- ggplot(work_freq, aes(x = accident_history_flag)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Workers Comp Frequency: Accident History Flag", x = "Accident History Flag", y = "Count")
p4
ggsave("EDA_Work/work_freq_accident_history_flag.png", p4, width = 7, height = 5)

p5 <- ggplot(work_freq, aes(x = psych_stress_index)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Workers Comp Frequency: Psych Stress Index", x = "Psych Stress Index", y = "Count")
p5
ggsave("EDA_Work/work_freq_psych_stress_index.png", p5, width = 7, height = 5)

p6 <- ggplot(work_freq, aes(x = safety_training_index)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Workers Comp Frequency: Safety Training Index", x = "Safety Training Index", y = "Count")
p6
ggsave("EDA_Work/work_freq_safety_training_index.png", p6, width = 7, height = 5)

p7 <- ggplot(work_freq, aes(x = protective_gear_quality)) +
  geom_bar(fill = "steelblue", colour = "black") +
  labs(title = "Workers Comp Frequency: Protective Gear Quality", x = "Protective Gear Quality", y = "Count")
p7
ggsave("EDA_Work/work_freq_protective_gear_quality.png", p7, width = 7, height = 5)

p8 <- ggplot(work_freq, aes(x = experience_yrs)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Workers Comp Frequency: Experience Years", x = "Experience Years", y = "Frequency")
p8
ggsave("EDA_Work/work_freq_experience_yrs.png", p8, width = 7, height = 5)

p9 <- ggplot(work_freq, aes(x = hours_per_week)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Workers Comp Frequency: Hours per Week", x = "Hours per Week", y = "Frequency")
p9
ggsave("EDA_Work/work_freq_hours_per_week.png", p9, width = 7, height = 5)

p10 <- ggplot(work_freq, aes(x = supervision_level)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Workers Comp Frequency: Supervision Level", x = "Supervision Level", y = "Frequency")
p10
ggsave("EDA_Work/work_freq_supervision_level.png", p10, width = 7, height = 5)

p11 <- ggplot(work_freq, aes(x = gravity_level)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Workers Comp Frequency: Gravity Level", x = "Gravity Level", y = "Frequency")
p11
ggsave("EDA_Work/work_freq_gravity_level.png", p11, width = 7, height = 5)

p12 <- ggplot(work_freq, aes(x = base_salary)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Workers Comp Frequency: Base Salary", x = "Base Salary", y = "Frequency")
p12
ggsave("EDA_Work/work_freq_base_salary.png", p12, width = 7, height = 5)

p13 <- ggplot(work_freq, aes(x = exposure)) +
  geom_histogram(bins = 30, fill = "skyblue3", colour = "black") +
  labs(title = "Workers Comp Frequency: Exposure", x = "Exposure", y = "Frequency")
p13
ggsave("EDA_Work/work_freq_exposure.png", p13, width = 7, height = 5)

p14 <- ggplot(work_freq, aes(x = claim_count)) +
  geom_histogram(binwidth = 1, fill = "skyblue3", colour = "black", boundary = -0.5) +
  labs(title = "Workers Comp Frequency: Claim Count", x = "Claim Count", y = "Frequency")
p14
ggsave("EDA_Work/work_freq_claim_count.png", p14, width = 7, height = 5)

p15 <- ggplot(work_sev, aes(x = claim_amount)) +
  geom_histogram(bins = 30, fill = "mediumpurple3", colour = "black") +
  labs(title = "Workers Comp Severity: Claim Amount", x = "Claim Amount", y = "Frequency")
p15
ggsave("EDA_Work/work_sev_claim_amount.png", p15, width = 7, height = 5)

p16 <- ggplot(work_sev %>% filter(claim_amount > 0), aes(x = log(claim_amount))) +
  geom_histogram(bins = 30, fill = "mediumpurple3", colour = "black") +
  labs(title = "Workers Comp Severity: Log Claim Amount", x = "log(Claim Amount)", y = "Frequency")
p16
ggsave("EDA_Work/work_sev_log_claim_amount.png", p16, width = 7, height = 5)

p17 <- ggplot(work_freq, aes(x = solar_system, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Solar System", x = "Solar System", y = "Claim Count")
p17
ggsave("EDA_Work/work_freq_claimcount_by_solar_system.png", p17, width = 7, height = 5)

p18 <- ggplot(work_freq, aes(x = occupation, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Occupation", x = "Occupation", y = "Claim Count")
p18
ggsave("EDA_Work/work_freq_claimcount_by_occupation.png", p18, width = 8, height = 5)

p19 <- ggplot(work_freq, aes(x = employment_type, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Employment Type", x = "Employment Type", y = "Claim Count")
p19
ggsave("EDA_Work/work_freq_claimcount_by_employment_type.png", p19, width = 7, height = 5)

p20 <- ggplot(work_freq, aes(x = accident_history_flag, y = claim_count)) +
  geom_boxplot(fill = "lightgreen", colour = "black") +
  labs(title = "Claim Count by Accident History Flag", x = "Accident History Flag", y = "Claim Count")
p20
ggsave("EDA_Work/work_freq_claimcount_by_accident_history_flag.png", p20, width = 7, height = 5)

p21 <- ggplot(work_freq, aes(x = experience_yrs, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Experience Years", x = "Experience Years", y = "Claim Count")
p21
ggsave("EDA_Work/work_freq_claimcount_vs_experience_yrs.png", p21, width = 7, height = 5)

p22 <- ggplot(work_freq, aes(x = hours_per_week, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Hours per Week", x = "Hours per Week", y = "Claim Count")
p22
ggsave("EDA_Work/work_freq_claimcount_vs_hours_per_week.png", p22, width = 7, height = 5)

p23 <- ggplot(work_freq, aes(x = supervision_level, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Supervision Level", x = "Supervision Level", y = "Claim Count")
p23
ggsave("EDA_Work/work_freq_claimcount_vs_supervision_level.png", p23, width = 7, height = 5)

p24 <- ggplot(work_freq, aes(x = gravity_level, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Gravity Level", x = "Gravity Level", y = "Claim Count")
p24
ggsave("EDA_Work/work_freq_claimcount_vs_gravity_level.png", p24, width = 7, height = 5)

p25 <- ggplot(work_freq, aes(x = base_salary, y = claim_count)) +
  geom_point(alpha = 0.5, colour = "tomato3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Count vs Base Salary", x = "Base Salary", y = "Claim Count")
p25
ggsave("EDA_Work/work_freq_claimcount_vs_base_salary.png", p25, width = 7, height = 5)

p26 <- ggplot(work_sev, aes(x = injury_type, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Injury Type", x = "Injury Type", y = "Claim Amount")
p26
ggsave("EDA_Work/work_sev_claimamount_by_injury_type.png", p26, width = 8, height = 5)

p27 <- ggplot(work_sev, aes(x = injury_cause, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Injury Cause", x = "Injury Cause", y = "Claim Amount")
p27
ggsave("EDA_Work/work_sev_claimamount_by_injury_cause.png", p27, width = 8, height = 5)

p28 <- ggplot(work_sev, aes(x = occupation, y = claim_amount)) +
  geom_boxplot(fill = "goldenrod1", colour = "black") +
  labs(title = "Claim Amount by Occupation", x = "Occupation", y = "Claim Amount")
p28
ggsave("EDA_Work/work_sev_claimamount_by_occupation.png", p28, width = 8, height = 5)

p29 <- ggplot(work_sev, aes(x = experience_yrs, y = claim_amount)) +
  geom_point(alpha = 0.5, colour = "darkorchid3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Amount vs Experience Years", x = "Experience Years", y = "Claim Amount")
p29
ggsave("EDA_Work/work_sev_claimamount_vs_experience_yrs.png", p29, width = 7, height = 5)

p30 <- ggplot(work_sev, aes(x = claim_length, y = claim_amount)) +
  geom_point(alpha = 0.5, colour = "darkorchid3") +
  geom_smooth(method = "loess", se = FALSE, colour = "black") +
  labs(title = "Claim Amount vs Claim Length", x = "Claim Length", y = "Claim Amount")
p30
ggsave("EDA_Work/work_sev_claimamount_vs_claim_length.png", p30, width = 7, height = 5)

work_freq_num <- work_freq %>%
  select(experience_yrs, hours_per_week, supervision_level, gravity_level,
         base_salary, exposure, claim_count)

cov_work_freq <- cov(work_freq_num, use = "complete.obs")
cov_work_freq
write.csv(cov_work_freq, "EDA_Work/cov_work_freq.csv")

work_sev_num <- work_sev %>%
  select(experience_yrs, hours_per_week, supervision_level, gravity_level,
         base_salary, claim_length, exposure, claim_amount)

cov_work_sev <- cov(work_sev_num, use = "complete.obs")
cov_work_sev
write.csv(cov_work_sev, "EDA_Work/cov_work_sev.csv")

cor_work_freq <- cor(work_freq_num, use = "complete.obs")
cor_work_freq
write.csv(cor_work_freq, "EDA_Work/cor_work_freq.csv")

cor_work_sev <- cor(work_sev_num, use = "complete.obs")
cor_work_sev
write.csv(cor_work_sev, "EDA_Work/cor_work_sev.csv")

tab1 <- table(work_freq$occupation, work_freq$employment_type)
chi1 <- suppressWarnings(chisq.test(tab1)$statistic)
n1 <- sum(tab1)
r1 <- nrow(tab1)
k1 <- ncol(tab1)
cramers_v_1 <- sqrt(chi1 / (n1 * min(r1 - 1, k1 - 1)))

tab2 <- table(work_freq$occupation, work_freq$solar_system)
chi2 <- suppressWarnings(chisq.test(tab2)$statistic)
n2 <- sum(tab2)
r2 <- nrow(tab2)
k2 <- ncol(tab2)
cramers_v_2 <- sqrt(chi2 / (n2 * min(r2 - 1, k2 - 1)))

tab3 <- table(work_freq$employment_type, work_freq$accident_history_flag)
chi3 <- suppressWarnings(chisq.test(tab3)$statistic)
n3 <- sum(tab3)
r3 <- nrow(tab3)
k3 <- ncol(tab3)
cramers_v_3 <- sqrt(chi3 / (n3 * min(r3 - 1, k3 - 1)))

tab4 <- table(work_freq$psych_stress_index, work_freq$safety_training_index)
chi4 <- suppressWarnings(chisq.test(tab4)$statistic)
n4 <- sum(tab4)
r4 <- nrow(tab4)
k4 <- ncol(tab4)
cramers_v_4 <- sqrt(chi4 / (n4 * min(r4 - 1, k4 - 1)))

cramers_v_results <- data.frame(
  variable_1 = c("occupation", "occupation", "employment_type", "psych_stress_index"),
  variable_2 = c("employment_type", "solar_system", "accident_history_flag", "safety_training_index"),
  cramers_v = c(cramers_v_1, cramers_v_2, cramers_v_3, cramers_v_4)
)

cramers_v_results
write.csv(cramers_v_results, "EDA_Work/cramers_v_results.csv", row.names = FALSE)
