FILEPATH=$1

if [ -f "$FILEPATH" ]
then
	# reset
	# echo -e "\e[3J"
	swipl -s process_data.pl  -g "debug,process_data2(_, '$FILEPATH'), halt."
	# 2>&1 1> arrrr-combined.xml | tee err; and begin; grep -q -E -i 'Warn|err' err; or  vim arrrr-combined.xml ; end
else
	echo "$FILEPATH not found"
fi
