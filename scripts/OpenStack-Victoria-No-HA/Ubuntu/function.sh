#!/bin/bash
#Author HOC CHU DONG

source config.cfg

# Ham dinh nghia mau cho cac thong bao in ra man hinh
function echocolor {
    echo "$(tput setaf 2)##### $1 #####$(tput sgr0)"
}

# Ham sua file config cua OpenStack
## Ham add 
function ops_add {
	crudini --set $1 $2 $3 $4
}
### Cach dung
### Cu phap
### ops_add PATH_FILE SECTION PARAMETER VAULE

## Ham del
function ops_del {
	crudini --del $1 $2 $3
}

function notify {
        chatid=1977142239
        token=1117214915:AAF4LFh6uChng056_oTyM6cz9TY4dyAn3YU

if [ $? -eq 0 ]
then
  curl -s --data-urlencode "text=I-AM-OK" "https://api.telegram.org/bot$token/sendMessage?chat_id=$chatid" > /dev/null
  curl -s --data-urlencode "text=#######" "https://api.telegram.org/bot$token/sendMessage?chat_id=$chatid" > /dev/null
else
  curl -s --data-urlencode "text=NOT-OK" "https://api.telegram.org/bot$token/sendMessage?chat_id=$chatid" > /dev/null
  curl -s --data-urlencode "text=#######" "https://api.telegram.org/bot$token/sendMessage?chat_id=$chatid" > /dev/null

fi

}

function sendtelegram {
        chatid=1977142239
        token=1117214915:AAF4LFh6uChng056_oTyM6cz9TY4dyAn3YU
        default_message="Test canh bao"

        curl -s --data-urlencode "text=$@" "https://api.telegram.org/bot$token/sendMessage?chat_id=$chatid" > /dev/null
}