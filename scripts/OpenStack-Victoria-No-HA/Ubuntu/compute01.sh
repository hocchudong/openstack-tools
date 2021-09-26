#!/bin/bash
#Author HOC CHU DONG

DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"

source function.sh
source config.cfg
TIME_START=`date +%s.%N`

./com1_01_env.sh
./com1_02_nova_neutron.sh

TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify