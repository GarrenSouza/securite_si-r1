#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install -y default-jre
sudo apt install -y default-jdk

su vagrant
mkdir software
cd software
wget https://archive.apache.org/dist/activemq/5.17.5/apache-activemq-5.17.5-bin.tar.gz
tar -xvzf apache-activemq-5.17.5-bin.tar.gz
cd apache-activemq-5.17.5/bin
chmod +x ./activemq
./activemq console 2>&1 > logger.log &

