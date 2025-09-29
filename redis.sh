#!/bin/bash

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
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

# Redis setup
dnf module disable redis -y &>>$LOG_FILE
validate $? "Disabling Redis"

dnf module enable redis:7 -y &>>$LOG_FILE
validate $? "Enabling Redis"

dnf install redis -y &>>$LOG_FILE
validate $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
# -e for including more than one argument

systemctl enable redis &>>$LOG_FILE
validate $? "Enabling Redis"

systemctl start redis &>>$LOG_FILE
validate $? "Starting Redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in $Y $TOTAL_TIME seconds $N"