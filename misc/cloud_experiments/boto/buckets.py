import boto3

# Let's use Amazon S3
s3 = boto3.resource('s3')

#Now that you have an s3 resource, you can make requests and process responses from the service. The following uses the buckets collection to print out all bucket names:

# Print out bucket names
for bucket in s3.buckets.all():
    print(bucket.name)

