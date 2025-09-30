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
echo "Script started executing at $(date)"

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

dnf module disable nginx -y &>>$LOG_FILE
validate $? "Disabling Nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
validate $? "Enabling Nginx"

dnf install nginx -y &>>$LOG_FILE
validate $? "Installing Nginx"

systemctl enable nginx &>>$LOG_FILE
validate $? "Enabling Nginx"

systemctl start nginx &>>$LOG_FILE
validate $? "Starting Nginx"

rm -rf /usr/share/nginx/html/*

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
validate $? "Downloading Frontend"

cd /usr/share/nginx/html

unzip /tmp/frontend.zip &>>$LOG_FILE
validate $? "Unzipping Frontend"

rm -rf /etc/nginx/nginx.conf

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
validate $? "Copying Nginx Configuration"

systemctl restart nginx
validate $? "Restarting Nginx"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in $Y $TOTAL_TIME seconds $N"
