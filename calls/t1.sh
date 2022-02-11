#!/bin/sh -x

a=01
b=12

#echo $(($a > $b ? $a : $b))

#for i in {1..10000}; do
#	echo 5.555 | awk '{print $1 / 4}'
#done

number1="1.01"
number2="1.02"

[ ${number1%.*} -eq ${number2%.*} ] && [ ${number1#*.} \> ${number2#*.} ] || [ ${number1%.*} -gt ${number2%.*} ]
[ $? -eq 0 ] && number=$number1 || number=$number2
echo $number
