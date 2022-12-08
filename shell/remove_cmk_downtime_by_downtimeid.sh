#!/bin/bash

API_URL="https://CMK_URL/<SITE>/check_mk/api/1.0"

echo -e "please provide automation user password: \n"
read -s pass
echo ""

# gets all downtimes in json
function cmk_get_downtimes(){
HTTP_RESPONSE=$(curl \
    --request GET \
    --insecure \
    --silent \
    --show-error \
    --header "Authorization: Bearer automation ${pass}" \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --write-out "~~HTTP~~STATUS~~CODE~~%{http_code}" \
    "$API_URL/domain-types/downtime/collections/all")

HTTP_STATUS=$(echo "$HTTP_RESPONSE" | awk '/~~HTTP~~STATUS~~CODE~~/{match($0, /~~HTTP~~STATUS~~CODE~~(...)/, m); print int(m[1])}')
HTTP_RESPONSE="${HTTP_RESPONSE/~~HTTP~~STATUS~~CODE~~???/}"

if (($HTTP_STATUS != 200));
then
  echo $HTTP_RESPONSE
  exit 253
fi

}

function cmk_get_downtimeid_by_hostname(){
 local hostname did
 hostname="$1"
 did=$(echo $HTTP_RESPONSE | jq -r --arg hostname $hostname  '.value[] | select(.extensions.host_name == $hostname).id // empty')
 [[ -z $did ]] && echo "NaN" || echo $did

}

function cmk_delete_hostdowntime_by_id(){
  local downtime_id
  downtimeid="$1"
  RESPONSE=$(curl \
    --request POST \
    --insecure \
    --silent \
    --show-error \
    --header "Authorization: Bearer automation ${pass}" \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --write-out "~~HTTP~~STATUS~~CODE~~%{http_code}" \
    --data '{
          "delete_type": "by_id",
          "downtime_id": "'"$downtimeid"'"
        }' \
    "$API_URL/domain-types/downtime/actions/delete/invoke")

STATUS=$(echo "$RESPONSE" | awk '/~~HTTP~~STATUS~~CODE~~/{match($0, /~~HTTP~~STATUS~~CODE~~(...)/, m); print int(m[1])}')
RESPONSE="${RESPONSE/~~HTTP~~STATUS~~CODE~~???/}"

if (($STATUS == 204));
then
  echo "[DOWNTIME-$downtimeid] --> success"
else
  echo "[DOWNTIME-$dowtimeid] --> failed"
fi
}


#######################################################
if ! command -v jq &> /dev/null
then
    echo "'jq' could not be found"
    exit 1
fi


cmk_get_downtimes
cmk_downtime_id=$(cmk_get_downtimeid_by_hostname $1)

if [[ $cmk_downtime_id  != "NaN" ]];
then
  echo "[$1] --> removing, downtime with id $cmk_downtime_id"
  cmk_delete_hostdowntime_by_id $cmk_downtime_id
else
  echo "[$1] --> host does not have downtime id, skipping..."
fi
