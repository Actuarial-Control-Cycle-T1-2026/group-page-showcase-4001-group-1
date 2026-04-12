library(dplyr)
library(tidyverse)
library(readxl)
library(ggplot2)
library(rcompanion)
library(effectsize)


wc_freq <- read_xlsx("C:/Users/joyz1/OneDrive/Documents/SOA_2026_Case_Study_Materials/srcsc-2026-claims-workers-comp.xlsx", sheet = "freq")

##EDA: Data Cleaning; Reasonable range/column Conversions

#Cleaning _??? values
cols_to_clean <- c("policy_id", "worker_id","solar_system", "station_id","occupation","employment_type","accident_history_flag")
wc_freq[cols_to_clean] <- lapply(wc_freq[cols_to_clean], function(x) {
  sub("_\\?\\?.*$", "", x)
})

wc_freq <- wc_freq %>%
  mutate(across(c(policy_id, solar_system, station_id, occupation, employment_type, accident_history_flag, psych_stress_index, safety_training_index, protective_gear_quality, hours_per_week ), as.factor))

#Remove data values not within the correct range or category and also NA
# Numeric ranges
numeric_ranges <- list(
  experience_yrs = c(0.2, 40),
  supervision_level = c(0, 1),
  gravity_level = c(0.75, 1.5),
  base_salary = c(20000, 130000),
  exposure = c(0, 1),
  claim_count = c(0, 2)
)

# Categorical allowed levels
categorical_levels <- list(
  solar_system = c("Helionis Cluster", "Epsilon", "Zeta"),
  occupation = c("Scientist","Planetary Operations","Drill Operator","Engineer", "Administrator","Maintenance Staff","Technology Officer", "Manager","Spacecraft Operator", "Executive", "Safety Officer"),
  employment_type = c("Full-time", "Contract"),
  accident_history_flag = c("0", "1"),
  psych_stress_index = c("1","2","3","4","5"),  
  hours_per_week = c("20","25","30","35","40"),
  safety_training_index = c("1","2","3","4","5"),
  protective_gear_quality = c("1","2","3","4","5")
)

for(col in names(numeric_ranges)){
  rng <- numeric_ranges[[col]]
  wc_freq <- wc_freq[wc_freq[[col]] >= rng[1] & wc_freq[[col]] <= rng[2]| is.na(wc_freq[[col]]),]
}

for(col in names(categorical_levels)){
  allowed <- categorical_levels[[col]]
  wc_freq <- wc_freq[wc_freq[[col]] %in% allowed | is.na(wc_freq[[col]]),]
}

wc_freq <- na.omit(wc_freq)
summary(wc_freq)

#Severity
wc_sev <- read_xlsx("C:/Users/joyz1/OneDrive/Documents/SOA_2026_Case_Study_Materials/srcsc-2026-claims-workers-comp.xlsx", sheet = "sev")

cols_to_clean_sev <- c("policy_id", "worker_id","solar_system", "station_id","occupation","employment_type","accident_history_flag","injury_type", "injury_cause")
wc_sev[cols_to_clean_sev] <- lapply(wc_sev[cols_to_clean_sev], function(x) {
  sub("_\\?\\?.*$", "", x)
})

wc_sev <- wc_sev %>%
  mutate(across(c(claim_seq, solar_system, station_id, occupation, employment_type, accident_history_flag, psych_stress_index, safety_training_index, protective_gear_quality, hours_per_week , injury_type, injury_cause,), as.factor))

#Remove data values not within the correct range or category and also NA
# Numeric ranges
numeric_ranges_sev <- list(
  experience_yrs = c(0.2, 40),
  supervision_level = c(0, 1),
  gravity_level = c(0.75, 1.5),
  base_salary = c(20000, 130000),
  exposure = c(0, 1),
  claim_length = c(3, 1000),
  claim_amount = c(5, quantile(wc_sev$claim_amount, 0.9975, na.rm = TRUE))
)

