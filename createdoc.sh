#!/bin/bash

count=0

# get TITLE and URL from STDIN tab-separated file
while IFS=$'\t' read -r URL TITLE; do
  echo "Title: $TITLE" >&2
  #  echo "URL: $URL"
((count++))
curl "$URL" -s | pandoc -f mediawiki -t markdown -o "./docs/$TITLE.md"

./stripmd.pl < "./docs/$TITLE.md" > "./docs/$TITLE-clean.md"

ID=$(curl --location 'https://fai2.getoutline.com/api/documents.import' \
-s \
--header 'Accept: application/json' \
--header 'Content-Type: multipart/form-data' \
--header 'Authorization: Bearer ol_api_ZY01R39BqiZXhO3A5rzQzHqFa6yAmRhuUXNNhj' \
--form 'collectionId="ea128558-f8fc-438c-8885-729e36c20657"' \
--form 'parentDocumentId="d9fa9f5e-e7dc-4069-a576-165ac7a34eff"' \
--form 'template="false"' \
--form 'publish="true"' \
--form "file=@\"./docs/$TITLE-clean.md\"" | jq -r '.data.id')

curl --location 'https://fai2.getoutline.com/api/documents.update' \
-s \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer ol_api_ZY01R39BqiZXhO3A5rzQzHqFa6yAmRhuUXNNhj' \
--data @<(cat <<EOF
{
"id": "$ID",
"title": "$TITLE",
"text": "\n\n\n**This page has been imported from wiki.fai2.com**",
"append": true,
"publish": true,
"done": true
}
EOF
) | jq -r '.data.url | split( "-" ) | last'

  if (( count % 20 == 0 )); then
    echo "Processed $count documents — pausing for 60 seconds..." >&2
    sleep 60
  fi

done

