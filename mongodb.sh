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
echo "Script Started executing at: $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo "Error: Please run this script with root privelege"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$2....$R Failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2...$G Success $N" | tee -a $LOG_FILE
    fi
}

# Creating a repo file in yum.repos.d
cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding Mongo repo"

#Installing MongoDB server
dnf install mongodb-org -y &>>$LOG_FILE
validate $? "Installing MongoDB"

#Enabling MongoDB server
systemctl enable mongod &>>$LOG_FILE
validate $? "Enabling MongoDB"

#Starting MongoDB server
systemctl start mongod &>>$LOG_FILE
validate $? "Starting MongoDB"

#Changing remote connections allowing
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "Allowing remote connections to MongoDB"

#Restarting MongoDB server
systemctl restart mongod &>>LOG_FILE
validate $? "Restarting MongoDB"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in $Y $TOTAL_TIME seconds $N"