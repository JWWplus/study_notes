---
title: 第二章 关于MapReduce
tags:  Hadoop
notebook: Hadoop
---
# 第二章 关于MapReduce

> from hadoop 权威指南

------
### 利用unix工具来分析数据

几个常用的Linux命令参考链接[awk](http://www.cnblogs.com/ggjucheng/archive/2013/01/13/2858470.html), [grep](http://www.cnblogs.com/ggjucheng/archive/2013/01/13/2856896.html), [sed](http://www.cnblogs.com/ggjucheng/archive/2013/01/13/2856901.html)
在文本处理中这几个命令很**重要!**

气象数据的unix分析,[实验数据](https://pan.baidu.com/s/1hs3IfjA)

``` sh
#! /usr/bin/env bash
for year in ~/hadoop_data/*
do
    echo -ne `basename $year` "\n"
    for files in $year/*
    do
        echo $files
        awk '{
            temp = substr($0,88,5) + 0;
            q = substr($0,93,1);
            if ( temp != 9999 && q ~ /[01459]/ && temp > max)
                max = temp;
        }
        END { print max }' $files
    done
done
```

-----
## 使用Hadoop MR操作

关于Map/Reduce的本质