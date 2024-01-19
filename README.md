# README

Required environment variables:

* SERVER_NAME - hostname of your server like: example.herokuapp.com
* S3_BUCKET_NAME - amazon s3 bucket to store media
* AMAZON_ACCESS_KEY_ID - your id for amazon s3
* AMAZON_SECRET_ACCESS_KEY - your secret for amazon s3

Optional environment variables:

* INDIEAUTH_TIME_ZONE - timezone of your server (default: UTC) like: Central Time (US & Canada)

* EXCEPTION_NOTIFICATION - comma separated list of emails to receive exception notifications for troubleshooting
* SMTP_DEFAULT_FROM - like support@example.com
* SMTP_DOMAIN - like example.com
* SMTP_PASSWORD - your smtp password
* SMTP_PORT - default is 587
* SMTP_SERVER - like smtp.example.com
* SMTP_USER - your smtp user
