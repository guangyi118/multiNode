#!/bin/bash
UBUNTU='ubuntu'
NN='nn'
SN='sn'
OFFSET=10
DATA_NODE_NUMBER=$3

# -d check if the temp directory exists. 
if [ -d temp ] 
then
	echo "delete old directory, generate new empty installation directory."
	sudo rm -rf temp
	mkdir temp
else
	echo "generate new empty installation directory."
	sudo mkdir temp
fi
tar zxf $1 -C temp/
tar zxf $2 -C temp/
#note: when define a variable in bash, don't left space around the "=" operator. 
# command between backticks will be first executed. the result of the command will then replace it.  
user=`ls -l temp|grep jdk|awk '{print $3}'` 
if [ "$user" != 'root' ]
then
	echo "Change user and group for jdk to root"
	 chown -R root.root temp/jdk*	
fi

# Check if lxc is installed. Else install.
if [ -f /usr/bin/lxc-create ]
then
	echo "LXC is installed"
else
	echo "LXC is not installed..installing"
#no expect handling here
	 apt-get install lxc
fi

# destroy all previously installed nodes
for f in `ls /var/lib/lxc` 
do
	lxc-stop -n $f
	lxc-destroy -n $f
	echo "Node $f is destroyed."
done

#create name node
lxc-create -t $UBUNTU -n $NN
cp -r temp/hadoop*  /var/lib/lxc/$NN/rootfs/opt/hadoop
cp -r temp/jdk*  /var/lib/lxc/$NN/rootfs/opt/jdk
echo 'export JAVA_HOME=/opt/jdk' >> /var/lib/lxc/$NN/rootfs/etc/profile
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /var/lib/lxc/$NN/rootfs/etc/profile
echo 'export PATH=$PATH:/opt/hadoop/bin' >> /var/lib/lxc/$NN/rootfs/etc/profile
# ^ is location operator to indicate the beginning of line. 
sed -i 's/^exec/#exec/' /var/lib/lxc/$NN/rootfs/etc/init/tty1.conf
echo 'exec /bin/login -f ubuntu < /dev/tty1 > /dev/tty1 2>&1' >> /var/lib/lxc/$NN/rootfs/etc/init/tty1.conf

#start namenode container
lxc-start -d -n $NN
sleep 30

#Get ip address of base container
#http://sunsite.ualberta.ca/Documentation/Gnu/gawk-3.1.0/html_chapter/gawk_8.html#SEC115

ip=`awk -v pattern="$NN" '$0 ~ pattern { print $3 }' /var/lib/misc/dnsmasq.lxcbr0.leases`
if test -z "$ip"
then
	echo "Failed to get ip address. Run script again. If it doesnt work restart lxc-net."
	exit
fi

#nn_configuration.expect is used to set up automatic log-in. 
./nn_configuration.expect ${ip} ${DATA_NODE_NUMBER}


lxc-stop -n $NN
#configure masters and slaves file for name node
sed -i 's/^localhost/#localhost/' /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/masters
echo 'sn' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/masters
sed -i 's/^localhost/#localhost/'  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/slaves
for ((i=1; i<=$DATA_NODE_NUMBER; i++)) 
do
	echo "dn0$i" >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/slaves
done
#configure core-site.xml
sed -i '6d'  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
sed -i '6d'  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
sed -i '6d'  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '<configuration>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '<property>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '<name>fs.default.name</name>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '<value>hdfs://nn:9000</value>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '</property>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '<property>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '<name>hadoop.tmp.dir</name>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '<value>/home/ubuntu/data</value>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '</property>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
echo '</configuration>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/core-site.xml
#configure hdfs-site.xml
sed -i '6d'  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
sed -i '6d'  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
sed -i '6d'  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '<configuration>' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '<property>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '<name>dfs.http.address</name>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '<value>nn:50070</value>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '</property>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '<property>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '<name>dfs.secondary.http.address</name>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '<value>sn:50090</value>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '</property>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '<property>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '<name>dfs.replication</name>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo "<value>$DATA_NODE_NUMBER</value>" >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '</property>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
echo '</configuration>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hdfs-site.xml
#configure mapred-site.xml
sed -i '6d' /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/mapred-site.xml
sed -i '6d' /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/mapred-site.xml
sed -i '6d' /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/mapred-site.xml
echo '<configuration>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/mapred-site.xml
echo '<property>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/mapred-site.xml
echo '<name>mapred.job.tracker</name>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/mapred-site.xml
echo '<value>nn:9001</value>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/mapred-site.xml
echo '</property>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/mapred-site.xml
echo '</configuration>' >> /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/mapred-site.xml
#configure hadoop-env.sh
echo 'export JAVA_HOME=/opt/jdk' >>  /var/lib/lxc/$NN/rootfs/opt/hadoop/conf/hadoop-env.sh

