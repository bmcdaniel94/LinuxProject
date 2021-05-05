#!/bin/bash
# Benjamin McDaniel
# 4-1-21
# Project

# check parameters are correct
if (($# != 3)); then
	echo "Usage: $0 USER IP FILEPATH" ; exit 1
fi
#if [[ ! -f "$3" ]]; then
	#echo "Third paramter must be a normal file (\$1)($1)"; exit 1
#fi

# Declare Vars
userid="$1"
remote_server="$2"
file_path="$3"

src_file="$(basename $file_path)"
coder="Benjamin McDaniel"


function rm_temps() {
	printf "*** WARNING!!! - This will delete all CSV files and tmp files leaving only transaction-rpt && purchase-rpt***\n"
	read -p "Delete Temporary Files? (Y/n): "
	if [[ $REPLY = [Yy] ]]; then
		rm *.tmp
		rm *.csv
		echo "Temporary Files Deleted"
	fi
}

#Remote Server IP Address: 40.69.135.45
#Server files location: /home/shared/MOCK_MIX_v2.1.csv.bz2
#./etl.sh bmcdaniel5@40.69.135.45:/home/shared/MOCK_MIX_v2.1.csv.bz2 ~/downloads/mcdaniel-benjamin-linuxproject/
# 1) Import File --- WORKS
printf "1) Importing file -- complete\n"
scp "$userid"@"$remote_server":"$file_path" .
 
# 2) Extract contents of downloaded file --- WORKS
bunzip2 $src_file # src_file = DemoData*.csv.bz2
main_file="${src_file%.*}" #main_file = DemoData*.csv
printf "2) Unzip file $main_file -- complete\n"

# 3) Remove the header from the file --- WORKS
tail -n +2 "$main_file" > "01_rm_header.tmp"
printf "3) Removed header from file -- complete\n"

# 4) Convert all text to lower case --- WORKS
tr '[:upper:]' '[:lower:]' < "01_rm_header.tmp" > "02_conv_lower.tmp"
printf "4) Converted all text to lowercase -- complete\n"

# 5) Convert male, female, 0, 1 to universal 0 -> m , 1 -> f --- WORKS
printf "5) Converted male(0) and female(1) to m & f standard  -- Complete"
gawk -F "," -f "scripts/_conv_gender.awk" "02_conv_lower.tmp" > "03_conv_gender.tmp"


printf "\n"
# 6) Filter out all records that do not contain statefrom --- WORKS
printf "6) filter out all records not containing states -- complete\n"
awk -F, '{ print >($12==""?"exceptions.csv":"04_filter_bad_data.tmp") }' "03_conv_gender.tmp"

# 7) Remove $ sign from the purchase _amt Field ($6) --- WORKS
printf "7) Remove '$' from transaction amount -- complete\n"
tr -d '"$' < "04_filter_bad_data.tmp" > "05_dollar_removed.tmp"

# 8) sort transction file by customerid  -- WORKS
printf "8) sort by customerid -- complete\n"
sort -k1 -s "05_dollar_removed.tmp" > "transactions.csv"


# 9)Accumulate total purchase amount for each "customerID" and produce a new file with a single
#record per customerID and the total amount over all records for that customer. Use commas as
#your field delimiter.
#The fields in this file should be in this order:
#	customerID, state, zip, lastname, firstname, total purchase amount  ---- WORKS
printf "9) reprinted customerID, state, zip, lastname, firstname, total purchase amount -- complete\n"
awk 'BEGIN{ FS=OFS="," }
   { $6=sum[$1]+=$6; customer[$1]=$0 }
END{ for (c in customer) print customer[c] }' "transactions.csv" > "07_accum.tmp"
gawk -F "," -f "scripts/_summary_transaction.awk" < "07_accum.tmp" > "accum.csv"
tr -d ' ' < accum.csv > summary.csv

#gawk -F "," -f "scripts/_accumulate.awk" < "transactions.csv" < "transactions_out.tmp"


# 10) sort the summary file based upon  a)state b)zip c)lastname d)firstname order same as 8 file summary should be called summmary.csv
sort -t ',' -k2 -k3nr -k4 -k5 summary.csv

# 11) generate transaction a) reports and b) purchase reports
awk 'BEGIN{ FS=OFS="," }
    { arr_state[toupper($2)]++$6 }
END {
    print "Transaction Count Report"
	print "\n"
	print "State\t" "Transaction Count"
    for (id in arr_state) {
        printf "%-10s %d\n", id, arr_state[id]
    }
}' < "summary.csv" > "transaction-rpt"

awk 'BEGIN{ FS=OFS="," }
    { arr_state[toupper($12) "\t\t\t" toupper($5)]+=$6 }
END {
    print "Purchase Count Report"
	print "State\t" "Gender\t" "Transaction Amount"
    for (id in arr_state) {
        printf "%-10s %.2f\n", id, arr_state[id]
    }
}' < "07_accum.tmp" > "purchase-rpt"
# 12) remove temp files
rm_temps #call function

exit 1

