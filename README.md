## Irwin

Irwin is an activitypub and indieauth server. Users are known on the social web using their own domain rather than this server's domain.

### Example blank-gh-site

This [blank-gh-site](https://github.com/otisburgsocial/blank-gh-site) adds 3 small commits to show indieauth and webfinger config needed to use these features on [otisburg.social](https://otisburg.social) which is running the irwin server code.  The first commit is created automatically by github when you configure custom domain which appears after you select branch under "Pages" under "Code and automation" sidebar for the blank-gh-site project.

The third commit is not required to register as it is for webfinger configuration and can be done later when creating the optional fediverse account to be associated with the user.

### Irwin Required environment variables:

* SERVER_NAME - hostname of your server like: example.herokuapp.com
* S3_BUCKET_NAME - amazon s3 bucket to store media
* AMAZON_ACCESS_KEY_ID - your id for amazon s3
* AMAZON_SECRET_ACCESS_KEY - your secret for amazon s3

### Irwin Optional environment variables:

* INDIEAUTH_TIME_ZONE - timezone of your server (default: UTC) like: Central Time (US & Canada)
* DEEPL_AUTH_KEY - authentication key for DeepL

* EXCEPTION_NOTIFICATION - comma separated list of emails to receive exception notifications for troubleshooting
* EXCEPTION_MAILBOX - mailbox (like support) of from address for exception notifications (default: app.error)
* SMTP_DOMAIN - like example.com
* SMTP_PASSWORD - your smtp password
* SMTP_PORT - default is 587
* SMTP_SERVER - like smtp.example.com
* SMTP_USER - your smtp user
