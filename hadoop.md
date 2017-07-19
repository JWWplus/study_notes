---
title: 第二章 关于MapReduce
tags:  Hadoop
notebook: Hadoop
---
[TOC]

# 第二章 关于MapReduce

> from hadoop 权威指南

------
## 利用unix工具来分析数据

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

------

## 使用Hadoop MR操作

### 关于Map/Reduce的本质

#### Map

- 可以将map操作理解为从海量文本文件中抽取目标数据

- map的输入是一行一行的文本/数据，这些行以**键值对 key/value**的形式作为map的输入

- key 一般为文件中的偏移量，类似于index(视情况需要而使用)

- 根据处理函数抽取要的数据

#### Reduce

- map的输出会作为reduce函数的输入

- **这个处理过程是基于键来对键值进行排序和分组**
    - example
    ``` text
    map抽取的天气数据
    (1999,21)
    (1999,23)
    (2000,45)
    (2000,33)
    (2002,24)

    reduce 看到的输入
    (1999, [21, 23])
    (2000, [45, 33])
    (2002, [24])
    ```

    - 流程
    ``` sh
    input | map | shuffle | reduce > output
    ```
    - shuffle(洗牌)操作讲key值相同的整合到一起

#### Map函数

``` java
/**
 * Created by jiangweiwei on 17-7-17.
 */
import java.io.IOException;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
 
public class MinTemperatureMapper extends Mapper<LongWritable, Text, Text, IntWritable>{
 
    private static final int MISSING = 9999;
   
    @Override
    public void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
       
        String line = value.toString();
        String year = line.substring(15, 19);
       
        int airTemperature;
        if(line.charAt(87) == '+') {
            airTemperature = Integer.parseInt(line.substring(88, 92));
        } else {
            airTemperature = Integer.parseInt(line.substring(87, 92));
        }
       
        String quality = line.substring(92, 93);
        if(airTemperature != MISSING && quality.matches("[01459]")) {
            context.write(new Text(year), new IntWritable(airTemperature));
        }
    }
}
```

#### reduce

``` java
import java.io.IOException;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

public class MinTemperatureReducer extends Reducer<Text, IntWritable, Text, IntWritable> {

    @Override
    public void reduce(Text key, Iterable<IntWritable> values, Context context) throws IOException, InterruptedException {

        int minValue = Integer.MAX_VALUE;
        for(IntWritable value : values) {
            minValue = Math.min(minValue, value.get());
        }
        context.write(key, new IntWritable(minValue));
    }
}
```

#### job函数
``` java
/**
 * Created by jiangweiwei on 17-7-17.
 */
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
 
public class MinTemperature {
   
    public static void main(String[] args) throws Exception {
        if(args.length != 2) {
            System.err.println("Usage: MinTemperature<input path> <output path>");
            System.exit(-1);
        }
       
        Job job = new Job();
        job.setJarByClass(MinTemperature.class);
        job.setJobName("Min temperature");
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        job.setMapperClass(MinTemperatureMapper.class);
        job.setReducerClass(MinTemperatureReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
```