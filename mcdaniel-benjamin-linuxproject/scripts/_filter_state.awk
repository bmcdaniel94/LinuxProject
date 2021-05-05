#!/usr/bin/gawk

BEGIN{
	FS=","
	OFS=","
}

{
if ($12 ~ /[a-z]/ {print}
}