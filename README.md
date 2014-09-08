Scripts to set up a hadoop cluster with mutiple work nodes on a single machine using Linux container and hadoop. 

Requirements:
1 Must download hadoop bin.tar.gz and jdk tar.gz and copy them into the same directorywhere your scripts stay. 

jdk download site: http://www.oracle.com/technetwork/java/javase/downloads/index.html 

hadoop download site: http://ftp.twaren.net/Unix/Web/apache/hadoop/common/

2 Must have expect: sudo apt-get install expect

we test this script under hadoop-1.2.1-bin.tar.gz and jdk-8u11-linux-x64.tar.gz and ubuntu 14.04. 

To set up a hadoop cluster with number of work nodes, as type in the command below. Don't forget sudo. 

Usage:

sudo multiNode.bash name of (hadoop.bin.tar.gz) (name of jdk.tar.gz) (number of work nodes)

This script will name the name node as nn, secondary name node as sn, work nodes as dn01, ..., dn0n. 

PITFALL: ssh under expect may fail to log into name node from time to time. If it happens, do not kill the script

with ctrl+c immediately. Instead, let it finish on its own and re-run the script. 


