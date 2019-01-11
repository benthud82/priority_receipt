#the training set is same as the validation set.  Need to modify based on other boosted tree examples

packages <- c('useful', 'coefplot', 'xgboost', 'here', 'magrittr', 'dygraphs', 'dplyr', 'RMySQL', 'caret', 'tinytex')
purrr::walk(packages, library, character.only = TRUE)
lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)
#dev
mychannel <- dbConnect(MySQL(), user="bentley", pass="dave41", host="127.0.0.1")

#prod
#mychannel <- dbConnect(MySQL(), user="root", pass="", host="127.0.0.1")
query <- function(...) dbGetQuery(mychannel, ...)

source('RMySQL_Update.R')

sqlquery <- paste("SELECT 
                  TOT_ALCLOC,
                  TOTAVL_QTY,
                  DAYS_FRM_SLE,
                  AVGD_BTW_SLE,
                  DAYS_BTW_SD,
                  SHIP_QTY_MN,
                  SHIP_QTY_SM,
                  SHIP_QTY_SD,
                  UNITS_SHIPPED,
                  PRIORITY
                  FROM
                  sandbox.pri_receipt;", sep = "")
data_pri <- query(sqlquery)

set.seed(112)

data_formula_pri <- PRIORITY ~ TOT_ALCLOC + TOTAVL_QTY + DAYS_FRM_SLE + AVGD_BTW_SLE + DAYS_BTW_SD + SHIP_QTY_MN + SHIP_QTY_SM + SHIP_QTY_SD + UNITS_SHIPPED - 1

priX_train <- build.x(data_formula_pri, data=data_pri,
                       contrasts=FALSE, sparse=TRUE)

priY_train <- build.y(data_formula_pri, data=data_pri) %>% 
  as.integer()

head(priY_train, n=100)


priX_val <- build.x(data_formula_pri, data=data_pri,
                     contrasts=FALSE, sparse=TRUE)
priY_val <- build.y(data_formula_pri, data=data_pri) %>% 
  as.integer()


xgTrain <- xgb.DMatrix(data=priX_train, label=priY_train)
xgVal <- xgb.DMatrix(data=priX_val, label=priY_val)

xg9 <- xgb.train(
  data=xgTrain,
  objective='binary:logistic',
  nrounds=1000,
  eval_metric='logloss',
  watchlist=list(train=xgTrain, validate=xgVal),
  early_stopping_rounds=70,
  max_depth=3,
  subsample=0.5, colsample_bytree=0.5,
  num_parallel_tree=50
)

