---
title: java 面试
tags: java 面试
notebook: Java
---

[详细参见](http://blog.csdn.net/jackfrued/article/details/44921941)

补充：

- 9. 通常我们定义一个基本数据类型的变量，一个对象的引用，还有就是函数调用的现场保存都使用JVM中的栈空间；而通过new关键字和构造器创建的对象则放在堆空间，堆是垃圾收集器管理的主要区域。

- 12. 位运算永远是效率最高的运算。

- 16. (1)如果两个对象相同（equals方法返回true），那么它们的hashCode值一定要相同；(2)如果两个对象的hashCode相同，它们并不一定相同。想想hashmap(数组+链表实现，对于相同的hashcode，存储在同一个位置的链表上，新入的值永远在第一个)

- 18. java中都是值传递

- 19. stringbuffer: 线程安全，效率不及stringbuilder
      stringbuilder: 线程不安全
      string的+操作其本质是创建了StringBuilder对象进行append操作，然后将拼接后的StringBuilder对象用toString方法处理成String对象
      [不可变字符串](http://www.shouce.ren/api/java/biji/#)，如果是new的申明形式那么直接开辟内存，不会检查。
      **注意Ingeter在 -128~128 之间也会先检测常量池**

- 20. [为什么不能根据返回类型来区分重载](https://www.zhihu.com/question/21455159)
函数的返回值只是作为函数运行之后的一个“状态”
他是保持方法的调用者与被调用者进行通信的关键。
并不能作为某个方法的“标识”

- 24. Static Nested Class是被声明为静态（static）的内部类，它可以不依赖于外部类实例被实例化。而通常的内部类需要在外部类实例化后才能实例化。

        example:
        ``` java
        public class Poker {
            private static String[] suites = {"黑桃", "红桃", "草花", "方块"};
            private static int[] faces = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13};

            private Card[] cards;

            /**
            * 构造器
            * 
            */
            public Poker() {
                cards = new Card[52];
                for(int i = 0; i < suites.length; i++) {
                    for(int j = 0; j < faces.length; j++) {
                        cards[i * 13 + j] = new Card(suites[i], faces[j]);
                    }
                }
            }

            /**
            * 洗牌 （随机乱序）
            * 
            */
            public void shuffle() {
                for(int i = 0, len = cards.length; i < len; i++) {
                    int index = (int) (Math.random() * len);
                    Card temp = cards[index];
                    cards[index] = cards[i];
                    cards[i] = temp;
                }
            }

            /**
            * 发牌
            * @param index 发牌的位置
            * 
            */
            public Card deal(int index) {
                return cards[index];
            }

            /**
            * 卡片类（一张扑克）
            * [内部类]
            * @author 骆昊
            *
            */
            public class Card {
                private String suite;   // 花色
                private int face;       // 点数

                public Card(String suite, int face) {
                    this.suite = suite;
                    this.face = face;
                }

                @Override
                public String toString() {
                    String faceStr = "";
                    switch(face) {
                    case 1: faceStr = "A"; break;
                    case 11: faceStr = "J"; break;
                    case 12: faceStr = "Q"; break;
                    case 13: faceStr = "K"; break;
                    default: faceStr = String.valueOf(face);
                    }
                    return suite + faceStr;
                }
            }
        }
        ```
        ```java       
        class PokerTest {

            public static void main(String[] args) {
                Poker poker = new Poker();
                poker.shuffle();                // 洗牌
                Poker.Card c1 = poker.deal(0);  // 发第一张牌
                // 对于非静态内部类Card
                // 只有通过其外部类Poker对象才能创建Card对象
                Poker.Card c2 = poker.new Card("红心", 1);    // 自己创建一张牌

                System.out.println(c1);     // 洗牌后的第一张
                System.out.println(c2);     // 打印: 红心A
            }
        }
        ```
        bad case
        ```java
        class Outer {

            class Inner {}

            public static void foo() { new Inner(); }

            public void bar() { new Inner(); }

            public static void main(String[] args) {
                new Inner();
            }
        }
        ```
    注意：Java中非静态内部类对象的创建要依赖其外部类对象，上面的面试题中foo和main方法都是静态方法，静态方法中没有this，也就是说没有所谓的外部类对象，因此无法创建内部类对象，如果要在静态方法中创建内部类对象，可以这样做：`new Outer().new Inner();`(想想java执行顺序)