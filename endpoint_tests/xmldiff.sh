curl -s -X POST --data-binary "@$2" --header "Accept: application/xml" -o "response1.xml" \
	"http://ec2-52-90-157-139.compute-1.amazonaws.com/accounts-assessor/api/$1"
tr -d '\040\011\012\015' < "$3" > "response2.xml"
diff -w -s "response1.xml" "response2.xml" &>/dev/null
if [ $? -eq 0 ]
then
	echo "Invoking $1 with request $2 produces expected response."
else
	echo "Invoking $1 with request $2 produces unexpected response."
fi
rm "response1.xml"
rm "response2.xml"

