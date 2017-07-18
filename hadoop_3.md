---
title: 第三章 关于HDFS
tags:  Hadoop
notebook: Hadoop
---
[TOC]

## hadoop 安装配置
[HDFS参考link](http://www.cnblogs.com/beanmoon/archive/2012/12/11/2809315.html)

[安装教程](http://www.powerxing.com/install-hadoop-in-centos/)

在配置文件时不能使用相对路径，应使用绝对路径。

### 运行单节点参考[官网教程](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html)

### 伪分布式

[参考](http://www.powerxing.com/install-hadoop-in-centos/)

### 分布式环境搭建

**要注意的坑**

#### 设置 hosts

编辑 /etc/hosts文件，master节点上要配置自己和所有的slave的ip 和 hostname， slave建议也全部配置(可以只配自己和master的)。

**坑: 127.0.0.1 只配置localhost即可，千万不要在后面加上master/slave名称，这样做会导致datanode连不上namenode！**

#### master和slave之间免密登录

利用命令生成密钥[^原理]

``` sh
    ssh-keygen -t rsa
    设置本机无密码自己登录
    cat ./id_rsa.pub >> ./authorized_keys
```
在slave上生成密钥并加入master的authorized_keys中，同时将master的也加入slave中

#### 配置hadoop文件

前提是在master上设置好java环境

1. 编辑 hadoop/etc/slave文件
    1. 加入slave的hostname
2. 文件 core-site.xml 改为下面的配置：
    ``` xml
    <configuration>
        <property>
                <name>fs.defaultFS</name>
                <value>hdfs://Master:9000</value>
        </property>
        <property>
                <name>hadoop.tmp.dir</name>
                <value>file:/usr/local/hadoop/tmp</value>
                <description>Abase for other temporary directories.</description>
        </property>
    </configuration>
    ```
3. 文件 hdfs-site.xml，dfs.replication 一般设为 3，但我们只有一个 Slave 节点，所以 dfs.replication 的值还是设为 1：
    ``` xml
    <configuration>
        <property>
                <name>dfs.namenode.secondary.http-address</name>
                <value>Master:50090</value>
        </property>
        <property>
                <name>dfs.replication</name>
                <value>1</value>
        </property>
        <property>
                <name>dfs.namenode.name.dir</name>
                <value>file:/usr/local/hadoop/tmp/dfs/name</value>
        </property>
        <property>
                <name>dfs.datanode.data.dir</name>
                <value>file:/usr/local/hadoop/tmp/dfs/data</value>
        </property>
    </configuration>
    ```
4. 文件 mapred-site.xml （可能需要先重命名，默认文件名为 mapred-site.xml.template），然后配置修改如下：
    ``` xml
    <configuration>
        <property>
                <name>mapreduce.framework.name</name>
                <value>yarn</value>
        </property>
        <property>
                <name>mapreduce.jobhistory.address</name>
                <value>Master:10020</value>
        </property>
        <property>
                <name>mapreduce.jobhistory.webapp.address</name>
                <value>Master:19888</value>
        </property>
    </configuration>
    ```
5. yarn-site.xml：
    ``` xml
    <configuration>
        <property>
                <name>yarn.resourcemanager.hostname</name>
                <value>Master</value>
        </property>
        <property>
                <name>yarn.nodemanager.aux-services</name>
                <value>mapreduce_shuffle</value>
        </property>
    </configuration>
    ```
以上所有变量需要按照实际的安装地址做修改，master改为自己设置的master的hostname

#### 打包hadoop文件利用scp发送到slave

``` sh
    cd /usr/local
    sudo rm -r ./hadoop/tmp     # 删除 Hadoop 临时文件
    sudo rm -r ./hadoop/logs/*   # 删除日志文件
    tar -zcf ~/hadoop.master.tar.gz ./hadoop   # 先压缩再复制
    cd ~
    scp ./hadoop.master.tar.gz Slave1:/home/hadoop
```

#### 运行

1. 首先namenode格式化

``` sh
    hdfs namenode -format       # 首次运行需要执行初始化，之后不需要
```

2. 关闭centos防火墙

``` sh
systemctl stop firewalld.service    # 关闭firewall
systemctl disable firewalld.service # 禁止firewall开机启动
```

3. 在master节点上开启服务
``` sh
start-dfs.sh
start-yarn.sh
mr-jobhistory-daemon.sh start historyserver
```

4. jps查看状态，如果有问题去看对应节点的log

5. 查看master:50070可视化界面，yarn界面master:8088 

[^原理]: Master（NameNode | JobTracker）作为客户端，要实现无密码公钥认证，连接到服务器Salve（DataNode | Tasktracker）上时，需要在Master上生成一个密钥对，包括一个公钥和一个私钥，而后将公钥复制到所有的Slave上。当Master通过SSH连接Salve时，Salve就会生成一个随机数并用Master的公钥对随机数进行加密，并发送给Master。Master收到加密数之后再用私钥解密，并将解密数回传给Slave，Slave确认解密数无误之后就允许Master进行连接了。这就是一个公钥认证过程，其间不需要用户手工输入密码。