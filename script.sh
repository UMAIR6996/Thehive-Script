#!/bin/bash

#Install TheHive 
sudo apt-get install -y curl 

#Install JVM 
sudo apt-get install -y openjdk-8-jre-headless 
sudo -c 'echo JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/environment' 
sudo export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" 

#Install Cassandra 
echo "deb https://debian.cassandra.apache.org 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list 
sudo deb https://debian.cassandra.apache.org 311x main 
curl https://downloads.apache.org/cassandra/KEYS | sudo apt-key add - 
sudo apt-get update 
sudo apt-get install -y cassandra 

#Configure Cassandra 
cqlsh localhost 9042 -e "UPDATE system.local SET cluster_name = 'thp' where key='local';" 
nodetool flush 
sudo cp /etc/cassandra/cassandra.yaml /etc/cassandra/cassandra.yaml.bak 
sudo sed -i "s|cluster_name: 'Test Cluster'|cluster_name: 'thp'|g" /etc/cassandra/cassandra.yaml 
sudo systemctl restart cassandra 

#Install TheHive4 
#Create Lucene folder for indexes 
sudo mkdir -p /opt/thp/thehive/index 
sudo chown thehive:thehive -R /opt/thp/thehive/index 

#File Storage 
sudo mkdir -p /opt/thp/thehive/files 
sudo chown -R thehive:thehive /opt/thp/thehive/files 

#theHive 
curl https://raw.githubusercontent.com/TheHive-Project/TheHive/master/PGP-PUBLIC-KEY | sudo apt-key add - 
echo 'deb https://deb.thehive-project.org release main' | sudo tee -a /etc/apt/sources.list.d/thehive-project.list 
sudo apt-get update 
sudo apt-get install thehive4 

#configure theHive 
thehive_ip=127.0.0.1 
cluster_name=thp 
local_datacenter=datacenter1 
sudo cp /etc/thehive/application.conf /etc/thehive/application.conf.bak 
sudo sed -i 's+// backend: cql+backend: cql+g' /etc/thehive/application.conf 
sudo sed -i "0,/\/\/ hostname: \[\"ip1\", \"ip2\"\]/s//hostname: [\"$thehive_ip\"]/g" /etc/thehive/application.conf 
sudo sed -i '0,/\ \ \ \ \ \ cluster-name: thp/s///g' /etc/thehive/application.conf 
sudo sed -i '0,/\ \ \ \ \ \ keyspace: thehive/s///g' /etc/thehive/application.conf 
sudo sed -i "/cql {/a \ \ \ \ \ \ cluster-name: $cluster_name\n\ \ \ \ \ \ keyspace: thehive\n\ \ \ \ \ \ local-datacenter: $local_datacenter\n\ \ \ \ \ \ read-consistency-level: ONE\n\ \ \ \ \ \ write-consistency-level: ONE" /etc/thehive/application.conf 
sudo sed -i 's|// provider: localfs|provider: localfs|g' /etc/thehive/application.conf 
sudo sed -i 's|// localfs.location: .*|localfs.location: /opt/thp/thehive/files|' /etc/thehive/application.conf 
sudo systemctl restart thehive 

#Login/Password : admin@thehive.local:secret 
 
sleep 60

curl -XPOST -u admin@thehive.local:secret -H 'Content-Type: application/json' http://127.0.0.1:9000/api/v0/organisation -d '{
   "description": "SOC tesm",
   "name": "SOC"
}'

curl  -XPOST -u admin@thehive.local:secret -H 'Content-Type: application/json' http://127.0.0.1:9000/api/v1/user -d '{
   "login" : "demouser@thehive",
   "name" : "demouser",
   "organisation" : "SOC",
   "profile" : "org-admin",
   "email" : "demouser@thehive",
   "password" : "demouser"
}'

curl -XPOST -u admin@thehive.local:secret -H 'Content-Type: application/json' http://127.0.0.1:9000/api/v1/user/demouser@thehive/key/renew
curl -XPOST -u demouser@thehive:demouser -H 'Content-Type: application/json' http://127.0.0.1:9000/api/alert -d '{
   "title":"sshd: attempt to login using non-existent user",
   "source":"Wazuh",
   "sourceRef":"5710",
   "type":"Wazuh Alert",
   "timestamp":"2023-08-31T09:08:50.994-0400",
   "rule":{
      "level":5,
      "description":"sshd: Attempt to login using a non-existent user",
      "id":"5710",
      "mitre":{
         "id":[
            "T1110.001",
            "T1021.004",
            "T1078"
         ],
         "tactic":[
            "Credential Access",
            "Lateral Movement",
            "Defense Evasion",
            "Persistence",
            "Privilege Escalation",
            "Initial Access"
         ],
         "technique":[
            "Password Guessing",
            "SSH",
            "Valid Accounts"
         ]
      },
      "firedtimes":34,
      "mail":false,
      "groups":[
         "syslog",
         "sshd",
         "authentication_failed",
         "invalid_login"
      ],
      "gdpr":[
         "IV_35.7.d",
         "IV_32.2"
      ],
      "gpg13":[
         "7.1"
      ],
      "hipaa":[
         "164.312.b"
      ],
      "nist_800_53":[
         "AU.14",
         "AC.7",
         "AU.6"
      ],
      "pci_dss":[
         "10.2.4",
         "10.2.5",
         "10.6.1"
      ],
      "tsc":[
         "CC6.1",
         "CC6.8",
         "CC7.2",
         "CC7.3"
      ]
   },
   "agent":{
      "id":"004",
      "name":"demo",
      "ip":"192.168.157.132"
   },
   "manager":{
      "name":"ubun2004"
   },
   "id":"1693487330.862782",
   "full_log":"Aug 31 18:08:50 ubun2004 sshd[6944]: Failed password for invalid user demo from 192.168.157.131 port 58926 ssh2",
   "predecoder":{
      "program_name":"sshd",
      "timestamp":"Aug 31 18:08:50",
      "hostname":"ubun2004"
   },
   "decoder":{
      "parent":"sshd",
      "name":"sshd"
   },
   "data":{
      "srcip":"192.168.157.131",
      "srcuser":"demo"
   },
   "location":"/var/log/auth.log"
}'