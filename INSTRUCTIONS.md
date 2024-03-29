# Validator Mission Control

**Validator Mission Control** provides a comprehensive set of metrics and alerts for Cosmos validator node operators. We utilized the power of Grafana + Telegraf and extended the monitoring & alerting with a custom built go server. It also sends emergency alerts and calls to you based on your pagerduty account configuration.

It can be installed on a validator node directly or a separate monitoring node (with an appropriate firewall setup on validator node). These instructions assume the user will install Validator Mission Control on the validator. [See this section](#hosting-validator-mission-control-on-separate-monitoring-node) for details on installing it on a separate monitoring node. 

## Install Prerequisites
- **Go 1.13.x+**
- **Docker 19+**
- **Grafana 6.7+**
- **InfluxDB 1.7+**
- **Telegraf 1.14+**
- **Gaia client**

## You can run this installation script to setup the monitoring tool

- One click installation to download grafana, telegraf, influxdb.
- Also it will create the databases(vcf and telegraf). If you configure different database names make sure to create those in influxDB.
- If you are running telegraf on someother node run script by giving --remote-hosted flag so that the script don't start telegraf in current node (ex: ./install_script.sh --remote-hosted)
- Here you can find
[script file](https://github.com/Chainflow/cosmos-validator-mission-control/blob/script/install_script.sh).
- To run script 
```bash
chmod +x install_script.sh
./install_script.sh

```
- After installation you just need to configure the config.toml and start the monitoring tool server.
- Follow further steps to setup grafana dashboards.

### A - Install Grafana for Ubuntu
Download the latest .deb file and extract it by using the following commands

```sh
$ cd $HOME
$ sudo -S apt-get install -y adduser libfontconfig1
$ wget https://dl.grafana.com/oss/release/grafana_6.7.2_amd64.deb
$ sudo -S dpkg -i grafana_6.7.2_amd64.deb
```

Start the grafana server
```sh
$ sudo -S systemctl daemon-reload

$ sudo -S systemctl start grafana-server

Grafana will be running on port :3000 (ex:: https://localhost:3000)
```

### Install InfluxDB and Telegraf

```sh
$ cd $HOME
$ wget -q https://repos.influxdata.com/influxdata-archive_compat.key
$ echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
$ echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
```

Start influxDB

```sh
$ sudo -S apt-get update && sudo apt-get install influxdb
$ sudo -S service influxdb start

The default port that runs the InfluxDB HTTP service is :8086
```

**Note :** If you want cusomize the configuration, edit `influxdb.conf` at `/etc/influxdb/influxdb.conf` and don't forget to restart the server after the changes. You can find a sample 'influxdb.conf' [file here](https://github.com/jheyman/influxdb/blob/master/influxdb.conf).


Start telegraf

```sh
$ sudo -S apt-get update && sudo apt-get install telegraf
$ sudo -S service telegraf start
```

### Setup a rest server on the validator instance
If your validator instance does not have a rest server running, execute this command to setup the rest server

```sh
gaiacli rest-server --chain-id cosmoshub-3 --laddr tcp://127.0.0.1:1317
```

## Install and configure the Validator Mission Control

### Get the code

```bash
$ git clone https://github.com/Chainflow/cosmos-validator-mission-control.git
$ cd cosmos-validator-mission-control
$ cp example.config.toml config.toml
```

### Configure the following variables in `config.toml`

- *tg_chat_id*

    Telegram chat ID to receive Telegram alerts, required for Telegram alerting.
    
- *tg_bot_token*

    Telegram bot token, required for Telegram alerting. The bot should be added to the chat and should have send message permission.

- *email_address*

    E-mail address to receive mail notifications, required for e-mail alerting.

- *sendgrid_token*

    Sendgrid mail service api token, required for e-mail alerting.
    
- *missed_blocks_threshold*

    Configure the threshold to receive  **Missed Block Alerting**, e.g. a value of 10 would alert you every time you've missed 10 consecutive blocks.
    
- *block_diff_threshold*

    An integer value to receive **Block difference alerts**, e.g. a value of 2 would alert you if your validator falls 2 or more blocks behind the chain's current block height.

- *alert_time1* and *alert_time2*

    These are for regular status updates. To receive validator status daily (twice), configure these parameters in the form of "02:25PM". The time here refers to UTC time.

- *voting_power_threshold*

    Configure the threshold to receive alert when the voting power reaches or drops below of the threshold given.

- *num_peers_threshold*

    Configure the threshold to get an alert if the no.of connected peers falls below the threshold.

- *enable_telegram_alerts*

    Configure **yes** if you wish to get telegram alerts otherwise make it **no** .

- *enable_email_alerts*

    Configure **yes** if you wish to get email alerts otherwise make it **no** .

- *validator_rpc_endpoint*

    Validator rpc end point (RPC of your own validator) useful to gather information about network info, validator voting power, unconfirmed txns etc.

- *val_operator_addr*

    Operator address of your validator which will be used to get staking, delegation and distribution rewards.

- *account_addr* 

    Your validator account address which will be used to get account informtion etc.

- *validator_hex_addr*

    Validator hex address useful to know about last proposed block, missed blocks and voting power.

- *lcd_endpoint*

    Address of your lcd client (ex: http://localhost:1317).

    **Note** : To start the lcd server for stargate node please do the following:
    
    - Go to `config/app.toml`
    - You can find below fields in that file
        ```bash 
           # Enable defines if the API server should be enabled.
           enable = false
        ```
    - Then make it `true` and restart the server.


- *external_rpc*

    External open RPC endpoint(secondary RPC other than your own validator). Useful to gather information like validator caught up, syncing and missed blocks etc.

- *staking_denom*

    Give stakig denom to display along with self delegation balance (ex:uatom or umuon)

- *pagerduty_email*

    Give mail address of pager duty service to send alerts of emergency missed blocks.
    Note : Have to give mail address which was generated after creation of a service in pager duty.

    You can refer this to know about pagerduty (https://www.pagerduty.com/)

- *emergency_missed_blocks_threshold*

    Give threshold to notify about continuous missed blocks to your pager duty account. so that it will send mails, messages and makes you a call about alerts.

After populating config.toml, check if you have connected to influxdb and created a database which you are going to use.

If your connection throws error "database not found", create a database

```bash
$   cd $HOME
$   influx
>   CREATE DATABASE db_name

ex: CREATE DATABASE vcf
ex: CREATE DATABASE telegraf
```

After all these steps, build and run the monitoring binary

```bash
$ go build -o chain-monit && ./chain-monit
```

### Run using docker
```bash
$ docker build -t cfv .
$ docker run -d --name chain-monit cfv
```

We have finished the installation and started the server. Now lets configure the Grafana dashboard.

## Grafana Dashboards

Validator Mission Control provides three dashboards

1. Validator Monitoring Metrics (These are the metrics which we have calculated and stored in influxdb)
2. System Metrics (These are the metrics related to the system configuration which come from telegraf)
3. Summary (Which gives quick overview of validator and system metrics)


### 1. Validator monitoring metrics
The following list of metrics are displayed in this dashboard.

- Validator Details :  Displays the details of a validator like moniker, website, keybase identity and details.
- Gaiad Status :  Displays whether the gaiad is running or not in the form of UP and DOWN.
- Validator Status :  Displays the validator health. Shows Voting if the validator is in active state or else Jailed.
- Gaiad Version : Displays the version of gaia currently running.
- Validator Caught Up : Displays whether the validator node is in sync with the network or not.
- Block Time Difference : Displays the time difference between previous block and current block.
- Current Block Height :  Validator : Displays the current block height committed by the validator.
- Latest Block Height : Network : Displays the latest block height of a network.
- Height Difference : Displays the difference between heights of validator current block height and network latest block height.
- Last Missed Block Range : Displays the continuous missed blocks range based on the threshold given in the config.toml
- Blocks Missed In last 48h : Displays the count of blocks missed by the validator in last 48 hours.
- Unconfirmed Txns : Displays the number of unconfirmed transactions on that node.
- No.of Peers : Displays the total number of peers connected to the validator.
- Peer Address : Displays the ip addresses of connected peers.
- Latency : Displays the latency of connected peers with respect to the validator.
- Validator Fee : Displays the commission rate of the validator.
- Max Change Rate : Displays the max change rate of the commission.
- Max Rate : Displays the max rate of the commission.
- Voting Power : Displays the voting power of the validator.
- Self Delegation Balance : Displays delegation balance of the validator.
- Current Balance : Displays the account balance of the validator.
- Unclaimed Rewards : Displays the current unclaimed rewards amount of the validator.
- Last proposed Block Height : Displays height of the last block proposed by the validator.
- Last Proposed Block Time : Displays the time of the last block proposed by the validator.
- Voting Period Proposals : Displays the list of the proposals which are currently in voting period.
- Deposit Period Proposals : Displays the list of the proposals which are currently in deposit period.
- Completed Proposals : Displays the list of the proposals which are completed with their status as passed or rejected.


**Note:** The above mentioned metrics will be calculated and displayed according to the validator address which will be configured in config.toml.

For alerts regarding system metrics, a Telegram bot can be set up on the dashboard itself. A new notification channel can be added for the Telegram bot by clicking on the bell icon on the left hand sidebar of the dashboard. 

This will let the user configure the Telegram bot ID and chat ID. **A custom alert** can be set for each graph in a Grafana dashboard by clicking on the edit button and adding alert rules.

### 2. System Monitoring Metrics
These are powered by telegraf.

-  For the list of system monitoring metrics, you can refer `telgraf.conf`. You can replace the file with your original telegraf.conf file which will be located at /telegraf/etc/telegraf (installation directory).
 
 ### 3. Summary Dashboard
This dashboard displays a quick information summary of validator details and system metrics. It includes following details.

- Validator identity (Moniker, Website, Keybase Identity, Details, Operator Address and Account Address)
- Validator summary (Gaiad Status, Validator Status, Voting Power, Height Difference and No.Of peers) are the metrics being displayed from Validator details.
- CPU usage, RAM Usage, Memory usage and information about disk usage are the metrics being displayed from System details.

## How to import these dashboards in your Grafana installation

### 1. Login to your Grafana dashboard
- Open your web browser and go to http://<your_ip>:3000/. `3000` is the default HTTP port that Grafana listens to if you haven’t configured a different port.
- If you are a first time user type `admin` for the username and password in the login page.
- You can change the password after login.

### 2. Create Datasources

- Before importing the dashboards you have to create datasources of InfluxDBTelegraf and InfluxDBVCF.
- To create datasoruces go to configuration and select Data Sources.
- After that you can find Add data source, select InfluxDB from Time series databases section.
- Then to create `InfluxDBVCF` Datasource, follow these configurations. In place of name give InfluxDBVCF, in place of URL give url of influxdb where it is running (ex : http://ip_address:8086). Finaly in InfluxDB Details section give Database name as vcf (If you haven't created a database with different name). You can give User and Password of influx if you have set anthing, otherwise you can leave it empty.
- After this configuration click on Save & Test. Now you have a working Datasource of InfluxDBVCF.

- Repeat same steps to create `InfluxDBTelegraf` Datasource. In place of name give InfluxDBTelegraf, give URL of telegraf where it is running (ex: http://ip_address:8086). Give Database name as telegraf, user and password (If you have configured any). 

- After this configuration click on Save & Test. Now you have a working Datasource of InfluxDBTelegraf.

### 3. Import the dashboards
- To import the json file of the **validator monitoring metrics** click the *plus* button present on left hand side of the dashboard. Click on import and load the validator_monitoring_metrics.json present in the grafana_template folder. 

- Select the datasources and click on import.

- To import **system monitoring metrics** click the *plus* button present on left hand side of the dashboard. Click on import and load the system_monitoring_metrics.json present in the grafana_template folder.

- While creating this dashboard if you face any issues at valueset, change it to empty and then click on import by selecting the datasources.

- To import **summary**, click the *plus* button present on left hand side of the dashboard. Click on import and load the summary.json present in the grafana_template folder.

- *For more info about grafana dashboard imports you can refer https://grafana.com/docs/grafana/latest/reference/export_import/*


## Alerting (Telegram and Email)
 A custom alerting module has been developed to alert on key validator health events. The module uses data from influxdb and trigger alerts based on user-configured thresholds.

 - Alert about validator node sync status.
 - Alert when missed blocks when the missed blocks count reaches or exceedes **missed_blocks_threshold** which is user configured in *config.toml*.
 - Alert when no.of peers count falls below of **num_peers_threshold** which is user configured in *config.toml*
- Alert when the block difference between network and validator reaches or exceeds the **block_diff_threshold** which is user configured in *config.toml*.
- Alert when the gaiad status is not running on validator instance.
- Alert when a new proposal is created.
- Alert when the proposal is moved to voting period, passed or rejected.
- Alert when voting period proposals are due in less than 24 hours, if the validator didn't vote on proposal yet.
- Alert about validator health, i.e. whether it's voting or jailed. You can get alerts twice a day based on the time you have configured **alert_time1** and **alert_time2** in *config.toml*. This is a useful sanity check, to confirm the validator is voting (or alerting you if it's jailed).
- Alert when the voting power of your validator drops below **voting_power_threshold** which is user configured in *config.toml*


## Hosting Validator Mission Control on separate monitoring node

This monitoring tool can also be hosted on any separate monitoring node/public sentry node of the validator.

 - Prerequisites and setup for a sentry node installation remains the same with 1 exception. Telegraf should be installed on the validator instance instead of sentry node. Telegraf collects all the hardware matrics like CPU load, RAM usage etc and posts it to InfluxDB. In this configuration, InfluxDB is installed on monitoring node. 
 - While importing and setting up the dashboards for Grafana, the url has to be changed for InfluxDBTelegraf datasource to point to the validator node telegraf url.
 - As mentioned above, the default port on which Telegraf points the data is 8086, so the url should be replaced as "http://validator-ip:8086"
 - This will allow Grafana to display system metrics of the validator instance instead of displaying metrics of the node where Grafana is installed.
 - All other metrics can be collected from monitoring node itself. The monitoring node should have access to the validator RPC and LCD endpoints. Configure your validator firewall to allow the monitoring node to access these endpoints.
 

## Feedback and Questions

Please feel free to create issues in this repo to ask questions and/or suggest additional metrics, alerts or features.
