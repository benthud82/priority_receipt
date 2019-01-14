#Units shipped needs to be pulled from NPTSLH file

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
                  WAREHOUSE,
                  PO_NUMBER,
                  ITEM_NUMBER,
                  RECEIPT_DATE,
                  ETRN_NUMBER,
                  DCI_MVTICK,
                  PACK_TYPE,
                  TOT_ALCLOC,
                  TOTAVL_QTY,
                  DAYS_FRM_SLE,
                  AVGD_BTW_SLE,
                  DAYS_BTW_SD,
                  SHIP_QTY_MN,
                  SHIP_QTY_SM,
                  SHIP_QTY_SD,
                  UNITS_SHIPPED,
                  AFT_REC_ALLOC,
                  PRIORITY
                  FROM
                  sandbox.pri_receipt
                  WHERE RECEIPT_DATE <> '2019-01-15';", sep = "")
data_pri <- query(sqlquery)

set.seed(222)
trainIndex <- createDataPartition(data_pri$PRIORITY, 
                                  p = .75, 
                                  list = FALSE, 
                                  times = 1)

dataTrain <- data_pri[ trainIndex,]
dataTest  <- data_pri[-trainIndex,]

data_formula_pri <- PRIORITY ~ TOTAVL_QTY + DAYS_FRM_SLE + AVGD_BTW_SLE + DAYS_BTW_SD + SHIP_QTY_MN + SHIP_QTY_SM + SHIP_QTY_SD - 1

priX_train <- build.x(data_formula_pri, data=dataTrain,
                       contrasts=FALSE, sparse=TRUE)

priY_train <- build.y(data_formula_pri, data=dataTrain) %>% 
  as.integer()



priX_val <- build.x(data_formula_pri, data=dataTest,
                     contrasts=FALSE, sparse=TRUE)
priY_val <- build.y(data_formula_pri, data=dataTest) %>% 
  as.integer()


xgTrain <- xgb.DMatrix(data=priX_train, label=priY_train)
xgVal <- xgb.DMatrix(data=priX_val, label=priY_val)

xg9 <- xgb.train(
  data=xgTrain,
  objective='binary:logistic',
  nrounds=1000,
  eval_metric='logloss',
  watchlist=list(train=xgTrain, validate=xgVal),
  print_every_n = 20, 
  nthread=4,
  eta=.1,
  early_stopping_rounds=70,
  max_depth=5,
  subsample=0.5, 
  colsample_bytree=0.5,
  num_parallel_tree=20
)

sqlquery <- paste("SELECT 
                  WAREHOUSE,
                  PO_NUMBER,
                  ITEM_NUMBER,
                  RECEIPT_DATE,
                  ETRN_NUMBER,
                  DCI_MVTICK,
                  PACK_TYPE,
                  TOT_ALCLOC,
                  TOTAVL_QTY,
                  DAYS_FRM_SLE,
                  AVGD_BTW_SLE,
                  DAYS_BTW_SD,
                  SHIP_QTY_MN,
                  SHIP_QTY_SM,
                  SHIP_QTY_SD,
                  UNITS_SHIPPED,
                  AFT_REC_ALLOC,
                  0 as PRIORITY
                  FROM
                  sandbox.pri_receipt
                  WHERE RECEIPT_DATE = '2019-01-15';", sep = "")
preddata <- query(sqlquery)
#need to build preddata as build.x
data_new <- build.x(data_formula_pri, data=preddata, contrasts = FALSE, sparse = TRUE)
preddata$PRIORITY <- predict(xg9,newdata = data_new)
preddata

data_new_test <- build.x(data_formula_pri, data=dataTest, contrasts = FALSE, sparse = TRUE)
dataTest$PRIORITY_VAL <- predict(xg9,newdata = data_new_test)
dataTest$PRED_DIF <- abs(dataTest$PRIORITY_VAL - dataTest$PRIORITY)
dataTest

