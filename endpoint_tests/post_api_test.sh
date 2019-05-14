curl -s -X POST --data-binary "@$2" --header "Accept: application/xml" -o "response1.xml" \
	"$1"
tr -d '\040\011\012\015' < "$3" > "response2.xml"
diff -w -s "response1.xml" "response2.xml" &>/dev/null
if [ $? -eq 0 ]
then
	echo "Posting $2 to $1 produces expected response: $3."
else
	echo "Posting $2 to $1 produces unexpected response."
fi
echo
rm "response1.xml"
rm "response2.xml"

