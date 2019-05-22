#run with "http://ec2-52-90-157-139.compute-1.amazonaws.com/accounts-assessor/api/Loan"
#or "http://localhost:8080/"


cd endpoint_tests
./post_api_test.sh $1 loan-request1.xml loan-response1.xml
./post_api_test.sh $1 loan-request2.xml loan-response2.xml
./post_api_test.sh $1 loan-request3.xml loan-response3.xml
./post_api_test.sh $1 loan-request4.xml loan-response4.xml
./post_api_test.sh $1 loan-request5.xml loan-response5.xml
./post_api_test.sh $1 loan-request6.xml loan-response6.xml

