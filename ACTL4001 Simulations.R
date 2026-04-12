library(dplyr)
library(ggplot2)
library(moments)
library(scales)


n_sim <- 100000      # Number of Monte Carlo simulations
t_short <- 1         # Short-term horizon (years)
t_long <- 10         # Long-term horizon (years)

inflation <- 0.02465    # 10-year historical average inflation
r_short <- 0.0179      # Short-term discount/interest rate
r_long <- 0.028956663       # Long-term discount/interest rate

expense_margin <- 0.20
profit_margin <- 0.08
risk_k <- 1.5        

occup_coeff <- data.frame(
  occupation = c(
    "Administrator","Drill Operator","Engineer","Executive",
    "Maintenance Staff","Manager","Planetary Operations",
    "Safety Officer","Scientist","Spacecraft Operator","Technology Officer"
  ),
  coef = c(
    0, 1.13122, 0.66097, -0.03464, 0.72562, 0.19030, 0.41706,
    0.45198, 0.43223, 0.33509, 0.69755
  )
)
# This is the log(lambda) for Administrator (baseline) at unit exposure
intercept <- coef(step_pois)["(Intercept)"]

# Lambda per employee per year (unit exposure) for each occupation
lambda_per_emp <- exp(intercept) * exp(occup_coeff$coef)

exposure_data <- data.frame(
  occupation = c("Administrator","Drill Operator","Engineer","Executive",
                 "Maintenance Staff","Manager","Planetary Operations",
                 "Safety Officer","Scientist","Spacecraft Operator","Technology Officer"),  # replace with your occupations
  num_employees = c(426 + 568 + 142 + 426,     # Administrator = HR + IT + Legal + Finance & Accounting
                    # Extraction Operations
                    2526,                       # Drill Operator = Drilling operators
                    2684,                       # Engineer = Engineers
                    12,                         # Executive
                    10316,                      # Maintenance Staff = Maintenance
                    111,                          # Manager (no direct match in your list, assign Directors)
                    3553,                          # Planetary Operations (no direct mapping, Freight operators
                    2132,                       # Safety Officer
                    211 + 711,                        # Scientist + Environmental Scientist
                    2842 + 1137 + 2132 + 568 + 2132, # Spacecraft Operator = Navigation + Maintenance + Security + Steward + Galleyhand
                    711 + 842),                           # Technology Officer (no dirst mapping, fiend technician + robotics technitian))
  period_exposure_in_years = 1,
  avg_salary = c(
    93750, 60000, 95000, 500000, 65000, 150000, 60000, 80000, 120000, 62000, 65000 # example salaries
  )
)

meanlog_sev_intercept <- coef(sev_step_ln)["(Intercept)"]
beta_salary <- coef(sev_step_ln)["base_salary"]
sdlog_sev <- summary(sev_step_ln)$sigma

sim_params <- exposure_data %>%
  mutate(lambda = lambda_per_emp, 
         emp_dist = num_employees / sum(num_employees))
sim_params <- sim_params %>%
  mutate(meanlog_occ = meanlog_sev_intercept + beta_salary * avg_salary,
         sdlog_occ   = sdlog_sev)

set.seed(123)

simulate_claims <- function(emp_df) {
  claim_list <- list() 
  
  for(i in 1:nrow(emp_df)) {
    occ <- emp_df$occupation[i]
    n_emp <- emp_df$num_employees[i]
    lambda <- emp_df$lambda[i]
    mu <- emp_df$meanlog_occ[i]
    sigma <- emp_df$sdlog_occ[i]
    
    # Simulate # of claims per employee
    claims_per_emp <- rpois(n_emp, lambda)
    
    # Total number of claims in this occupation
    n_claims <- sum(claims_per_emp)
    if(n_claims > 0) {
      severities <- rlnorm(n_claims, meanlog = mu, sdlog = sigma)
      claim_list[[occ]] <- severities
    } else {
      claim_list[[occ]] <- numeric(0)
    }
  }
  
  all_claims <- unlist(claim_list)
  return(all_claims)
}

agg_losses <- replicate(n_sim, sum(simulate_claims(sim_params)))
expected_loss <- mean(agg_losses)
loss_quantiles <- quantile(agg_losses, probs = c(0.1,0.25,0.5,0.75,0.9,0.95,0.99,0.9975))
expected_loss
loss_quantiles
max(agg_losses)
agg_losses_df <- data.frame(loss = unlist(agg_losses))

