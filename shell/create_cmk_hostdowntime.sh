#!/bin/bash
API_URL="https://<CMK_HOST>/<SITE>/check_mk/api/1.0"
echo -e "please provide automation user password: \n"
read -s pass
echo ""

function create_cmk_host_downtime(){
 host=$1

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
          "start_time": "2022-11-25T13:06:00Z",
          "end_time": "2022-11-27T18:00:00Z",
          "host_name": "'"$host"'",
          "recur": "fixed"
        }' \
    "$API_URL/domain-types/downtime/collections/host")

HTTP_STATUS=$(echo "$HTTP_RESPONSE" | awk '/~~HTTP~~STATUS~~CODE~~/{match($0, /~~HTTP~~STATUS~~CODE~~(...)/, m); print int(m[1])}')
HTTP_RESPONSE="${HTTP_RESPONSE/~~HTTP~~STATUS~~CODE~~???/}"

# cmk API Documentation
# 204 No Content: Operation done successfully.
if (($HTTP_STATUS == 204));
then
   echo "[${host}] --> Success($HTTP_STATUS)"
else
  echo $HTTP_RESPONSE
fi

}

if ! command -v jq &> /dev/null
then
    echo "'jq' could not be found"
    exit 1
fi


create_cmk_host_downtime $1
# OR
#while read -r host;
#do
#  echo "hostdowntime:--> ${host}"
#  create_cmk_host_downtime "${host}"
#  sleep  .5
#done < list.txt
