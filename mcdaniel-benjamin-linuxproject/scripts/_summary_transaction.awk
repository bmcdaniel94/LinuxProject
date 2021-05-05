#!/usr/bin/gawk

BEGIN{
	FS=","
	OFS=","
}

{
{print $1,$12,$13,$3,$2,$6}
}