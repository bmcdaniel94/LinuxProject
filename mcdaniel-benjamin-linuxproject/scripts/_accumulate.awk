#!/usr/bin/gawk

BEGIN { 
    FS=OFS="," 
}
{  
{ $5=sum[$1]+=$5; customer[$1]=$0 }
}
END { 
for (c in customer) print customer[c] 
}