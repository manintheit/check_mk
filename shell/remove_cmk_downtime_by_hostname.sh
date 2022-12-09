#!/bin/bash

cmk_base_api_addr="http://127.0.0.1:5000/monitoring/check_mk/api/1.0"

echo -e "please provide automation user password: \n"
read -r -s pass
echo ""

function cmk_remove_hostdowntime_by_hostname(){
  hostname="$1"
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
          "delete_type": "params",
          "host_name": "'"$hostname"'"
        }' \
    "$cmk_base_api_addr/domain-types/downtime/actions/delete/invoke")

HTTP_STATUS=$(echo "$HTTP_RESPONSE" | awk '/~~HTTP~~STATUS~~CODE~~/{match($0, /~~HTTP~~STATUS~~CODE~~(...)/, m); print int(m[1])}')
HTTP_RESPONSE="${HTTP_RESPONSE/~~HTTP~~STATUS~~CODE~~???/}"

# cmk API Documentation
# 204 No Content: Operation done successfully.
if ((HTTP_STATUS == 204));
then
   echo "[${hostname}] --> Success($HTTP_STATUS)"
else
  echo "${HTTP_RESPONSE}"
fi
}

if ! command -v jq &> /dev/null
then
    echo "'jq' could not be found"
    exit 1
fi

cmk_remove_hostdowntime_by_hostname "${1}"

# OR
#while read -r host;
#do
#  echo "remove host downtime for:--> ${host}"
#  cmk_remove_hostdowntime_by_hostname "${host}"
#  sleep  .5
#done < list.txt
