

curl --location 'https://fai2.getoutline.com/api/documents.import' \
--header 'Accept: application/json' \
--header 'Content-Type: multipart/form-data' \
--header 'Authorization: Bearer ol_api_ZY01R39BqiZXhO3A5rzQzHqFa6yAmRhuUXNNhj' \
--form 'collectionId="ea128558-f8fc-438c-8885-729e36c20657"' \
--form 'parentDocumentId="2865fe3c-7c8a-42f6-8191-8c6e54c30df3"' \
--form 'template="false"' \
--form 'publish="true"' \
--form 'file=@"/C:/Users/Ric/Documents/GitProjects/markdown-css-themes/osh-2.md"' \
--form 'title="Osh Test2 Subdocument"'

