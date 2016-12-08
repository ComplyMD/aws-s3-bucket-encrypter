# AWS S3 Bucket Encrypter

### Encrypts all objects in a S3 Bucket

    Usage: bucket_encrypter.rb [options]
        -b, --bucket NAME                REQUIRED - Name of the bucket to encrypt the contents of
        -r, --region NAME                REQUIRED - Region in which the bucket to be encrypted is located
        -k, --access-key KEY             Access Key ID AWS credential
        -s, --secret-access-key KEY      Secret Access Key AWS credential
        -n, --batch-size NUMBER          Size of batches to retrieve from bucket. Defaults to 100
        -c, --cipher NAME                Method with which the objects will encrypted. Accepts aws:kms or AES256. Defaults to AES256
        -v, --verbose                    Output more information. Useful for debugging or if you want to be sure things are actually working