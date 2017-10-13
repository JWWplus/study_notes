---
title: flume_to_sparkstreaming
tags: 
notebook: spark
---

[TOC]

# 从flume接入数据到SparkStreaming

## 官方文档

[link](https://spark.apache.org/docs/1.6.3/streaming-flume-integration.html)

## flume 配置文件

``` conf
agent.sources = logfile
agent.channels = logger_memChannel Sparkstraeming_Channel
agent.sinks = log Sparkstraeming

agent.sources.logfile.type=TAILDIR
agent.sources.logfile.positionFile = /home/jiangweiwei/Dow/log_dir/taildir_position.json
agent.sources.logfile.filegroups = t
agent.sources.logfile.filegroups.t = /home/jiangweiwei/Dow/log_dir/Flume_data.csv
agent.sources.logfile.channels = logger_memChannel Sparkstraeming_Channel

agent.channels.logger_memChannel.type=memory
agent.channels.logger_memChannel.capacity = 1000
agent.channels.logger_memChannel.transactionCapacity = 100

agent.channels.Sparkstraeming_Channel.type=memory
agent.channels.Sparkstraeming_Channel.capacity = 10000
agent.channels.Sparkstraeming_Channel.transactionCapacity = 1000

agent.sinks.log.type=logger
agent.sinks.log.channel=logger_memChannel


agent.sinks.Sparkstraeming.type = org.apache.spark.streaming.flume.sink.SparkSink
agent.sinks.Sparkstraeming.hostname = 127.0.0.1
agent.sinks.Sparkstraeming.port = 23456
agent.sinks.Sparkstraeming.channel = Sparkstraeming_Channel
```

这里使用的是官方文档中的pull模式更可靠(在event完全被sparkstreaming消费之前一直存储在 sink中)

## 配置中的坑:

报错

> 1,java.lang.IllegalStateException: begin() called when transaction is OPEN!
解决方法:
flume中多出来的scala-library版本,删除非当前的
>2 org.apache.flume.ChannelException: Take list for MemoryTransaction, capacity 100 full, consider committing more frequently, increasing capacity, or increasing thread count
原因以及解决办法:
因为在event在完全被消费之前一直存在sink中,如果spark设置的时间间隔比较大,而events写入的速度比较大的话很容易造成溢出,解决办法是适合合理的间隔时间同时将agent.channels.Sparkstraeming_Channel.transactionCapacity = 1000调大

## 编写spark作业需要注意的:

从flume发来的数据不同与scoketstream,是一个个的avroevents,所以在flatmap/map等算子中不能直接进行字符串算子的操作.

转换方法

``` scala
val sparkConf = new SparkConf().setMaster("local[2]").setAppName("NetworkWordCount")
val sparkStreamingContext = new StreamingContext(sparkConf,Seconds(microBatchTime))

val stream = FlumeUtils.createPollingStream(sparkStreamingContext,hostName,port)
//   val lines = FlumeUtils.createStream(sparkStreamingContext,hostName,port)  直接push用这个

val mappedlines = stream.map{ sparkFlumeEvent =>
    val event = sparkFlumeEvent.event
    println("Value of event " + event)
    println("Value of event Header " + event.getHeaders)
    println("Value of event Schema " + event.getSchema)
    val messageBody = new String(event.getBody.array())
    println("Value of event Body " + messageBody)
    messageBody
}.print()  // 先转换成string在操作
```

