library(MASS)      
library(glmnet)   
library(caret)    
library(dplyr)    
library(Matrix)
library(car)
library(Metrics)
library(survival)

# Overdispersion check
var(wc_freq$claim_count)
mean(wc_freq$claim_count)


# Frequency modelling
numeric_vars <- names(wc_freq)[sapply(wc_freq, is.numeric) & names(wc_freq) != "claim_count" & names(wc_freq) != "exposure"]
categorical_vars <- names(wc_freq)[sapply(wc_freq, is.factor)]
predictors <- c(numeric_vars, categorical_vars)  # character vector
x <- model.matrix(~ . -station_id, data = wc_freq[, predictors])[,-1]
y <- wc_freq$claim_count
offset_vec <- log(wc_freq$exposure)

# Fit Poisson GLM
#step-wise
formula_step <- as.formula(paste("claim_count ~", paste(predictors, collapse = " + "), "+ offset(log(exposure))"))

pois_model <- glm(formula_step, family = poisson(), data = wc_freq)
step_pois <- stepAIC(pois_model, direction = "both")
summary(step_pois)
Anova(step_pois, type = "III")
vif(step_pois)

#CV
set.seed(123)

train_control <- trainControl(method = "cv", number = 10)

cv_pois <- train(
  claim_count ~ gravity_level + accident_history_flag + safety_training_index + psych_stress_index + occupation + offset(log(exposure)),
  data = wc_freq,
  method = "glm",
  family = poisson(),
  trControl = train_control
)

cv_pois

#Fit Negative Binomial
#step-wise
nb_model <- glm.nb(formula_step, data = wc_freq)
step_nb <- stepAIC(nb_model, direction = "both")
summary(step_nb)
Anova(step_nb, type = "III")
vif(step_nb)

#CV
set.seed(123)
cv_nb <- train(
  claim_count ~ gravity_level + accident_history_flag+ safety_training_index+ psych_stress_index+ occupation + offset(log(exposure)),
  data = wc_freq,
  method = "glm.nb",
  trControl = train_control
)

cv_nb

##Regularised Regression
set.seed(123)
# Poisson LASSO (alpha = 1) (shrink)
cv_lasso_poi <- cv.glmnet(x, y, family = "poisson", alpha = 1, offset = offset_vec)
plot(cv_lasso_poi)
best_lambda_lasso_poi <- cv_lasso_poi$lambda.min
coef(cv_lasso_poi, s = "lambda.min")

#Adjusted poisson lasso removing solar system multicollinearity due to high vif
pois_lasso_model <- glm(y ~ .-claim_count -solar_system -station_id - policy_id - exposure - worker_id - experience_yrs - supervision_level - employment_type + offset(log(exposure)), family = poisson(), data = wc_freq)
summary(pois_lasso_model)
vif(pois_lasso_model)
Anova(pois_lasso_model, type = "III")

#CV
set.seed(123)
k <- 10
folds <- sample(1:k, nrow(x), replace = TRUE)

rmse_cv <- numeric(k)
mae_cv <- numeric(k)

for (i in 1:k) {
  
  train_idx <- which(folds != i)
  test_idx  <- which(folds == i)
  
  x_train <- x[train_idx, ]
  y_train <- y[train_idx]
  offset_train <- offset_vec[train_idx]
  
  x_test <- x[test_idx, ]
  y_test <- y[test_idx]
  offset_test <- offset_vec[test_idx]
  
  cv_model <- cv.glmnet(
    x_train, y_train,
    family = "poisson",
    alpha = 1,
    offset = offset_train,
    nfolds = 5  
  )
  
  best_lambda <- cv_model$lambda.min
  
  preds <- predict(
    cv_model,
    newx = x_test,
    s = best_lambda,
    type = "response",
    newoffset = offset_test
  )
  preds <- as.numeric(preds)
  
  rmse_cv[i] <- rmse(y_test, preds)
  mae_cv[i]  <- mae(y_test, preds)
}

mean_rmse <- mean(rmse_cv)
mean_mae  <- mean(mae_cv)
mean_rmse
mean_mae

# Ridge (alpha = 0)
cv_ridge_poi <- cv.glmnet(x, y, family = "poisson", alpha = 0, offset = offset_vec)
plot(cv_ridge_poi)
best_lambda_ridge_poi <- cv_ridge_poi$lambda.min
coef(cv_ridge_poi, s = "lambda.min")

# NB vs Poisson AIC
AIC(step_nb, step_pois,pois_lasso_model)

########################################################################
## Severity models
#Gamma
numeric_vars_sev <- names(wc_sev)[sapply(wc_sev, is.numeric) & names(wc_sev) != "claim_amount"]
categorical_vars_sev <- names(wc_sev)[sapply(wc_sev, is.factor)]
predictors_sev <- c(numeric_vars_sev, categorical_vars_sev)  # character vector
predictors_sev
x_s <- model.matrix(~ . -station_id, data = wc_sev[, predictors_sev])[,-1]
y_s <- wc_sev$claim_amount

#Gamma Model and Step - wise
gamma_model <- glm(claim_amount ~ .-claim_id - station_id - policy_id - worker_id, family = Gamma(link="log"), data = wc_sev)
step_gamma <- stepAIC(gamma_model, direction = "both")
summary(step_gamma)
Anova(step_gamma, type = "III")
vif(step_gamma)

