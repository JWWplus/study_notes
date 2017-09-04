---
title: spark shuffle
tags: spark
notebook: spark
---

[TOC]

# spark shufffle

## spark任务生成

在Spark中，RDD是操作对象的单位，其中操作可以分为转换(transformation)和动作(actions),只有动作操作才会触发一个spark计算操作。

1. 每次有一个action算子会触发一个job

1. job可能会生成多个stage

1. 一个rdd有多少个partition就会生成多少个task，partition是spark跑任务的最小单位。

------

## Job，Stage，Task, Dependency

Job是由一组RDD上转换和动作组成，这组RDD之间的转换关系表现为一个有向无环图(DAG)，每个RDD的生成依赖于前面1个或多个RDD。
在Spark中，两个RDD之间的依赖关系是Spark的核心。站在RDD的角度，两者依赖表现为点对点依赖， 但是在Spark中，RDD存在分区（partition）的概念，两个RDD之间的转换会被细化为两个RDD分区之间的转换。
![pic](https://github.com/ColZer/DigAndBuried/blob/master/image/job.jpg?raw=true)

## spark 中的shuffle

与MapReduce计算框架一样，Spark的Shuffle实现大致如下图所示，在DAG阶段以shuffle为界，划分stage，上游stage做map task，每个map task将计算结果数据分成多份，每一份对应到下游stage的每个partition中，并将其临时写到磁盘，该过程叫做shuffle write；下游stage做reduce task，每个reduce task通过网络拉取上游stage中所有map task的指定分区结果数据，该过程叫做shuffle read，最后完成reduce的业务逻辑。举个栗子，假如上游stage有100个map task，下游stage有1000个reduce task，那么这100个map task中每个map task都会得到1000份数据，而1000个reduce task中的每个reduce task都会拉取上游100个map task对应的那份数据，即第一个reduce task会拉取所有map task结果数据的第一份，以此类推。

![pic1](http://sharkdtu.com/images/spark-shuffle-overview.png)

### 版本演进

Spark在1.1以前的版本一直是采用Hash Shuffle的实现的方式，到1.1版本时参考Hadoop MapReduce的实现开始引入Sort Shuffle，在1.5版本时开始Tungsten钨丝计划，引入UnSafe Shuffle优化内存及CPU的使用，在1.6中将Tungsten统一到Sort Shuffle中，实现自我感知选择最佳Shuffle方式，到最近的2.0版本，Hash Shuffle已被删除，所有Shuffle方式全部统一到Sort Shuffle一个实现中。下图是spark shuffle实现的一个版本演进。

![pic2](http://sharkdtu.com/images/spark-shuffle-evolution.png)

[各个版本介绍](http://sharkdtu.com/posts/spark-shuffle.html)


### shuffle的两个阶段

对于Spark来讲，一些Transformation或Action算子会让RDD产生宽依赖，即parent RDD中的每个Partition被child RDD中的多个Partition使用，这时便需要进行Shuffle，根据Record的key对parent RDD进行重新分区。如果对这些概念还有一些疑问，可以参考我的另一篇文章《Spark基本概念快速入门》。

以Shuffle为边界，Spark将一个Job划分为不同的Stage，这些Stage构成了一个大粒度的DAG。Spark的Shuffle分为Write和Read两个阶段，分属于两个不同的Stage，前者是Parent Stage的最后一步，后者是Child Stage的第一步。如下图所示:

![pic](http://upload-images.jianshu.io/upload_images/35301-05f2e70588800a10.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

执行Shuffle的主体是Stage中的并发任务，这些任务分ShuffleMapTask和ResultTask两种，ShuffleMapTask要进行Shuffle，ResultTask负责返回计算结果，一个Job中只有最后的Stage采用ResultTask，其他的均为ShuffleMapTask。如果要按照map端和reduce端来分析的话，ShuffleMapTask可以即是map端任务，又是reduce端任务，因为Spark中的Shuffle是可以串行的；ResultTask则只能充当reduce端任务的角色。

我把Spark Shuffle的流程简单抽象为以下几步以便于理解：

- Shuffle Write
1. Map side combine (if needed)
1. Write to local output file

- Shuffle Read
1. Block fetch
1. Reduce side combine
1. Sort (if needed) 1.2版本后默认排序

Write阶段发生于ShuffleMapTask对该Stage的最后一个RDD完成了map端的计算之后，首先会判断是否需要对计算结果进行聚合，然后将最终结果按照不同的reduce端进行区分，写入当前节点的本地磁盘。
Read阶段开始于reduce端的任务读取ShuffledRDD之时，首先通过远程或本地数据拉取获得Write阶段各个节点中属于当前任务的数据，根据数据的Key进行聚合，然后判断是否需要排序，最后生成新的RDD。


## spark cache 和persist区别

这2种方法都是数据缓存的方式，只是cache是缓存在内存中，而persist则提供了多种缓存方式，存内存，存磁盘，存内存+磁盘。

## Spark Rdd coalesce()方法和repartition()方法

他们两个都是RDD的分区进行重新划分，repartition只是coalesce接口中shuffle为true的简易实现，（假设RDD有N个分区，需要重新划分成M个分区） 
1）N < M。一般情况下N个分区有数据分布不均匀的状况，利用HashPartitioner函数将数据重新分区为M个，这时需要将shuffle设置为true。 
2）如果N > M并且N和M相差不多，(假如N是1000，M是100)那么就可以将N个分区中的若干个分区合并成一个新的分区，最终合并为M个分区，这时可以将shuff设置为false，在shuffl为false的情况下，如果M>N时，coalesce为无效的，不进行shuffle过程，父RDD和子RDD之间是窄依赖关系。 
3）如果N > M并且两者相差悬殊，这时如果将shuffle设置为false，父子RDD是窄依赖关系，他们同处在一个stage中，就可能造成Spark程序的并行度不够，从而影响性能，如果在M为1的时候，为了使coalesce之前的操作有更好的并行度，可以讲shuffle设置为true。

_//如果重分区的数目大于原来的分区数，那么必须指定shuffle参数为true，//否则，分区数不便_

