curl -s -X POST --data-binary "@$2" --header "Accept: application/xml" -o "tmp/response1.xml" \
	"$1"
tr -d '\040\011\012\015' < "$3" > "tmp/response2.xml"
diff -w -s "tmp/response1.xml" "tmp/response2.xml" &>/dev/null
if [ $? -eq 0 ]
then
	echo "Posting $2 to $1 produces expected response: $3."
else
	echo "Posting $2 to $1 produces unexpected response."
fi
echo
rm "tmp/response1.xml"
rm "tmp/response2.xml"

