#!/bin/bash
RG="rg-app"
VM="vm-k3s"
LOC="centralindia"
ADMIN="azureuser"
SIZE="Standard_B1s"

az group create -n $RG -l $LOC

az vm create \
  --resource-group $RG \
  --name $VM \
  --image UbuntuLTS \
  --size $SIZE \
  --admin-username $ADMIN \
  --ssh-key-values ~/.ssh/id_rsa.pub
