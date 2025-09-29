#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.rahulsai.com
SCRIPT_DIR=$(pwd)
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo "Error: Please run this script with root priveliege"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$2...$R Failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2...$G Success $N" | tee -a $LOG_FILE
    fi
}

# NodeJs Setup
dnf module disable nodejs -y &>>$LOG_FILE
validate $? "Disabling NodeJS" 

dnf module enable nodejs:20 -y &>>$LOG_FILE
validate $? "Enabling NodeJS 20 version"

dnf install nodejs -y &>>$LOG_FILE
validate $? "Installing NodeJS"

# Creating system user
# Check user already exist or not
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    validate $? "Creating System User"
else
    echo -e "User already exist...$Y Skipping $N"
fi



mkdir -p /app
validate $? "Creating App directory" 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
validate $? "Downloading catalogue application"

cd /app 
validate $? "Moving to App directory"

#Before unziping clear all the previous files, so that if any older file exists with that name, it removes
rm -rf /app/*
validate $? "Removing Exsisting Code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
validate $? "Unzipping catalogue application"

npm install &>>$LOG_FILE
validate $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate $? "Creating systemctl service"

systemctl daemon-reload

systemctl enable catalogue &>>$LOG_FILE
validate $? "Enabling catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Copying Mongo Repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
validate $? "Installing MongoDB client"

# Here if in future, if we run this script, again it loads, duplicate may be found
# Here we should check if that collection is there or not 
# To check that
# We need a command to check weather a DB already exists or not (Google it)
INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
# If index is less than = 0, then create db else donot create
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    validate $? "Loading catalogue products"
else
    echo -e "Catalogue products already loaded...$Y Skipping $N"
fi

systemctl restart catalogue &>>$LOG_FILE
validate $? "Restarting catalogue"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in $Y $TOTAL_TIME seconds $N"