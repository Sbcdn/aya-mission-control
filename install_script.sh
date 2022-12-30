#!/bin/bash

set -e

cd $HOME

teleFalg="$1"
teleFlagValue="--remote-hosted"

echo "----------- Installing grafana -----------"
sudo -S apt-get install -y adduser libfontconfig1
if [[ ! -f "${HOME}"/grafana_6.7.2_amd64.deb ]]; then
	wget https://dl.grafana.com/oss/release/grafana_6.7.2_amd64.deb
fi
sudo -S dpkg -i "${HOME}"/grafana_6.7.2_amd64.deb


echo "----------- Installing Go -----------"
sudo apt update -y && sudo apt install golang-go -y

echo "------ Starting grafana server using systemd --------"

sudo -S systemctl daemon-reload
sudo -S systemctl enable grafana-server
sudo -S systemctl start grafana-server

cd $HOME

echo "----------- Installing Influx -----------"

wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

sudo -S apt-get update && sudo apt-get install influxdb
sudo systemctl enable influxdb.service
sudo systemctl start influxdb.service
#sudo -S service influxdb start

echo "--------- Cloning cosmos-validator-mission-control -----------"

cd $HOME

if [[ ! -d /opt/aya/amc ]]; then
	mkdir /opt/aya/amc
fi

sudo cp "${HOME}"/aya-mission-control/config.toml /opt/aya/amc/config.toml
cd $HOME

if [ "$teleFalg" != "$teleFlagValue" ];
then 
	echo "----------- Installing telegraf -----------------"
	
	sudo -S apt-get update && sudo apt-get install telegraf
	sudo cp "${HOME}"/aya-mission-control/telegraf.conf /etc/telegraf/
	sudo systemctl enable telegraf.service
	sudo systemctl start telegraf.service
	#sudo -S service telegraf start

else
	echo "------remote-hosted enabled, so not downloading the telegraf--------"
fi

echo "------------Creating databases vcf and telegraf-------------"

curl "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE vcf"

curl "http://localhost:8086/query" --data-urlencode "q=CREATE DATABASE telegraf"

echo "------ Building and running the code --------"
cd "${HOME}"/aya-mission-control/
go build 
#&& ./cosmos-validator-mission-control

echo -e "--------- Configuring systemd ---------\n"

sudo ln -s "${HOME}"/aya-mission-control/cosmos-validator-mission-control /usr/local/bin/aya-mission-control >/dev/null 2>&1

sudo tee /etc/systemd/system/aya_mission_control.service > /dev/null <<EOF
[Unit]
Description=Aya Mission Control
After=network-online.target

[Service]
User=$USER
ExecStart=aya-mission-control
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

echo -e "--------- Starting Aya Mission Control ---------\n"
sudo systemctl daemon-reload
sudo systemctl enable aya_mission_control
sudo systemctl start aya_mission_control

echo -e "--------- Successful ---------"
