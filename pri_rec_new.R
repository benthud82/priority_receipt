packages <- c('tictoc', 'useful', 'coefplot', 'xgboost', 'here', 'magrittr', 'dygraphs', 'dplyr', 'RMySQL', 'caret')
purrr::walk(packages, library, character.only = TRUE)

lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)
#dev
#mychannel <- dbConnect(MySQL(), user="bentley", pass="dave41", host="127.0.0.1")

#NY Server Prod
#mychannel <- dbConnect(MySQL(), user="root", pass="", host="127.0.0.1")

#Google Prod
mychannel <- dbConnect(MySQL(), user="bentley", pass="dave41", host="104.154.153.225")

query <- function(...) dbGetQuery(mychannel, ...)

source('RMySQL_Update.R')

sqlquery <- paste("SELECT 
                TOTAVL_QTY,
                AVGD_BTW_SLE,
                DAYS_FRM_SLE,
                DAYS_BTW_SD,
                TRUE_PCK_MN,
                CASE
                    WHEN SOFTALLOC_COUNT > 0 THEN 1
                    ELSE 0
                END AS SOFTALLOC_COUNT
            FROM
                sandbox.pri_rec
            WHERE RECEIPT_DATE <> '2019-08-09';", sep = "")
data <- query(sqlquery)

set.seed(111)
trainIndex <- createDataPartition(data$SOFTALLOC_COUNT, 
                                  p = .75, 
                                  list = FALSE, 
                                  times = 1)

dataTrain <- data[ trainIndex,]
dataTest  <- data[-trainIndex,]

data_formula_boxes <- SOFTALLOC_COUNT ~ TOTAVL_QTY + AVGD_BTW_SLE + DAYS_FRM_SLE + DAYS_BTW_SD + TRUE_PCK_MN

#boxes data training
dataX_Train_box <- build.x(
  data_formula_boxes,
  data = dataTrain,
  contrasts = FALSE,
  sparse = TRUE
)
dataY_Train_box <- build.y(data_formula_boxes, data = dataTrain)

dataX_Test_box <- build.x(
  data_formula_boxes,
  data = dataTest,
  contrasts = FALSE,
  sparse = TRUE
)
dataY_Test_box <- build.y(data_formula_boxes, data = dataTest)

xgTrain_box <- xgb.DMatrix(data = dataX_Train_box,
                           label = dataY_Train_box)

xgVal_box <- xgb.DMatrix(data = dataX_Test_box,
                         label = dataY_Test_box)


model.xgb <-
  xgb.train(
    data = xgTrain_box,
    objective='binary:logistic',
    nrounds=1000,
    eval_metric='logloss',
    watchlist=list(train=xgTrain_box, validate=xgVal_box),
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
                PO_NUMBER,
                ITEM_NUMBER,
                REC_LOC,
                REC_MOV_QTY,
                RECEIPT_DATE,
                RECEIPT_TIME,
                PRIORITY,
                CURNT_CLS,
                TOTAVL_QTY,
                AVGD_BTW_SLE,
                DAYS_FRM_SLE,
                DAYS_BTW_SD,
                TRUE_PCK_MN,
                CASE
                    WHEN SOFTALLOC_COUNT > 0 THEN 1
                    ELSE 0
                END AS SOFTALLOC_COUNT
            FROM
                sandbox.pri_rec
            WHERE RECEIPT_DATE = '2019-08-09';", sep = "")

preddata <- query(sqlquery)

data_new <- build.x(data_formula_boxes, data=preddata, contrasts = FALSE, sparse = TRUE)
preddata$PRED_PRI <- predict(model.xgb,newdata = data_new)
currentDate <- Sys.Date()
csvFileName <- paste("pri_receipt_train","_",currentDate,".csv",sep="")
write.csv(preddata, file=csvFileName)
