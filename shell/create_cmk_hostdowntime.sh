#!/bin/bash
cmk_base_api_addr="http://127.0.0.1:5000/monitoring/check_mk/api/1.0"
echo -e "please provide automation user password: \n"
read -r -s pass
echo ""
echo -e "please provide downtime in minutes: \n"
read -r downtime_in_minutes
echo ""

function create_cmk_host_downtime(){
 host=$1
 downtime_in_minutes=$2
 stime=$(date --utc '+%Y-%m-%dT%H:%M:%SZ')
 etime=$(date --utc '+%Y-%m-%dT%H:%M:%SZ' -d "+ ${downtime_in_minutes} minutes")
 HTTP_RESPONSE=$(curl \
    --request POST \
    --insecure \
    --silent \
    --show-error \
    --header "Authorization: Bearer automation ${pass}" \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --write-out "~~HTTP~~STATUS~~CODE~~%{http_code}" \
    --data '{
          "comment": "Maintenance",
          "downtime_type": "host",
          "start_time": "'"$stime"'",
          "end_time": "'"$etime"'",
          "host_name": "'"$host"'",
          "recur": "fixed"
        }' \
    "$cmk_base_api_addr/domain-types/downtime/collections/host")

HTTP_STATUS=$(echo "$HTTP_RESPONSE" | awk '/~~HTTP~~STATUS~~CODE~~/{match($0, /~~HTTP~~STATUS~~CODE~~(...)/, m); print int(m[1])}')
HTTP_RESPONSE="${HTTP_RESPONSE/~~HTTP~~STATUS~~CODE~~???/}"

# cmk API Documentation
# 204 No Content: Operation done successfully.
if ((HTTP_STATUS == 204));
then
   echo "[${host}] --> Success($HTTP_STATUS)"
else
  echo "${HTTP_RESPONSE}"
fi

}

if ! command -v jq &> /dev/null
then
    echo "'jq' could not be found"
    exit 1
fi


create_cmk_host_downtime "${1}" "${downtime_in_minutes}"
# OR
#while read -r host;
#do
#  echo "hostdowntime:--> ${host}"
#  create_cmk_host_downtime "${host}" "${downtime_in_minutes}"
#  sleep  .5
#done < list.txt
