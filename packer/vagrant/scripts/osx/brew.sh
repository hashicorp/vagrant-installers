#!/bin/bash -eux

result=1
attempts=0
while [ "${result}" -ne "0" ]
do
    TRAVIS=1 su vagrant -l -c 'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install | sed 's%https://github%git://github%g')"'
    result=$?
    attempts=$(expr $attempts + 1)
    if [ $attempts -gt 5 ]
    then
        echo "Failed to install homebrew!"
        exit 1
    else
        sleep 2
    fi
done