#use name node to clone secondary name node and data nodes
lxc-clone -o $NN -n $SN
for ((i=1; i<=$DATA_NODE_NUMBER; i++))
do
	DN="dn0$i" 
	lxc-clone -o $NN -n $DN
done
# configure ip addresses of each node in hosts files.
sed -i "/$NN/d" /var/lib/lxc/$NN/rootfs/etc/hosts
echo "10.0.3.$OFFSET $NN" >> /var/lib/lxc/$NN/rootfs/etc/hosts
OFFSET=$((OFFSET+1)) 
echo "10.0.3.$OFFSET $SN" >> /var/lib/lxc/$NN/rootfs/etc/hosts

OFFSET=$((OFFSET+1)) 
for ((i=1; i<=$DATA_NODE_NUMBER; i++))
do
	DN="dn0$i" 
	echo "10.0.3.$OFFSET $DN" >> /var/lib/lxc/$NN/rootfs/etc/hosts
	OFFSET=$((OFFSET+1)) 
done

cp /var/lib/lxc/$NN/rootfs/etc/hosts /var/lib/lxc/$SN/rootfs/etc/hosts

for ((i=1; i<=$DATA_NODE_NUMBER; i++))
do
	DN="dn0$i" 
	cp /var/lib/lxc/$NN/rootfs/etc/hosts /var/lib/lxc/$DN/rootfs/etc/hosts
done
#set up interfaces file for each nodes. 
OFFSET=10
sed -i 's/^iface eth0 inet dhcp/iface eth0 inet static/' /var/lib/lxc/$NN/rootfs/etc/network/interfaces
echo "address 10.0.3.$OFFSET" >> /var/lib/lxc/$NN/rootfs/etc/network/interfaces
echo "netmask 255.255.255.0" >> /var/lib/lxc/$NN/rootfs/etc/network/interfaces
echo "gateway 10.0.3.1" >> /var/lib/lxc/$NN/rootfs/etc/network/interfaces
echo "dns-nameservers 168.95.1.1" >> /var/lib/lxc/$NN/rootfs/etc/network/interfaces

OFFSET=$((OFFSET+1)) 
sed -i 's/^iface eth0 inet dhcp/iface eth0 inet static/' /var/lib/lxc/$SN/rootfs/etc/network/interfaces
echo "address 10.0.3.$OFFSET" >> /var/lib/lxc/$SN/rootfs/etc/network/interfaces
echo "netmask 255.255.255.0" >> /var/lib/lxc/$SN/rootfs/etc/network/interfaces
echo "gateway 10.0.3.1" >> /var/lib/lxc/$SN/rootfs/etc/network/interfaces
echo "dns-nameservers 168.95.1.1" >> /var/lib/lxc/$SN/rootfs/etc/network/interfaces

for ((i=1; i<=$DATA_NODE_NUMBER; i++))
do
	DN="dn0$i" 
	OFFSET=$((OFFSET+1)) 
	sed -i 's/^iface eth0 inet dhcp/iface eth0 inet static/' /var/lib/lxc/$DN/rootfs/etc/network/interfaces
	echo "address 10.0.3.$OFFSET" >> /var/lib/lxc/$DN/rootfs/etc/network/interfaces
	echo "netmask 255.255.255.0" >> /var/lib/lxc/$DN/rootfs/etc/network/interfaces
	echo "gateway 10.0.3.1" >> /var/lib/lxc/$DN/rootfs/etc/network/interfaces
	echo "dns-nameservers 168.95.1.1" >> /var/lib/lxc/$DN/rootfs/etc/network/interfaces
done
#start all the nodes. 
lxc-start -n $NN -d
lxc-start -n $SN -d
for ((i=1; i<=$DATA_NODE_NUMBER; i++))
do
	DN="dn0$i"
	lxc-start -n $DN -d
done
rm -rf temp
echo 'The entire deployment has completed.'

