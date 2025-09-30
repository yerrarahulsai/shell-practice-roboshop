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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
validate $? "Installing Python"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    validate $? "Creating System user"
else
    echo -e "User already exits $Y Skipping $N"
fi

mkdir -p /app
validate $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
validate $? "Downloading application"

cd /app
validate $? "Changing to app directory"

rm -rf /app/*

unzip /tmp/payment.zip &>>$LOG_FILE
validate $? "Unzipping Application"

pip3 install -r requirements.txt &>>$LOG_FILE
validate $? "Installing dependencies"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
validate $? "Copying systemctl file"

systemctl daemon-reload

systemctl enable shipping &>>$LOG_FILE
validate $? "Enabling Shipping"

systemctl restart shipping 
validate $? "Restarting Shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in $Y $TOTAL_TIME seconds $N"