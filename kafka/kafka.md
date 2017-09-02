---
title: kafka 总结
tags: kafka
notebook: kafka
---

[TOC]

# kafka

## Topic/Partition

Topic在逻辑上可以被认为是一个queue。每条消费都必须指定它的topic，可以简单理解为必须指明把这条消息放进哪个queue里。为了使得Kafka的吞吐率可以水平扩展，物理上把topic分成一个或多个partition，每个partition在物理上对应一个文件夹，该文件夹下存储这个partition的所有消息和索引文件。

### kafka 如何做到数据持久/以及效率问题

![pic](http://kafka.apache.org/images/log_anatomy.png)

Partition中的每条Message由offset来表示它在这个partition中的偏移量，这个offset不是该Message在partition数据文件中的实际存储位置，而是逻辑上一个值，它唯一确定了partition中的一条Message。因此，可以认为offset是partition中Message的id。partition中的每条Message包含了以下三个属性：

- offset
- MessageSize
- data

我们来思考一下，如果一个partition只有一个数据文件会怎么样？

1. 新数据是添加在文件末尾（调用FileMessageSet的append方法），不论文件数据文件有多大，这个操作永远都是O(1)的。 
1. 查找某个offset的Message（调用FileMessageSet的searchFor方法）是顺序查找的。因此，如果数据文件很大的话，查找的效率就低。

那Kafka是如何解决查找效率的的问题呢？有两大法宝：1) 分段 2) 索引。如下图：

![pic2](http://img.blog.csdn.net/20150121163718558)

**如何查找index文件？**

![pic3](http://img.blog.csdn.net/20150121164203539)

比如：要查找绝对offset为7的Message：

1. 首先是用二分查找确定它是在哪个LogSegment中，自然是在第一个Segment中。
1. 打开这个Segment的index文件，也是用二分查找找到offset小于或者等于指定offset的索引条目中最大的那个offset。自然offset为6的那个索引是我们要找的，通过索引文件我们知道offset为6的Message在数据文件中的位置为9807。
1. 打开数据文件，从位置为9807的那个地方开始顺序扫描直到找到offset为7的那条Message。

索引文件使用的是稀疏索引，这样做可以有效减少索引文件的大小。

### 存储变长message

kafka的数据是变长的，事前并不知道会有多少字节，因此在每个message log的开头都会存储一下信息:

``` text
　　message length ： 4 bytes (value: 1+4+n)
　　“magic” value ： 1 byte
　　crc ： 4 bytes
　　payload ： n bytes
```

最前面4个字节，记录长度；
紧跟着1个字节，版本号；
接下来4个字节，crc校验值；
最后n个字节，消息的实际内容。

### flush 刷磁盘机制
[参考1](http://calvin1978.blogcn.com/articles/kafkaio.html) [参考2](http://blog.csdn.net/chunlongyu/article/details/53784033)

首先明确kafka 会先把数据放入系统内存中，然后在批量刷入磁盘(flush操作)，kafka配置文件可以控制刷入的策略。

刷入的策略参考 参考1！

写message

- 消息从java堆转入page cache(即物理内存)。
- 由异步线程刷盘,消息从page cache刷入磁盘。

读message

- 消息直接从page cache转入socket发送出去。
- 当从page cache没有找到相应数据时，此时会产生磁盘IO,从磁
- 盘Load消息到page cache,然后直接从socket发出去

## Replication & Leader election(副本以及leader选举)

Kafka从0.8开始提供partition级别的replication，replication的数量可在`$KAFKA_HOME/config/server.properties`中配置。

`default.replication.factor = 1`

该 Replication与leader election配合提供了自动的failover机制。replication对Kafka的吞吐率是有一定影响的，但极大的增强了可用性。默认情况下，Kafka的replication数量为1。　　每个partition都有一个唯一的leader，所有的读写操作都在leader上完成，leader批量从leader上pull数据。一般情况下partition的数量大于等于broker的数量，并且所有partition的leader均匀分布在broker上。follower上的日志和其leader上的完全一样。
　　和大部分分布式系统一样，Kakfa处理失败需要明确定义一个broker是否alive。对于Kafka而言，Kafka存活包含两个条件，一是它必须维护与Zookeeper的session(这个通过Zookeeper的heartbeat机制来实现)。二是follower必须能够及时将leader的writing复制过来，不能“落后太多”。
　　leader会track“in sync”的node list。如果一个follower宕机，或者落后太多，leader将把它从”in sync” list中移除。这里所描述的“落后太多”指follower复制的消息落后于leader后的条数超过预定值，该值可在`$KAFKA_HOME/config/server.properties`中配置。

```text
#If a replica falls more than this many messages behind the leader, the leader will remove the follower from ISR and treat it as dead
replica.lag.max.messages=4000
#If a follower hasn't sent any fetch requests for this window of time, the leader will remove the follower from ISR (in-sync replicas) and treat it as dead
replica.lag.time.max.ms=10000
```

### 怎样判断成功提交

Producer在发布消息到某个Partition时，先通过ZooKeeper找到该Partition的Leader，然后无论该Topic的Replication Factor为多少（也即该Partition有多少个Replica），Producer只将该消息发送到该Partition的Leader。Leader会将该消息写入其本地Log。每个Follower都从Leader pull数据。这种方式上，Follower存储的数据顺序与Leader保持一致。Follower在收到该消息并写入其Log后，向Leader发送ACK。一旦Leader收到了ISR中的所有Replica的ACK，该消息就被认为已经commit了，Leader将增加HW并且向Producer发送ACK。

为了提高性能，每个Follower在接收到数据后就立马向Leader发送ACK，而非等到数据写入Log中。因此，对于已经commit的消息，Kafka只能保证它被存于多个Replica的内存中，而不能保证它们被持久化到磁盘中，也就不能完全保证异常发生后该条消息一定能被Consumer消费。但考虑到这种场景非常少见，可以认为这种方式在性能和数据持久化上做了一个比较好的平衡。在将来的版本中，Kafka会考虑提供更高的持久性。

Consumer读消息也是从Leader读取，只有被commit过的消息（offset低于HW的消息）才会暴露给Consumer。

![pic4](http://cdn3.infoqstatic.com/statics_s1_20170829-0315/resource/articles/kafka-analysis-part-2/zh/resources/0416000.png)

## Consumer Group & Rebalance

### 

## 几个面试问到的问题

### kafka是否保证消费时和写入时的顺序一致？

当partition为1时，可以保证，但是当存在多个partition时则不能保证，因为kafka会均匀的将数据写入到不同的partition中，但是在消费的时候每个partition的消费速度是不同的，有可能出现后插入的message被先消费到的情况。

### 同一个topic中offset是唯一的吗？

[可以参考](http://www.jasongj.com/2015/01/02/Kafka%E6%B7%B1%E5%BA%A6%E8%A7%A3%E6%9E%90/)
这个是有可能的存在相同的，首先要明确一点，x写入的每条消息都有一个当前partition下唯一的64字节的offset，它指明了这条消息的起始位置。只能保证这个offset在当前partition下是唯一的。

下图是一个partition中的数据分布图
![pic1](http://www.jasongj.com/img/kafka/KafkaAnalysis/partition_segment.png)

### kafka的丢数据/重复消费问题，以及如何解决

丢失数据的原因：设置offset为自动定时提交，当offset被自动定时提交时，数据还在内存中未处理，此时刚好把线程kill掉，那么offset已经提交，但是数据未处理，导致这部分内存中的数据丢失。

重复消费的原因：设置自己手动提交offset但是程序消费后没提交之前 kill掉了。
