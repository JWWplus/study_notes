---
title: spark计算流程
tags: spark
notebook: spark
---

[TOC]

## 基本运行流程
Spark应用程序有多种运行模式。SparkContext和Executor这两部分的核心代码实现在各种运行模式中都是公用的，在这两部分之上，根据运行部署模式（例如：Local[N]、Yarn cluster等）的不同，有不同的调度模块以及对应的适配代码。

![pic](http://images.cnblogs.com/cnblogs_com/BYRans/761498/o_sparkArchitecture.png)

具体来说，以SparkContext为程序运行的总入口，在SparkContext的初始化过程中，Spark会分别创建DAGScheduler作业和TaskScheduler任务调度两级调度模块。

其中作业调度模块是基于任务阶段的高层调度模块，它为每个Spark作业计算具有依赖关系的多个调度阶段（通常根据shuffle来划分），然后为每个阶段构建出一组具体的任务（通常会考虑数据的本地性等），然后以TaskSets（任务组）的形式提交给任务调度模块来具体执行。而任务调度模块则负责具体启动任务、监控和汇报任务运行情况。

## 详细的运行流程为：

1. 构建Spark Application的运行环境（启动SparkContext），SparkContext向资源管理器（可以是Standalone、Mesos或YARN）注册并申请运行Executor资源；

1. 资源管理器分配Executor资源并启动StandaloneExecutorBackend，Executor运行情况将随着心跳发送到资源管理器上；

1. SparkContext构建成DAG图，将DAG图分解成Stage，并把Taskset发送给Task Scheduler。Executor向SparkContext申请Task，Task Scheduler将Task发放给Executor运行同时SparkContext将应用程序代码发放给Executor。

1. Task在Executor上运行，运行完毕释放所有资源。

![pic2](http://images.cnblogs.com/cnblogs_com/BYRans/761498/o_sparkProcessDetail.png)

作业调度模块和具体的部署运行模式无关，在各种运行模式下逻辑相同。**不同运行模式的区别主要体现在任务调度模块**。不同的部署和运行模式，根据底层资源调度方式的不同，各自实现了自己特定的任务调度模块，用来将任务实际调度给对应的计算资源。接下来重点介绍下YARN cluster模式的实现原理和实现细节。