# Categorical allowed levels
categorical_levels_sev <- list(
  solar_system = c("Helionis Cluster", "Epsilon", "Zeta"),
  occupation = c("Scientist","Planetary Operations","Drill Operator","Engineer", "Administrator","Maintenance Staff","Technology Officer", "Manager","Spacecraft Operator", "Executive", "Safety Officer"),
  employment_type = c("Full-time", "Contract"),
  accident_history_flag = c("0", "1"),
  psych_stress_index = c("1","2","3","4","5"),  
  hours_per_week = c("20","25","30","35","40"),
  safety_training_index = c("1","2","3","4","5"),
  protective_gear_quality = c("1","2","3","4","5"),
  claim_seq=c("0","1","2"),
  injury_type = c("Burns", "Psychological", "Amputation", "Cut laceration", "Other", "Sprain, strain", "Stress"),
  injury_cause = c("Caught in machine", "Exposure", "Other", "Overexertion", "Stress/strain", "Vehicle accident", "Violence")
)
for(col in names(numeric_ranges_sev)){
  rng <- numeric_ranges_sev[[col]]
  wc_sev <- wc_sev[(wc_sev[[col]] >= rng[1] & wc_sev[[col]] <= rng[2]) | is.na(wc_sev[[col]]),]}


for(col in names(categorical_levels_sev)){
  allowed <- categorical_levels_sev[[col]]
  wc_sev <- wc_sev[wc_sev[[col]] %in% allowed,]
}
wc_sev <- na.omit(wc_sev)
summary(wc_sev)

wc_freq[sapply(wc_freq, is.factor)] <- lapply(wc_freq[sapply(wc_freq, is.factor)], droplevels)
wc_sev[sapply(wc_sev, is.factor)] <- lapply(wc_sev[sapply(wc_sev, is.factor)], droplevels)

##EDA DATA ANALYSIS
# Frequency data numeric summary
summary(wc_freq[sapply(wc_freq, is.numeric)])

# Severity data numeric summary
summary(wc_sev[sapply(wc_sev, is.numeric)])

# Frequency data categorical summaries
lapply(wc_freq[sapply(wc_freq, is.factor)], table)

# Severity data categorical summaries
lapply(wc_sev[sapply(wc_sev, is.factor)], table)


################################################################
#claim count
ggplot(wc_freq, aes(x = claim_count)) +
  geom_bar(fill = "skyblue") +
  labs(title = "Distribution of Claim Count", 
       x = "Claim Count", y = "Frequency") +
  theme_minimal()

#Injury Type
ggplot(wc_sev, aes(x = injury_type)) +
  geom_bar(fill = "tomato") +
  labs(title = "Distribution of Injury Type", 
       x = "Injury Type", y = "Number of Claims") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#Injury Cause
ggplot(wc_sev, aes(x = injury_cause)) +
  geom_bar(fill = "tomato") +
  labs(title = "Distribution of Injury Cause", 
       x = "Injury Cause", y = "Number of Claims") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#Claim Length
ggplot(wc_sev, aes(x = claim_length)) +
  geom_histogram(fill = "tomato", bins = 40) +
  labs(title = "Distribution of Claim Length", 
       x = "Claim Length", y = "Number of Claims") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#Claim Amount
ggplot(wc_sev, aes(x = claim_amount)) +
  geom_histogram(fill = "tomato", color = "black", bins = 30) +
  labs(title = "Distribution of Claim Amount", 
       x = "Claim Amount", y = "Number of Claims") +
  theme_minimal()

##Paired Plots
plot_pair_base <- function(var_name, freq_data, sev_data) {
  
  par(mfrow = c(1,2), mar = c(5,4,3,1))  # 1 row, 2 columns, margins
  
  if(is.numeric(freq_data[[var_name]])) {
    # Histogram for frequency
    hist(freq_data[[var_name]], 
         main = paste("Frequency -", var_name),
         xlab = var_name,
         col = "skyblue", border = "black")
    
    # Histogram for severity
    hist(sev_data[[var_name]], 
         main = paste("Severity -", var_name),
         xlab = var_name,
         col = "tomato", border = "black")
    
  } else if(is.factor(freq_data[[var_name]])) {
    # Bar plot for frequency
    freq_table <- table(freq_data[[var_name]])
    barplot(freq_table,
            main = paste("Frequency -", var_name),
            xlab = var_name,
            col = "skyblue",
            las = 2)  # rotate axis labels
    
    # Bar plot for severity
    sev_table <- table(sev_data[[var_name]])
    barplot(sev_table,
            main = paste("Severity -", var_name),
            xlab = var_name,
            col = "tomato",
            las = 2)
    
  } else {
    stop("Unknown variable type")
  }
  
  par(mfrow = c(1,1))
}
# Numeric and categorical variables
numeric_vars <- setdiff(names(wc_freq)[sapply(wc_freq, is.numeric)], "claim_count")
categorical_vars <- names(wc_freq)[sapply(wc_freq, function(x) is.factor(x))]
all_vars <- c(numeric_vars, categorical_vars)

