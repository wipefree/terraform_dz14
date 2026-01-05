#!/bin/bash

TARGET_DIR="./"
FILE_NAME=".builder_end"
FULL_PATH="$TARGET_DIR/$FILE_NAME"
TIMEOUT=300
INTERVAL=10

terraform init
terraform apply -auto-approve

for ((i=0; i<TIMEOUT; i+=INTERVAL)); do
    if [[ -f "$FULL_PATH" ]]; then

        mv make-img.tf make-img.tf-disable

        mv run-img.tf-disable run-img.tf
        terraform init
        terraform apply -auto-approve

        # instance builder (make-img.tf) will by deleted in the one time with start deploy (run-img.tf) instance
        # [ it's not needed ! ] -> terraform destroy -target=yandex_compute_instance.builder -auto-approve

        mv make-img.tf-disable make-img.tf
        mv run-img.tf run-img.tf-disable

        rm -f .builder_end
        exit 0
    fi
    sleep $INTERVAL
done

#echo "******************************************************"
#echo "* No information about completion of Builder actions *"
#echo "******************************************************"

terraform destroy -auto-approve

exit 1 
