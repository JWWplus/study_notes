---
title: spark persistence
tags: spark
notebook: spark
---

[TOC]

# 讲Spark数据持久化到外部系统中

## 从kafka中接收数据

tips:一个consumer可以消费多个topic

### 基于Receiver接收数据

这种方式利用接收器（Receiver）来接收kafka中的数据，其最基本是使用Kafka高阶用户API接口。对于所有的接收器，从kafka接收来的数据会存储在spark的executor中，之后spark streaming提交的job会处理这些数据。如下图：

![pic1](http://images2015.cnblogs.com/blog/524764/201612/524764-20161214185141370-645283644.png)

在使用时，我们需要添加相应的依赖包：

``` xml
<dependency><!-- Spark Streaming Kafka -->
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-streaming-kafka_2.10</artifactId>
    <version>1.6.3</version>
</dependency>
```

scala 使用基本方式:

``` scala
import org.apache.spark.streaming.kafka._

 val kafkaStream = KafkaUtils.createStream(streamingContext,
     [ZK quorum], [consumer group id], [per-topic number of Kafka partitions to consume])

```

需要注意的点:

1. 在Receiver的方式中，Spark中的partition和kafka中的partition并不是相关的，所以如果我们加大每个topic的partition数量，仅仅是增加线程来处理由单一Receiver消费的主题。但是这并没有增加Spark在处理数据上的并行度。 *看api理解*
1. 对于不同的Group和topic我们可以使用多个Receiver创建不同的Dstream来并行接收数据，之后可以利用union来统一成一个Dstream。
1. 如果我们启用了Write Ahead Logs复制到文件系统如HDFS，那么`storage level`需要设置成 `StorageLevel.MEMORY_AND_DISK_SER`，也就是`KafkaUtils.createStream(...,StorageLevel.MEMORY_AND_DISK_SER)`

### 直接读取的方式

``` scala

``` 
## 在使用`foreachRDD`的注意点

1. 示例代码

``` scala
dstream.foreachRDD { rdd =>
  val connection = createNewConnection()  // executed at the driver
  rdd.foreach { record =>
    connection.send(record) // executed at the worker
  }
}
```

上述代码存在的问题: 外部存储的连接对象是在driver上建立的,但是foreach操作是在worker节点上,因此连接对象会有一个序列化和反序列化的过程,这里一般会在worker上报错!

2. 改进版本 V1.0

``` scala
dstream.foreachRDD { rdd =>
  rdd.foreach { record =>
    val connection = createNewConnection()
    connection.send(record)
    connection.close()
  }
}
```

上述代码虽然可以跑通,但为rdd中的每一行数据都新建一个连接,很容易超出对应连接池的最大连接数而报错.

3. 正确的写法

``` scala
dstream.foreachRDD { rdd =>
  rdd.foreachPartition { partitionOfRecords =>
    val connection = createNewConnection()
    partitionOfRecords.foreach(record => connection.send(record))
    connection.close()
  }
}
```

在每个partition上建立连接,一个partition上的数据共用一个