# Loop through variables
for(var in all_vars){
  plot_pair_base(var, wc_freq, wc_sev)
}


##Relationships between y response and variables
wc_freq <- wc_freq %>%
  mutate(across(c(claim_count), as.factor))

#Boxplot for claim_count vs numerical values considering density
numeric_vars <- names(wc_freq)[sapply(wc_freq, is.numeric)]

for(var in numeric_vars){
  
  wc_freq_plot <- wc_freq %>%
    group_by(claim_count) %>%
    mutate(count_level = n())
  
  ggplot(wc_freq_plot, aes(x = claim_count, y = .data[[var]], fill = count_level)) +
    geom_boxplot( color = "black") +
    scale_fill_gradient(low = "lightblue", high = "darkblue") +
    labs(title = paste("Boxplot of", var, "by Claim Count"),
         x = "Claim Count",
         y = var,
         fill = "Number of Policies") +
    theme_minimal() -> p
  
  print(p)
}

#Tile plot for claim_count vs...
categorical_vars <- names(wc_freq)[sapply(wc_freq, function(x) is.factor(x))]
categorical_vars <- setdiff(categorical_vars, "claim_count")  # exclude outcome

wc_freq$claim_count_num <- as.numeric(as.character(wc_freq$claim_count))
for (var in categorical_vars) {
  
  plot_data <- wc_freq %>%
    group_by(.data[[var]]) %>%
    summarise(claim_rate = mean(claim_count_num)) %>%
    arrange(desc(claim_rate))
  
  p <- ggplot(plot_data, aes(x = reorder(.data[[var]], claim_rate),
                             y = claim_rate)) +
    geom_col(fill = "steelblue") +
    labs(
      title = paste("Average Claim Frequency by", var),
      x = var,
      y = "Average Claims per Policy"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p)
}

##Relationship for severity
#Scatterplot for claim amount vs numerical vars
numeric_vars_sev <- names(wc_sev)[sapply(wc_sev, is.numeric)]
numeric_vars_sev <- setdiff(numeric_vars_sev, "claim_amount")
for(var in numeric_vars_sev){
  
  ggplot(wc_sev, aes(x = .data[[var]], y = claim_amount)) +
    geom_point(color = "darkblue", alpha = 0.5) +
    scale_y_log10()+
    geom_smooth(method = "loess", color = "red", se = TRUE) +
    labs(title = paste("Scatterplot of", var, "vs Claim Amount"),
         x = var,
         y = "Claim Amount") +
    theme_minimal() -> p
  
  print(p)
}

#Boxplots for claim amount vs categorical
categorical_vars_sev <- names(wc_sev)[sapply(wc_sev, function(x) is.factor(x))]
for(var in categorical_vars_sev){
  
  ggplot(wc_sev, aes(x = .data[[var]], y = claim_amount, fill = .data[[var]])) +
    geom_boxplot(alpha = 0.6) +
    scale_y_log10(labels = scales::comma)+
    geom_jitter(width = 0.2, alpha = 0.4, color = "black", size = 0.8) +
    labs(title = paste("Claim Amount by", var),
         x = var,
         y = "Claim Amount",
         fill = var) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "none") -> p
  
  print(p)
}

#############################################################################
##Correlation
#Numerical vs Numerical
# Frequency
cor_freq <- cor(wc_freq[, numeric_vars], use = "complete.obs")

# Severity
cor_sev <- cor(wc_sev[, numeric_vars_sev], use = "complete.obs")

#Heat maps
cor_freq_long <- as.data.frame(as.table(cor_freq))

ggplot(cor_freq_long, aes(Var1, Var2, fill = Freq)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0,
                       limits = c(-1,1), name = "Correlation") +
  labs(title = "Correlation Heatmap - Frequency Data", x = "", y = "") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) -> p_freq

print(p_freq)

# Severity heatmap
cor_sev_long <- as.data.frame(as.table(cor_sev))

ggplot(cor_sev_long, aes(Var1, Var2, fill = Freq)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0,
                       limits = c(-1,1), name = "Correlation") +
  labs(title = "Correlation Heatmap - Severity Data", x = "", y = "") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) -> p_sev

print(p_sev)

ggplot(wc_freq, aes(x = experience_yrs, y = base_salary)) +
  geom_point(alpha = 0.4, color = "darkblue") +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  labs(title = "Base Salary vs Experience",
       x = "Experience (Years)",
       y = "Base Salary") +
  theme_minimal()

#Solar system vs gravity lvl
ggplot(wc_freq, aes(x = solar_system, y = gravity_level, fill = solar_system)) +
  geom_boxplot(alpha = 0.6) +
  geom_jitter(width = 0.1, alpha = 0.4, color = "black", size = 0.8) +
  labs(title = "Gravity Level by Solar System",
       x = "Solar System",
       y = "Gravity Level") +
  theme_minimal() +
  theme(legend.position = "none")

# Categorical vs categorical  (Frequency)
cat_vars <- wc_freq[sapply(wc_freq, is.factor)]

cramer_matrix <- matrix(NA,
                        ncol = ncol(cat_vars),
                        nrow = ncol(cat_vars))

colnames(cramer_matrix) <- names(cat_vars)
rownames(cramer_matrix) <- names(cat_vars)

for(i in 1:ncol(cat_vars)){
  for(j in 1:ncol(cat_vars)){
    
    tbl <- table(cat_vars[[i]], cat_vars[[j]])
    
    cramer_matrix[i,j] <- cramerV(tbl)
  }
}

cramer_matrix

#Categorical vs numerical (frequency)
num_vars <- names(wc_freq)[sapply(wc_freq, is.numeric)]
cat_vars <- names(wc_freq)[sapply(wc_freq, is.factor)]

eta_results <- data.frame()

for(num in num_vars){
  for(cat in cat_vars){
    
    model <- aov(wc_freq[[num]] ~ wc_freq[[cat]])
    
    eta <- eta_squared(model)[1,"Eta2"]
    
    eta_results <- rbind(
      eta_results,
      data.frame(
        Numeric = num,
        Categorical = cat,
        Eta_Squared = eta
      )
    )
  }
}

eta_results

#Correlation severity
num_vars <- names(wc_sev)[sapply(wc_sev, is.numeric)]
cat_vars <- names(wc_sev)[sapply(wc_sev, is.factor)]

eta_results <- data.frame()

for(num in num_vars){
  for(cat in cat_vars){
    
    model <- aov(wc_sev[[num]] ~ wc_sev[[cat]])
    
    eta <- eta_squared(model)$Eta2[1]
    
    eta_results <- rbind(
      eta_results,
      data.frame(
        Numeric_Var = num,
        Categorical_Var = cat,
        Eta_Squared = eta
      )
    )
  }
}

eta_results
##
cat_vars <- wc_sev[, sapply(wc_sev, is.factor), drop = FALSE]

cramer_matrix <- matrix(NA,
                        ncol = ncol(cat_vars),
                        nrow = ncol(cat_vars))

colnames(cramer_matrix) <- names(cat_vars)
rownames(cramer_matrix) <- names(cat_vars)

for(i in 1:ncol(cat_vars)){
  for(j in 1:ncol(cat_vars)){
    
    temp <- na.omit(data.frame(cat_vars[[i]], cat_vars[[j]]))
    
    if(length(unique(temp[,1])) > 1 & length(unique(temp[,2])) > 1){
      
      tbl <- table(temp)
      cramer_matrix[i,j] <- cramerV(tbl)
      
    }
  }
}

cramer_matrix
