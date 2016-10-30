assignment="imc-assignment-9"

if [ "$#" -lt 1 ]
then
    echo date required as argument
    exit 1
fi


./classroom.sh grade classdata.txt ${assignment} "$1"
