#install and load necessary packages
install.packages("rpart.plot")
install.packages("rattle",dependencies = TRUE)
library(rpart.plot)
library(rpart)
library(rattle)
library(dplyr)
library(data.table)
library(sqldf)

url.train <-"http://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.data"
url.test <- "http://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.test"
url.names <- "http://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.names"

download.file(url.train, destfile = "Adult_train.csv")
download.file(url.test, destfile = "Adult_test.csv")
download.file(url.names, destfile = "Adult_Income_Readme.txt")

#getwd()

train <- read.csv("Adult_train.csv", header = FALSE)
test <- read.csv("Adult_test.csv",header = FALSE)
head(test)
#test set contains unwanteds 1st row ,which need to be dropped
test <- test[-1,]
str(train)
str(test)

###############
# removing unwanted value records
train1=train
train2=sqldf("select * from train1 where V2 NOT like '%?%' and V7 NOT like '%?%'
             and V14 NOT like '%?%'")

write.csv(train2,"train_clean.csv")
train2=read.csv("train_clean.csv")
str(train2)
#DROP ROW NUMBER COLUMN
train2<-train2[,-1]



####################

# applying the column names from the readme.txt

varnames=c("AGE",
     "WORKCLASS",
    "FNLWGT",
    "EDUCATION",
    "EDUCATION_NUM",
    "MARITAL_STATUS",
    "OCCUPATION",
    "RELATIONSHIP",
    "RACE",
    "SEX",
    "CAPITAL_GAIN",
    "CAPITAL_LOSS",
    "HOURS_PER_WEEK",
    "NATIVE_COUNTRY",
    "INCOME_LEVEL")
names(train2)<-varnames

# preparing the test data
str(test)
names(test)<-varnames

# removing unwanted Puncutations from test set

test1=sqldf("select * from test where WORKCLASS NOT like '%?%' 
	     and EDUCATION NOT like '%?%'
           and MARITAL_STATUS NOT like '%?%' 
           and OCCUPATION NOT like '%?%' 
           and RELATIONSHIP NOT like '%?%'
           and RACE NOT like '%?%' 
           and SEX NOT like '%?%' 
           and NATIVE_COUNTRY NOT like '%?%' 
           and INCOME_LEVEL NOT like '%?%' ")
	       
#export n import

write.csv(test1,"test_clean.csv")
test2=read.csv("test_clean.csv")
test2<-test2[,-1]

# abc=sqldf("select * from test2 where INCOME_LEVEL  NOT like '%<=50K.%' and 
#                               INCOME_LEVEL NOT like '%>50K.%'" )

test2=test2[-(test2$AGE == "|1x3 Cross validator"),]
write.csv(test2,"test_clean2.csv")
test2=read.csv("test_clean2.csv")
test2<-test2[,-1]
#cleaning the income_level  levels 
levels(test2$INCOME_LEVEL)<-levels(train2$INCOME_LEVEL)

#build the decision Tree using rpart
dtree<-rpart(INCOME_LEVEL~.,data=train2,method ="class")

plot(dtree)
text(dtree,pretty = 0)
fancyRpartPlot(dtree, main = "Adult Income Level")
print(dtree)


#preictions on test data

test_pred=predict(dtree,test2[,1:14])
str(test_pred)
results=ifelse(test_pred[,1] >=0.5," <=50K"," >50K")

#model accuracy
accuracy<-round(sum(results==test2[,15])/length(results),digit=4)
print(paste("The model correctly predicted the test outcome ",
            accuracy*100, "% of the time", sep=""))


