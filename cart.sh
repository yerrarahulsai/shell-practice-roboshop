#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(pwd)
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "Script started executing at $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo "Error: Please run this script with root privilege"
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

dnf module disable nodejs -y &>>$LOG_FILE
validate $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>LOG_FILE
validate $? "Enabling NodeJS"

dnf install nodejs -y &>>$LOG_FILE
validate $? "Installing NodeJS"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    validate $? "Creating system user"
else
    echo -e "User already exists...$Y Skipping $N"
fi

mkdir -p /app
validate $? "Creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
validate $? "Downloading Application"

cd /app
validate $? "Moving to app directory"

rm -rf /app/*
validate $? "Removing old code"

unzip /tmp/cart.zip &>>$LOG_FILE
validate $? "Unzipping Application"

npm install &>>$LOG_FILE
validate $? "Installing dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
validate $? "Copying systemctl service"

systemctl daemon-reload

systemctl enable cart &>>$LOG_FILE
validate $? "Enabling Cart"

systemctl restart cart
validate $? "Restarting Cart"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in $Y $TOTAL_TIME seconds $N"

