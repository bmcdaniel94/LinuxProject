#!/usr/bin/gawk

BEGIN{
	FS=","
	OFS=","
}

{
if ($5 ~ /m/ || $5 ~/f/) {print}
}