#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$LOG_FILE.log"
SCRIPT_DIR=$(pwd)
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "Script started executing at $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo "Error: Please run this script with root privelige"
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

dnf module enable nodejs:20 -y &>>$LOG_FILE
validate $? "Enabling NodeJS"

dnf install nodejs -y &>>$LOG_FILE
validate $? "Installing NodeJS"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    validate $? "Creating System user"
else
    echo -e "User already exists...$Y Skipping $N" 
fi

mkdir -p /app
validate $? "Creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
validate $? "Downloading Application"

cd /app 
validate $? "Moving to App directory"

rm -rf /app/*
validate $? "Removing Old code"

unzip /tmp/user.zip &>>$LOG_FILE
validate $? "Unzipping application"

npm install &>>$LOG_FILE
validate $? "Installing Dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
validate $? "Copying Systemctl service"

systemctl daemon-reload

systemctl enable user &>>$LOG_FILE
validate $? "Enabling User"

systemctl restart user &>>$LOG_FILE
validate $? "Restarting User"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in $Y $TOTAL_TIME seconds $N"