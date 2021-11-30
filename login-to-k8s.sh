export COMMAND=`terraform output -json | jq .get_cluster_credentials.value -r`
eval $COMMAND