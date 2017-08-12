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

## soark 中的shuffle

### HashShuffleManger

