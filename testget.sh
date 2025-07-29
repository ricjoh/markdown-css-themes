wget --no-check-certificate --quiet \
     --method POST \
     --timeout=0 \
     --header 'Accept: application/json' \
     --header 'Content-Type: application/json' \
     --header 'Authorization: Bearer ol_api_ZY01R39BqiZXhO3A5rzQzHqFa6yAmRhuUXNNhj' \
     --body-data '{
  "offset": 0,
  "limit": 25,
  "sort": "updatedAt",
  "direction": "DESC",
  "query": "",
  "statusFilter": [
  ]
}' \
     'https://fai2.getoutline.com/api/collections.list'



wget --quiet \
  --method POST \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer ol_api_ZY01R39BqiZXhO3A5rzQzHqFa6yAmRhuUXNNhj' \
  --body-data '{"id":"4bbmp3Z062","permanent":false}' \
  --output-document \
  - https://app.getoutline.com/api/documents.delete
