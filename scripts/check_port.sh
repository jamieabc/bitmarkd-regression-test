#!/usr/local/bin/bash
node_number=0
while true
do
    array=("1" "2" "3" "4" "5")
    for number in "${array[@]}"
    do
        normal_mode=$(curl -s -k "https://localhost:2${number}31/bitmarkd/details" | jq | grep -c Normal)
    if [ $normal_mode -ne 0 ]; then
        echo "node ${number} in Normal mode, cli port 2${number}30, https port 2${number}31"
        node_number=$number
        break 2                 # break 2 levels of loop
    fi
    done
    echo "waiting nodes to sync with other server..."
    sleep 5
done
