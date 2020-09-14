#!/bin/bash

echo "creating autoregistration stack"
zip -j orm-stack-dnszone-autoregister.zip ../infrastructure/*.tf ../infrastructure/schema.yml
cp orm-stack-dnszone-autoregister.zip ../release
cp orm-stack-dnszone-autoregister.zip ~/Downloads
rm orm-stack-dnszone-autoregister.zip

echo "creating minimal stack"
zip -j orm-stack-dnszone.zip ../infrastructure/*.tf ../infrastructure/orm/schema.yml
cp orm-stack-dnszone.zip ../release
cp orm-stack-dnszone.zip ~/Downloads
rm orm-stack-dnszone.zip

