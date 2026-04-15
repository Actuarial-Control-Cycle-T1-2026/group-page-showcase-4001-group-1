# -------------------------------------------------
# Premium and Net revenue calculation
# -------------------------------------------------
# Risk margin
k <- 2
sd_short <- sd(sim_short)
sd_long <- sd(sim_long)
risk_margin_short <- k * sd_short
risk_margin_long <- k * sd_long

# Other margins
expense_margin <- 0.2
profit_margin <- 0.08

# Premium
premium_short <- (mean_short + risk_margin_short) / (1 - expense_margin - profit_margin)
premium_long <- (mean_long + risk_margin_long) / (1 - expense_margin - profit_margin)

expense_short <- premium_short * expense_margin
expense_long <- premium_long * expense_margin

profit_short <- premium_short * profit_margin
profit_long <- premium_long * profit_margin

# Net Revenue
net_revenue_short <- premium_short - mean_short - expense_short
net_revenue_long <- premium_long - mean_long - expense_long

# Return on Profit
ROP_short <- net_revenue_short / premium_short
ROP_long <- net_revenue_long / premium_long

net_revenue_short
net_revenue_long
