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
                          DCI_LINE,
                          PACK_TYPE, 
                          REC_LOC,
                          REC_QTY,
                          REC_TIME,
                          TOTAVL_QTY,
                          DAYS_FRM_SLE, 
                          AVGD_BTW_SLE,
                          DAYS_BTW_SD,
                          SHIP_QTY_SM,
                          SHIP_QTY_SD,
                          UNITS_SHIPPED, 
                          PRIORITY,
                          PRI_CALC,
                          TRUE_PRI
                  FROM
                          sandbox.pri_receipt
                  WHERE 
                          RECEIPT_DATE < '2019-03-19'
                          and DAYS_FRM_SLE <= 999
                          AND PACK_TYPE = 'LSE';", sep = "")

data_pri <- query(sqlquery)

set.seed(222)
trainIndex <- createDataPartition(data_pri$TRUE_PRI, 
                                  p = .75, 
                                  list = FALSE, 
                                  times = 1)

dataTrain <- data_pri[ trainIndex,]
dataTest  <- data_pri[-trainIndex,]

data_formula_pri <- TRUE_PRI ~ TOTAVL_QTY + DAYS_FRM_SLE + AVGD_BTW_SLE + DAYS_BTW_SD + SHIP_QTY_SM + SHIP_QTY_SD - 1

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
                          DCI_LINE,
                          PACK_TYPE, 
                          REC_LOC,
                          REC_QTY,
                          REC_TIME,
                          TOTAVL_QTY,
                          DAYS_FRM_SLE, 
                          AVGD_BTW_SLE,
                          DAYS_BTW_SD,
                          SHIP_QTY_SM,
                          SHIP_QTY_SD,
                          UNITS_SHIPPED, 
                          PRIORITY,
                          PRI_CALC,
                          TRUE_PRI,
                          0 as PRED_PRI,
                          0 as PRED_DIF
                  FROM
                          sandbox.pri_receipt
                  WHERE 
                          RECEIPT_DATE >= '2019-03-21'
                          and DAYS_FRM_SLE <= 999
                          AND PACK_TYPE = 'LSE';", sep = "")

preddata <- query(sqlquery)
#need to build preddata as build.x
data_new <- build.x(data_formula_pri, data=preddata, contrasts = FALSE, sparse = TRUE)
preddata$PRED_PRI <- predict(xg9,newdata = data_new)


#data_new_test <- build.x(data_formula_pri, data=dataTest, contrasts = FALSE, sparse = TRUE)
#dataTest$PRIORITY_VAL <- predict(xg9,newdata = data_new_test)
#dataTest$PRED_DIF <- abs(dataTest$PRED_PRI - dataTest$TRUE_PRI)
preddata$PRED_DIF <- abs(preddata$PRED_PRI - preddata$TRUE_PRI)

currentDate <- Sys.Date()
csvFileName <- paste("pri_receipt_train","_",currentDate,".csv",sep="")
write.csv(preddata, file=csvFileName)
lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)


