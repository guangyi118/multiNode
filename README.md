Scripts to set up a hadoop cluster with mutiple work nodes on a single machine using Linux container and hadoop. 


1 Requirements: 

    a. Must download hadoop bin.tar.gz and jdk tar.gz and copy them into the same directory where your scripts stay. 

    jdk download site: http://www.oracle.com/technetwork/java/javase/downloads/index.html 

    hadoop download site: http://ftp.twaren.net/Unix/Web/apache/hadoop/common/

    b. Must have expect: sudo apt-get install expect

    we test this script under hadoop-1.2.1-bin.tar.gz, jdk-8u11-linux-x64.tar.gz and ubuntu 14.04. 

2 chmod 755 multinode.bash, chmod 755 nn_configuration.expect

3 Usage: 

To set up a hadoop cluster with number of work nodes, just type in the command below. Don't forget sudo. 

sudo multiNode.bash (name of hadoop.bin.tar.gz) (name of jdk.tar.gz) (number of work nodes) 

This script will name the name node as nn, secondary name node as sn, work nodes as dn01, ..., dn0n. 

4 Start hadoop cluster and run mapreduce program

    a. the hadoop installation directory is under /opt/hadoop

    b. format hdfs system: hadoop namenode -format           you only need to do this for one time  

    c. start-all.sh

    d. check hdfs system: hadoop dfsadmin -report

    e. create a folder: hadoop dfs -mkdir input

    f. create a txt file copy it into input

    g. check current hadoop directory: hadoop dfs ls

    h. run mapreduce wordcount example: hadoop jar /opt/hadoop/hadoop-$version-example.jar wordcount input output       

    note: you need to create the input directory in hdfs and copy the txt input into the directory, you don't have to create output dir since it will be created automatically. Check result of execution under output dir. 
    
    You can also check the result under hadoop/logs

5 Note: 

remember to exit from namenode when you are done with your job. It is a good habit.  

lxc is a memory consuming application. Creating one node will take about 1 GB memory. Do not create too many nodes that your machine cannot handle.

This script is not compatible with hadoop version greater than or equal to 2.2. 
    
    
6 PITFALL:

ssh under expect may fail to log into name node from time to time. If it happens, do not kill the script with ctrl+c immediately. 

Instead, let it finish on its own and re-run the script.

sometimes lxc command such (lxc-create, lxc-start, lxc-stop) can fail. In this case, try delete that node with lxc-destroy first.

If it doesn't work, delete lxc container directory directly using the command below

(sudo rm -rf /var/lib/lxc/nn, nn gives a name of node, to check node name under lxc, use sudo ls /var/lib/lxc) 

If you still cannot delete this directory, restart the machine and redo it.


