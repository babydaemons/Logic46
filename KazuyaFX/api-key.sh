#!/bin/sh
echo "松田和也大先生💛💛💛💛💛💛💛💛💛💛" | sha512sum | awk '{ printf("%s", $1) }' > api-key.txt
echo "中田さん💛💛💛💛💛💛💛💛💛💛" | sha512sum | awk '{ printf("%s", $1) }' >> api-key.txt
