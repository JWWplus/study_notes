---
title: map 和 flatmap区别
tags: spark map flatMap
notebook: spark
---

[TOC]

## spark中Map/flatmap区别

1. flatMap返回的是迭代器中的元素。

    ![例子](http://upload-images.jianshu.io/upload_images/617881-d20aa6341827949d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

    flatmap中的函数返回的必须是一个可迭代对象，返回int 会出错

2. map和flatMap接收返回值为可迭代类型的函数的区别
    ![例子2](http://upload-images.jianshu.io/upload_images/617881-09a2dcb611b698d5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

    
## 上例说明对于返回可迭代类型的函数map与flatMap的区别在于：

map函数会对每一条输入进行指定的操作，然后为每一条输入返回一个对象；而flatMap函数则是两个操作的集合——正是“先映射后扁平化”：

- 同map函数一样：对每一条输入进行指定的操作，然后为每一条输入返回一个对象

- 最后将所有对象合并为一个对象
