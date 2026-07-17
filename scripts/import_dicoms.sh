#!/usr/bin/env bash

dicom_port=8104. # check
while true
do
  sleep 60
  for dir in /data/import_data/*; do
        if [ -d "${dir}" ]; then
            num1=$(find $dir -type f | wc -l)
            #echo "$dir $num1"
            sleep 60
            num2=$(find $dir -type f | wc -l)
           #echo "$dir $num2"
            if [ "$num1" == "$num2" ] && [ "$num1" != "0" ];
            then
                printf "\n $(date): Found DICOMs in import directory. Numbers static, importing $dir \n"

                find  "$dir" -name *.log -print0 | xargs -0 rm
                find  "$dir" -name *.xml -print0 | xargs -0 rm
                find  "$dir" -name *.json -print0 | xargs -0 rm
                dcmsend +sd +r -aec XNAT -aet XNAT localhost 8104 "$dir"
                rm -r $dir
            fi
        fi
    done
done