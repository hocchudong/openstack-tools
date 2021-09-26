#!/bin/bash
#Author HOC CHU DONG

TIMEDATE_EXEC="$(date "+%d/%m/%Y %H:%M")"

source function.sh
source config.cfg
TIMEDATE_START=`date +%s.%N`

./com1_01_env.sh
./com1_02_nova_neutron.sh

TIMEDATE_END=`date +%s.%N`
TIMEDATE_TOTAL_TEMP=$( echo "$TIMEDATE_END - $TIMEDATE_START" | bc -l )
TIMEDATE_TOTAL=$(cut -c-6 <<< "$TIMEDATE_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $TIMEDATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIMEDATE_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $TIMEDATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIMEDATE_TOTAL giay"
notify