ggplot(agg_losses_df, aes(x = loss)) +
  geom_histogram(aes(y = ..density..), bins = 100, fill = "skyblue", color = "white") +
  geom_density(color = "red", size = 1) +
  labs(title = "Distribution of Aggregate Losses",
       x = "Aggregate Loss ($)",
       y = "Density") +
  theme_minimal()
ggplot(agg_losses_df, aes(x = loss)) +
  geom_histogram(bins = 100, fill = "skyblue", color = "white") +
  scale_x_log10() +
  labs(title = "Log-Scale Distribution of Aggregate Losses",
       x = "Aggregate Loss ($, log scale)",
       y = "Frequency") +
  theme_minimal()

##Metrics
# Function to compute NPV-adjusted losses
compute_npv_losses <- function(agg_losses, i, r, t){
  npv_losses <- rep(0, length(agg_losses))
  for(year in 1:t){
    factor <- ((1 + i) / (1 + r))^year
    npv_losses <- npv_losses + agg_losses * factor
  }
  
  return(npv_losses)
}

# Short-term (1 year)
short_losses <- compute_npv_losses(agg_losses, inflation, r_short, t_short)
Short_quantiles<- quantile(short_losses, probs = c(0.1,0.25,0.5,0.75,0.9,0.95,0.99,0.9975))
Short_quantiles
mean(long_losses)
# Long-term (10 years)
long_losses <- compute_npv_losses(agg_losses, inflation, r_long, t_long)
long_quantiles<- quantile(long_losses, probs = c(0.1,0.25,0.5,0.75,0.9,0.95,0.99,0.9975))
long_quantiles
compute_metrics <- function(losses){
  var_loss <- var(losses)
  
  VaR_99 <- quantile(losses, 0.99)
  
  TVaR_99 <- mean(losses[losses >= VaR_99])
  
  return(list(
    variance = var_loss,
    VaR_99 = VaR_99,
    TVaR_99 = TVaR_99
  ))
}

short_metrics <- compute_metrics(short_losses)
long_metrics  <- compute_metrics(long_losses)
short_metrics
long_metrics

##PREMIUM
risk_k <- 1.5 
expense_margin <- 0.2
profit_margin <- 0.08
compute_pricing <- function(losses, k, expense_margin, profit_margin){
  
  EL <- mean(losses)
  SD <- sd(losses)
  
  risk_margin <- k * SD
  premium <- (EL + risk_margin) / (1 - expense_margin - profit_margin)
  expenses <- expense_margin * premium
  profit_loading <- profit_margin * premium
  
  profit_sim <- premium - losses - expenses
  return_sim <- profit_sim / premium
  
  net_revenue <- mean(profit_sim)
  return_on_premium <- mean(return_sim)
  
  return(list(
    Expected_Loss = EL,
    Std_Dev = SD,
    Risk_Margin = risk_margin,
    Premium = premium,
    Expenses = expenses,
    Profit_Loading = profit_loading,
    Net_Revenue = net_revenue,
    Return_on_Premium = return_on_premium,
    Profit_Distribution = profit_sim,
    Return_Distribution = return_sim
  ))
}
compute_risk_metrics <- function(x){
  list(
    mean = mean(x),
    variance = var(x),
    SD = sd(x),
    VaR_95 = quantile(x, 0.05),
    VaR_99 = quantile(x, 0.01),
    TVaR_99 = mean(x[x <= quantile(x, 0.01)])
  )
}
short_results <- compute_pricing(short_losses, risk_k, expense_margin, profit_margin)
short_results
profit_risk <- compute_risk_metrics(short_results$Profit_Distribution)
return_risk <- compute_risk_metrics(short_results$Return_Distribution)
profit_risk
return_risk

long_results <- compute_pricing(long_losses, risk_k, expense_margin, profit_margin)
long_results
profit_risk_long <- compute_risk_metrics(long_results$Profit_Distribution)
return_risk_long <- compute_risk_metrics(long_results$Return_Distribution)
profit_risk_long
return_risk_long

##RANGES for short and long term returns and premium
compute_ranges <- function(losses){
  list(
    low  = losses[losses <= quantile(losses, 0.10)], 
    base = losses,                                  
    high = losses[losses >= quantile(losses, 0.90)]  
  )
}

short_ranges <- compute_ranges(short_losses)
long_ranges  <- compute_ranges(long_losses)

short_low_results  <- compute_pricing(short_ranges$low,  risk_k, expense_margin, profit_margin)
short_base_results <- compute_pricing(short_ranges$base, risk_k, expense_margin, profit_margin)
short_high_results <- compute_pricing(short_ranges$high, risk_k, expense_margin, profit_margin)

