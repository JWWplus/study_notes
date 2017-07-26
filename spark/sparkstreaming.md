---
title: SparkStreaming小结
tags: spark sparkstreaming
notebook: SparkStreaming
---

# Spark Streaming

Spark streaming是Spark核心API的一个扩展，它对实时流式数据的处理具有可扩展性、高吞吐量、可容错性等特点。我们可以从kafka、flume、Twitter、 ZeroMQ、Kinesis等源获取数据，也可以通过由 高阶函数map、reduce、join、window等组成的复杂算法计算出数据。最后，处理后的数据可以推送到文件系统、数据库、实时仪表盘中。事实上，你可以将处理后的数据应用到Spark的机器学习算法、 图处理算法中去。
![pic](https://aiyanbo.gitbooks.io/spark-programming-guide-zh-cn/content/img/streaming-arch.png)
在内部，它的工作原理如下图所示。Spark Streaming接收实时的输入数据流，然后将这些数据切分为批数据供Spark引擎处理，Spark引擎将数据生成最终的结果数据。
![pic2](https://aiyanbo.gitbooks.io/spark-programming-guide-zh-cn/content/img/streaming-flow.png)
Spark Streaming支持一个高层的抽象，叫做离散流(discretized stream)或者DStream，它代表连续的数据流。DStream既可以利用从Kafka, Flume和Kinesis等源获取的输入数据流创建，也可以 在其他DStream的基础上通过高阶函数获得。在内部，DStream是由一系列RDDs组成。

[TOC]

## 一个简单的例子

``` python
    from __future__ import print_function

    import sys

    from pyspark import SparkContext
    from pyspark.streaming import StreamingContext

    if __name__ == "__main__":
        if len(sys.argv) != 3:
            print("Usage: stateful_network_wordcount.py <hostname> <port>", file=sys.stderr)
            exit(-1)
        sc = SparkContext(appName="PythonStreamingStatefulNetworkWordCount")
        ssc = StreamingContext(sc, 1)
        ssc.checkpoint("checkpoint")

        def updateFunc(new_values, last_sum):
            return sum(new_values) + (last_sum or 0)

        lines = ssc.socketTextStream(sys.argv[1], int(sys.argv[2]))
        running_counts = lines.flatMap(lambda line: line.split(" "))\
                            .map(lambda word: (word, 1))\
                            .updateStateByKey(updateFunc)

        running_counts.pprint()

        ssc.start()
        ssc.awaitTermination()
```
分析: 在spark中抽象概念是RDD，在sparkstreaming中的抽象概念是Dstream(离散数据集，本质是有多个rdd组成，因此两者很多函数都适用)

[阅读api](https://spark.apache.org/docs/1.6.1/api/python/pyspark.streaming.html)

以及自带的example
