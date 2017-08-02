---
title: java 执行顺序
tags: java
notebook: Java
---

[TOC]

# Java中main方法，静态，非静态的执行顺序详解

Java程序运行时，第一件事情就是试图访问main方法，因为main相等于程序的入口，如果没有main方法，程序将无法启动，main方法更是占一个独立的线程，找到main方法后，是不是就会执行mian方法块里的第一句话呢？答案是不一定

```java
public class Test1 {
public static String name;
    public Test1() {
    }
    public static void get() {
        System.out.println("Test start");
    }
    public static void main(String[] args) {
        System.out.println("main start");
        Test1 bb = new Test1();
    }
}
```

总结：只要按照这个步骤，遇到这一类问题就可以解决了。

1-3：类加载过程，不涉及构造方法

1-5: 实例化过程，涉及构造方法

　　1.类中所有属性的默认值（一举而成）

　　2. 父类静态属性初始化，静态块，静态方法的声明（按出现顺序执行）

　　3. 子类静态属性初始化，静态块，静态方法的声明 （按出现顺序执行）

　　4.  调用父类的构造方法，

　　　　　　首先父类的非静态成员初始化，构造块，普通方法的声明（按出现顺序执行）

　　　　　　然后父类构造方法

　　5.  调用子类的构造方法，

　　　　　　首先子类的非静态成员初始化，构造块，普通方法的声明（按出现顺序执行）

　　　　　　然后子类构造方法
## 分析：

- 因为静态部分是依赖于类，而不是依赖于对象存在的，所以静态部分的加载优先于对象存在。

- 当找到main方法后，因为main方法虽然是一个特殊的静态方法，但是还是静态方法，此时JVM会加载main方法所在的类，试图找到类中其他静态部分，即首先会找main方法所在的类。

执行顺序大致分类：

1. 静态属性，静态方法声明，静态块。(谁写在上面谁先)

2. 动态属性，普通方法声明，构造块。

3. 构造方法。

# 一般类的初始化顺序
对于静态变量、静态初始化块、变量、初始化块、构造器，它们的初始化顺序依次是（静态变量、静态初始化块）>（变量、初始化块）>构造器

代码
``` java
public class InitialOrderTest {
        /* 静态变量 */
    public static String staticField = "静态变量";
        /* 变量 */
    public String field = "变量";
        /* 静态初始化块 */
    static {
        System.out.println( staticField );
        System.out.println( "静态初始化块" );
    }
        /* 初始化块 */
    {
        System.out.println( field );
        System.out.println( "初始化块" );
    }
        /* 构造器 */
    public InitialOrderTest()
    {
        System.out.println( "构造器" );
    }


    public static void main( String[] args )
    {
        new InitialOrderTest();
    }
}
```
结果
```
    静态变量
    静态初始化块
    变量
    初始化块
    构造器
```

# 带有继承的情况

代码
```java
class Parent {
        /* 静态变量 */
    public static String p_StaticField = "父类--静态变量";
         /* 变量 */
    public String    p_Field = "父类--变量";
    protected int    i    = 9;
    protected int    j    = 0;
        /* 静态初始化块 */
    static {
        System.out.println( p_StaticField );
        System.out.println( "父类--静态初始化块" );
    }
        /* 初始化块 */
    {
        System.out.println( p_Field );
        System.out.println( "父类--初始化块" );
    }
        /* 构造器 */
    public Parent()
    {
        System.out.println( "父类--构造器" );
        System.out.println( "i=" + i + ", j=" + j );
        j = 20;
    }
}

public class SubClass extends Parent {
         /* 静态变量 */
    public static String s_StaticField = "子类--静态变量";
         /* 变量 */
    public String s_Field = "子类--变量";
        /* 静态初始化块 */
    static {
        System.out.println( s_StaticField );
        System.out.println( "子类--静态初始化块" );
    }
       /* 初始化块 */
    {
        System.out.println( s_Field );
        System.out.println( "子类--初始化块" );
    }
       /* 构造器 */
    public SubClass()
    {
        System.out.println( "子类--构造器" );
        System.out.println( "i=" + i + ",j=" + j );
    }


        /* 程序入口 */
    public static void main( String[] args )
    {
        System.out.println( "子类main方法" );
        new SubClass();
    }
}
```

result
```
父类--静态变量
父类--静态初始化块
子类--静态变量
子类--静态初始化块
子类main方法
父类--变量
父类--初始化块
父类--构造器
i=9, j=0
子类--变量
子类--初始化块
子类--构造器
i=9,j=20
```
**子类的静态变量和静态初始化块的初始化是在父类的变量、初始化块和构造器初始化之前就完成了。静态变量、静态初始化块，变量、初始化块初始化了顺序取决于它们在类中出现的先后顺序。**

在代码中如果静态变量的值在初始化之前先于代码块中使用那么编译会不通过。