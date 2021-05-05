#!/usr/bin/gawk
# convert gender to m/f
BEGIN {
	FS= OFS = ","
}

{
if ($5 ~ /0/ || /male/) {$5 = "m"; print}
	else if ($5 ~ /1/ || /[fe]/) {$5 = "f"; print}
		else {print}
}