#CV
set.seed(123)
cv_gamma <- train(
  claim_amount ~ . -claim_id -station_id -policy_id -worker_id,
  data = wc_sev,
  method = "glm",
  family = Gamma(link = "log"),
  trControl = train_control
)

cv_gamma

#Log-transformed log-normal models and step wise
sev_ln <- lm(log(claim_amount) ~ .-claim_id - station_id - policy_id - worker_id, data = wc_sev)
sev_step_ln <- stepAIC(sev_ln, direction = "both")
summary(sev_step_ln)
Anova(sev_step_ln, type = "III")
vif(sev_step_ln)

#Weibull and step-wise
sev_model_weib <- survreg(Surv(claim_amount, rep(1, nrow(wc_sev))) ~ .-claim_id - station_id - policy_id - worker_id, 
                          dist = "weibull", data = wc_sev)
summary(sev_model_weib)
sev_model_step_weib <- step(sev_model_weib, direction="both")
summary(sev_model_step_weib)
anova(sev_model_step_weib, sev_model_weib)
vif(sev_model_step_weib)
drop1(sev_model_step_weib, test = "Chisq")

#CV
set.seed(123)
k <- 10
folds <- sample(1:k, nrow(wc_sev), replace = TRUE)
rmse_weib <- mae_weib <- numeric(k)
rmse_logn <- mae_logn <- numeric(k)

for (i in 1:k) {
  train_idx <- which(folds != i)
  test_idx <- which(folds == i)
  
  train_df <- wc_sev[train_idx, ]
  test_df  <- wc_sev[test_idx, ]
  
  train_df$y_surv <- Surv(train_df$claim_amount, rep(1, nrow(train_df)))
  
  weib_model <- survreg(y_surv ~ solar_system+ occupation + psych_stress_index +
                          hours_per_week+safety_training_index+protective_gear_quality+base_salary+injury_type+claim_length,
                        data = train_df, dist = "weibull")
  preds_weib <- predict(weib_model, newdata = test_df, type = "response")
  rmse_weib[i] <- sqrt(mean((test_df$claim_amount - preds_weib)^2))
  mae_weib[i]  <- mean(abs(test_df$claim_amount - preds_weib))
  
  log_model <- survreg(y_surv ~ solar_system + psych_stress_index +
                         hours_per_week+safety_training_index+protective_gear_quality+base_salary+claim_length,
                       data = train_df, dist = "lognormal")
  preds_logn <- predict(log_model, newdata = test_df, type = "response")
  rmse_logn[i] <- sqrt(mean((test_df$claim_amount - preds_logn)^2))
  mae_logn[i]  <- mean(abs(test_df$claim_amount - preds_logn))
}

data.frame(
  Model = c("Weibull", "Lognormal"),
  RMSE  = c(mean(rmse_weib), mean(rmse_logn)),
  MAE   = c(mean(mae_weib), mean(mae_logn))
)


##Regularised Regression
set.seed(123)
# Lasso
cv_lasso_sev <- cv.glmnet(x_s, y_s, alpha = 1, family = "gaussian")
plot(cv_lasso_sev)
best_lambda_lasso_sev <- cv_lasso_sev$lambda.min
coef(cv_lasso_sev, s = "lambda.min")

#Adjusted gamma lasso removing solar system multicollinearity due to high vif
gamma_lasso_model <- glm(claim_amount ~ .-claim_id - station_id - policy_id - worker_id 
                         - exposure - experience_yrs - employment_type -claim_seq - accident_history_flag, family = Gamma(link="log"), data = wc_sev)
summary(gamma_lasso_model)
vif(gamma_lasso_model)
Anova(gamma_lasso_model, type = "III")

# Ridge
cv_ridge_sev <- cv.glmnet(x_s, y_s, alpha = 0, family = "gaussian")
plot(cv_ridge_sev)
best_lambda_ridge_sev <- cv_ridge_sev$lambda.min
coef(cv_ridge_sev, s = "lambda.min")

#CV
set.seed(123)
k <- 10
folds <- sample(1:k, nrow(x_s), replace = TRUE)

rmse_cv <- numeric(k)
mae_cv <- numeric(k)
y_log <- log(y_s)

for (i in 1:k) {
  train_idx <- which(folds != i)
  test_idx  <- which(folds == i)
  
  x_train <- x_s[train_idx, ]
  y_train <- y_log[train_idx] 
  x_test  <- x_s[test_idx, ]
  y_test  <- y_s[test_idx]
  
  cv_model <- cv.glmnet(
    x_train, y_train,
    family = "gaussian",
    alpha = 1, 
    nfolds = 5 
  )
  
  best_lambda <- cv_model$lambda.min
  
  preds_log <- predict(cv_model, newx = x_test, s = best_lambda)
  preds <- exp(preds_log) 
  rmse_cv[i] <- sqrt(mean((y_test - preds)^2))
  mae_cv[i]  <- mean(abs(y_test - preds))
}
mean_rmse <- mean(rmse_cv)
mean_mae  <- mean(mae_cv)
mean_rmse
mean_mae


AIC(step_gamma, sev_step_ln,sev_model_step_weib,gamma_lasso_model)

