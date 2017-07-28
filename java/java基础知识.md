---
title: java 基础知识
tags: java basic
notebook: Java
---

[TOC]

##java的autoboxing/unboxing
基本（Primitive）数据类型不是对象，也就是您使用int、double、boolean等声明的变量，以及您在程序中直接写下的字面常量。

您要使用包裹类型（Wrapper Types）才能将基本数据类型包装为对象，例如在 J2SE 1.4.2 之前，您要如下才能将int包装为一个Integer对象：
`Integer integer = new Integer(10);`

在 J2SE 5.0 之后您可以这么写：
`Integer integer = 10;`

事实上编译器在背后自动根据您写下的陈述，为您进行自动装箱（Autoboxing）动 作，同样的动作可以适用于 boolean、byte、short、char、long、float、double等基本类型，分别会使用对应的包裹类型（Wrapper Types）Boolean、Byte、Short、Character、Integer、Long、Float或Double。
