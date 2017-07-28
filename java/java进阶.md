---
title: java collection/map 接口实现
tags: collection map
notebook: JAVA笔记
---

[TOC]
![pic1](http://www.hollischuang.com/wp-content/uploads/2016/03/CollectionVsCollections.jpeg)

![Collection家族关系图](http://www.hollischuang.com/wp-content/uploads/2016/03/java-collection-hierarchy.jpeg)

![Map家族的关系图](http://www.hollischuang.com/wp-content/uploads/2016/03/MapClassHierarchy-600x354.jpg)

![关系图谱](http://www.hollischuang.com/wp-content/uploads/2016/03/collection-summary.png)
![整体图](http://upload-images.jianshu.io/upload_images/1594931-d1061afa6f0cbc96.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
###ArrayList
ArrayList类实现了List接口，List接口是Collection接口的子接口，主要增加了根据索引取得对象的方法。

ArrayList使用数组实现List接口，所以对于快速的随机取得对象来说，使用ArrayList可以得到较好的效能，不过在移除对象或插入对象时，ArrayList就比较慢（使用 LinkedList 在这方面就好的多）。

``` java
import java.util.*;
 
public class ArrayListDemo {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
         
        List<String> list = new ArrayList<String>();
        
        System.out.println("输入名称(quit结束)"); 
        while(true) { 
            System.out.print("# "); 
            String input = scanner.next(); 
 
            if(input.equals("quit"))
                 break; 
            list.add(input); 
        }
        
        System.out.print("显示输入: "); 
        for(int i = 0; i < list.size(); i++) 
            System.out.print(list.get(i) + " "); 
        System.out.println(); 
    }
}
```
**可以使用get()方法指定索引值取出对象**

###LinkedList

List类是以对象加入（add）容器的顺序来排列它们，如果您的对象加入之后大都是为了取出，而不会常作移除或插入（Insert）的动作，则使用ArrayList，如果您会经常从容器中作移除或插入对象的动作，则使用LinkedList会获得较好的效能。

LinkedList实现了List接口，并增加了一些移除与插入对象的特定方法，像是addFirst()、addLast()、 getFirst()、getLast()、removeFirst( )、removeLast()等等，由于在插入与移除时有较好的效能，适合拿来实现堆（Stack）与伫列（Queue）。

**LinkedList实现stack**
``` java
import java.util.*;
 
public class StringStack {
    private LinkedList<String> linkedList;
    
    public StringStack() {
        linkedList = new LinkedList<String>();
    }
    
    public void push(String name) { 
        linkedList.addFirst(name);
    }
    
    public String top() {
        return linkedList.getFirst();
    }
    
    public String pop() {
        return linkedList.removeFirst();
    }
 
    public boolean isEmpty() {
        return linkedList.isEmpty();
    }
} 
```

###HashSet

HashSet实现Set接口，Set接口继承Collection接口，Set容器中的对象都是唯一的，加入 Set容器中的对象都必须覆盖equals()方法，作为唯一性的识别，Set容器有自己的一套排序规则。

HashSet的排序规则是利用Hash Table，所以加入HashSet容器的对象还必须覆盖hashCode()方法，利用Hash的方式，可以让您快速的找到容器中的对象，在比较两个加入Set容器中的对象是否相同时，会先比较hashCode()方法传回的值是否相同，如果相同，则再使用equals()方法比较，如果两者都相同，则视为相同的对象。

###LinkedHashSet

LinkedHashSet和HashSet的区别是hashset内部的顺序不一定是插入的顺序，而LinkedHashSet是按照插入的顺序来的。
**LinkedHashSet是HashSet的子类，它在内部实现使用Hash Code进行排序**

###HashMap

HashMap实现Map接口，内部实现使用Hash Table，让您在常量时间内可以寻得key/value对。

``` java
import java.util.*;
 
public class HashMapDemo {
    public static void main(String[] args) {
        Map<String, String> map = 
                  new HashMap<String, String>();
 
        map.put("justin", "justin's message!!");
        map.put("momor", "momor's message!!");
        map.put("caterpillar", "caterpillar's message!!");
        
        Collection collection = map.values();
        Iterator iterator = collection.iterator();
        while(iterator.hasNext()) {
            System.out.println(iterator.next());
        }
    }
} 
```

**[关于hashmap和hashtable区别可以参照](http://blog.csdn.net/Double2hao/article/details/53411594)**