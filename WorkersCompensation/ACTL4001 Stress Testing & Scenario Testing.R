##Stress Testing
# 1-in-100 year macroeconomic shock
inflation_stress <- 0.0528
r_short_stress <- 0.0456
r_long_stress  <- 0.0407

# Short-term stressed losses
short_losses_stress <- compute_npv_losses(
  agg_losses,
  inflation_stress,
  r_short_stress,
  t_short
)
mean(short_losses_stress)
# Long-term stressed losses
long_losses_stress <- compute_npv_losses(
  agg_losses,
  inflation_stress,
  r_long_stress,
  t_long
)

short_metrics_stress <- compute_metrics(short_losses_stress)
long_metrics_stress  <- compute_metrics(long_losses_stress)
short_metrics_stress
long_metrics_stress

short_pricing_stress <- compute_pricing(
  short_losses_stress,
  risk_k,
  expense_margin,
  profit_margin
)
long_pricing_stress <- compute_pricing(
  long_losses_stress,
  risk_k,
  expense_margin,
  profit_margin
)

##Scenario testing
#Testing for different k and expense
k_vals <- c(1, 1.25, 1.5, 1.75,2)
expense_vals <- c(0.1, 0.15, 0.20, 0.25, 0.3)

grid <- expand.grid(
  k = k_vals,
  expense_margin = expense_vals
)
results_table <- do.call(rbind, lapply(1:nrow(grid), function(i) {
  
  k <- grid$k[i]
  em <- grid$expense_margin[i]
  
  res <- compute_pricing(short_losses, k, em, profit_margin)
  
  data.frame(
    k = k,
    expense_margin = em,
    
    Expected_Loss = res$Expected_Loss,
    Expenses = mean(res$Expenses),   # scalar summary
    Premium = res$Premium,
    
    Total_Cost = res$Expected_Loss + mean(res$Expenses),
    Net_Revenue = res$Net_Revenue,
    Return_on_Premium = res$Return_on_Premium
  )
}))
results_table
reshape(
  results_table[, c("k", "expense_margin", "Net_Revenue")],
  idvar = "k",
  timevar = "expense_margin",
  direction = "wide"
)

results_table_long <- do.call(rbind, lapply(1:nrow(grid), function(i) {
  
  k <- grid$k[i]
  em <- grid$expense_margin[i]
  
  res <- compute_pricing(long_losses, k, em, profit_margin)
  
  data.frame(
    k = k,
    expense_margin = em,
    
    Expected_Loss = res$Expected_Loss,
    Expenses = mean(res$Expenses),   # scalar summary
    Premium = res$Premium,
    
    Total_Cost = res$Expected_Loss + mean(res$Expenses),
    Net_Revenue = res$Net_Revenue,
    Return_on_Premium = res$Return_on_Premium
  )
}))
results_table_long
reshape(
  results_table_long[, c("k", "expense_margin", "Net_Revenue")],
  idvar = "k",
  timevar = "expense_margin",
  direction = "wide"
)
