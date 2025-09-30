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
MYSQL_HOST=mysql.rahulsai.com

mkdir -p $LOGS_FOLDER
echo "Script started executing at $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo "Error: Please run this script root privilege"
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

dnf install maven -y &>>$LOG_FILE
validate $? "Installing Maven"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    validate $? "Creating system user"
else
    echo -e "User already exists...$Y Skipping $N"
fi

mkdir -p /app
validate $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
validate $? "Downloading Application"

cd /app

rm -rf /app/*
validate $? "Removing old code"

unzip /tmp/shipping.zip &>>$LOG_FILE
validate $? "Unzipping Application"

mvn clean package
validate $? "Installing Dependencies"

mv target/shipping-1.0.jar shipping.jar

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
validate $? "Copying systemctl file"

systemctl daemon-reload

systemctl enable shipping &>>$LOG_FILE
validate $? "Enabling Shipping"

systemctl restart shipping &>>$LOG_FILE
validate $? "Restarting Shipping"

dnf install mysql -y &>>$LOG_FILE
validate $? "Installing MySQL client"

#MySQL shell script to check schema exist or not
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded... $Y Skipping $N"
fi

systemctl restart shipping

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script executed in $Y $TOTAL_TIME seconds $N"
