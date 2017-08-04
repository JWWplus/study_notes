---
title: java 快速排序
tags: java
notebook: Java
---

[TOC]

### 代码实现

```java
public class quicksort{
    public static void main(String[] args){
        int [] n = {43,2,4,3,56,13,-3,5,10,74};
        int low = 0;
        int high = n.length - 1;
        _quicksort(n, low, high);
        for (int i: n){
            System.out.println(i);
        }
    }

    public static void _quicksort(int[] n, int low, int high){
        int temp = n[low];
        int l = low;
        int r = high;
        if(l < r){
            while (l < r){
                while (l < r && temp < n[r]){
                    r--;
                }
                if (l < r){
                    n[l] = n[r];
                }
                while (l < r && temp >= n[l])
                    l++;
                if (l < r){
                    n[r] = n[l];
                }
            }
            n[l] = temp;
            _quicksort(n, low, l - 1);
            _quicksort(n, l + 1, high);
        }
    }
}
```

### 核心思想：

1. 选定一个合适的值（理想情况中值最好，但实现中一般使用数组第一个值）,称为“枢轴”(pivot)。
1. 基于这个值，将数组分为两部分，较小的分在左边，较大的分在右边。
1. 可以肯定，如此一轮下来，这个枢轴的位置一定在最终位置上。
1. 对两个子数组分别重复上述过程，直到每个数组只有一个元素。
1. 排序完成。

### 算法示意图
![pic](http://upload.wikimedia.org/wikipedia/commons/6/6a/Sorting_quicksort_anim.gif)

### 算法复杂度

可以看出，那么，每层排序大约需要O(n)复杂度。而一个长度为n的数组，调用深度最多为log(n)层。二者相乘，得到快速排序的平均复杂度为O(n ㏒n)。
通常，快速排序被认为是在所有同数量级的排序方法中，平均性能最好。
从代码中可以很容易地看出，快速排序单个栈的空间复杂度不高，每次调用partition方法时，其额外开销只有O(1)。所以，最好情形下快速排序空间复杂度大约为O(㏒n)。
上面这个快速排序算法可以说是最基本的快速排序，因为它并没有考虑任何输入数据。但是，我们很容易发现这个算法的缺陷：这就是在我们输入数据基本有序甚至完全有序的时候，这算法退化为冒泡排序，不再是O(n㏒n)，而是O(n^2)了