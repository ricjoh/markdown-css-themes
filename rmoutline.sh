#!/bin/bash
# get TITLE and DOCID from STDIN tab-separated file
while IFS=$'\t' read -r DOCID; do
  echo
  echo "DOCID: $DOCID"

curl https://app.getoutline.com/api/documents.delete \
  -s \
  --request POST \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer ol_api_ZY01R39BqiZXhO3A5rzQzHqFa6yAmRhuUXNNhj' \
  --data @<(cat <<EOF
{
      "id": "$DOCID",
      "permanent": false
}
EOF
) | jq '.success'

done
echo
