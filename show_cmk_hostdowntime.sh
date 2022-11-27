#!/bin/bash
API_URL="https://<CMK_HOST>/<SITE>/check_mk/api/1.0"

echo -e "please provide automation user password: \n"
read -s pass
echo ""

if ! command -v jq &> /dev/null
then
    echo "'jq' could not be found"
    exit 1
fi

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


if (($HTTP_STATUS == 200));
then
   echo $HTTP_RESPONSE | \
         jq -r '["Hostname","User","Comment", "DowntimeID"],[.value[]
           | select(.domainType == "dict")
           | {"hostname": .extensions.host_name, "author": .extensions.author, "comment": .extensions.comment, "downtimeid": .id}
           | [.hostname, .author, .comment,.downtimeid]][]
           | @tsv' | column -t -s$'\t'
else
  echo $HTTP_RESPONSE
  echo $HTTP_STATUS
fi