long_low_results  <- compute_pricing(long_ranges$low,  risk_k, expense_margin, profit_margin)
long_base_results <- compute_pricing(long_ranges$base, risk_k, expense_margin, profit_margin)
long_high_results <- compute_pricing(long_ranges$high, risk_k, expense_margin, profit_margin)

# short/long-term scenario profit risk
short_high_profit_risk <- compute_risk_metrics(short_high_results$Profit_Distribution)
short_low_profit_risk  <- compute_risk_metrics(short_low_results$Profit_Distribution)
short_base_profit_risk <- compute_risk_metrics(short_base_results$Profit_Distribution)

long_low_profit_risk   <- compute_risk_metrics(long_low_results$Profit_Distribution)
long_base_profit_risk  <- compute_risk_metrics(long_base_results$Profit_Distribution)
long_high_profit_risk  <- compute_risk_metrics(long_high_results$Profit_Distribution)

# short/long-term scenario return risk
short_high_return_risk <- compute_risk_metrics(short_high_results$Return_Distribution)
short_low_return_risk  <- compute_risk_metrics(short_low_results$Return_Distribution)
short_base_return_risk <- compute_risk_metrics(short_base_results$Return_Distribution)

long_low_return_risk   <- compute_risk_metrics(long_low_results$Return_Distribution)
long_base_return_risk  <- compute_risk_metrics(long_base_results$Return_Distribution)
long_high_return_risk  <- compute_risk_metrics(long_high_results$Return_Distribution)

##GRAPHS FOR REPRESENTATION OF SHORT AND LONG TERM RANGES
short_np <- short_results$Profit_Distribution / 1e6
long_np  <- long_results$Profit_Distribution / 1e6
short_np

summary_stats <- function(x){
  x <- x[!is.na(x)]
  
  c(
    Min = min(x),
    Max = max(x),
    Mean = mean(x),
    Median = median(x),
    SD = sd(x),
    Skew = skewness(x),
    Kurt = kurtosis(x)
  )
}

plot_npv <- function(x, title){
  
  stats <- summary_stats(x)
  xmin = quantile(x, 0.1)
  xmax = quantile(x, 0.9)
  
  ggplot(data.frame(value = x), aes(x = value)) +

    # density scaled
    geom_density(aes(y = after_stat(density)),
                 fill = "steelblue", alpha = 0.4) +
    
    # core region shading
    annotate("rect",
             xmin = quantile(x, 0.1),
             xmax = quantile(x, 0.9),
             ymin = -Inf, ymax = Inf,
             alpha = 0.05, fill = "blue") +
    
    # P10 and P90 lines
    geom_vline(xintercept = xmin, linetype = "dashed", colour = "red") +
    geom_vline(xintercept = xmax, linetype = "dashed", colour = "red") +
    
    annotate("text",
             x = xmin, y = 0,
             label = paste0("10%: ", round(xmin, 1), "M"),
             vjust = -0.5, hjust = -0.1, size = 3) +
    
    annotate("text",
             x = xmax, y = 0,
             label = paste0("90%: ", round(xmax, 1), "M"),
             vjust = -0.5, hjust = 1.1, size = 3) +
    
    annotate("text",
             x = -Inf, y = Inf,
             hjust = -0.1, vjust = 1.1,
             size = 3.5,
             label = paste0(
               "Min: ", round(stats["Min"], 2), "\n",
               "Max: ", round(stats["Max"], 2), "\n",
               "Mean: ", round(stats["Mean"], 2), "\n",
               "Median: ", round(stats["Median"], 2), "\n",
               "SD: ", round(stats["SD"], 2), "\n",
               "Skew: ", round(stats["Skew"], 2), "\n",
               "Kurt: ", round(stats["Kurt"], 2),"\n",
               "Values: 100,000"
             )) +
    
    labs(
      title = title,
      x = "NPV of Net Revenue (Millions)",
      y = "Density"
    ) +
    
    scale_y_continuous(labels = label_number()) +
    
    # zoom into central mass (optional but recommended for your data)
    coord_cartesian(
      xlim = c(
        quantile(x, 0.05),
        quantile(x, 1)
      )
    ) +
    
    theme_minimal() + 
    theme(plot.title = element_text(hjust = 0.5, size = 16)) 
}
short_npv <- plot_npv(short_np, "NPV of Annual Positive Net Revenues")
short_npv
long_npv <- plot_npv(long_np, "NPV of Long Term Positive Net Revenues")
long_npv

breakeven_quantile_short <- ecdf(short_results$Profit_Distribution)(0)
breakeven_quantile_short
breakeven_quantile_long <- ecdf(long_results$Profit_Distribution)(0)
breakeven_quantile_long
