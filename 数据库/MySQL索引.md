---
title: mysql 索引
tags: mysql,b+tree
notebook: MYSQL
---

[TOC]

# MYSQL 索引

MySQL支持诸多存储引擎，而各种存储引擎对索引的支持也各不相同，因此MySQL数据库支持多种索引类型，如BTree索引，哈希索引，全文索引等等。为了避免混乱，本文将只关注于BTree索引，因为这是平常使用MySQL时主要打交道的索引，至于哈希索引和全文索引本文暂不讨论。

## B tree

B树与红黑树最大的不同在于，B树的结点可以有许多子女，从几个到几千个。那为什么又说B树与红黑树很相似呢?因为与红黑树一样，一棵含n个结点的B树的高度也为O（lgn），但可能比一棵红黑树的高度小许多，应为它的分支因子比较大。所以，B树可以在O（logn）时间内，实现各种如插入（insert），删除（delete）等动态集合操作。
如下图所示，即是一棵B树，一棵关键字为英语中辅音字母的B树，现在要从树种查找字母R（包含n[x]个关键字的内结点x，x有n[x]+1]个子女（也就是说，一个内结点x若含有n[x]个关键字，那么x将含有n[x]+1个子女）。所有的叶结点都处于相同的深度，带阴影的结点为查找字母R时要检查的结点）：
![pic](http://hi.csdn.net/attachment/201106/7/8394323_130745821166Sc.jpg)
**仔细理解 n+1什么意思**

## B+ tree

[参考1](http://blog.codinglabs.org/articles/theory-of-mysql-index.html) [参考2](http://www.jianshu.com/p/3a1377883742)

几个特性:

- 树度为n的话，每个节点指针上限为2n+1

- 非叶子节点不存储数据，只存储指针索引；叶子节点存储所有数据，不存储指针

- 在经典B+树基础上增加了顺序访问指针，每个叶子节点都有指向相邻下一个叶子节点的指针，如图所示。主要为了提高区间访问的性能，例如要找key为20到50的所有数据，只要按着顺序访问路线一次性访问所有数据节点。

![pic6](http://upload-images.jianshu.io/upload_images/787365-a979aa05bf72eed5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## MySQL索引实现

### MyISAM

_不支持事务操作，不支持行锁h额外键_
适用场景：不需要事物操作而且表的读操作远远多于写操作。
MyISAM引擎使用B+Tree作为索引结构，叶节点的data域存放的是数据记录的地址。下图是MyISAM索引的原理图：
![pic2](http://blog.codinglabs.org/uploads/pictures/theory-of-mysql-index/8.png)


这里设表一共有三列，假设我们以Col1为主键，则图8是一个MyISAM表的主索引（Primary key）示意。可以看出MyISAM的索引文件仅仅保存数据记录的地址。在MyISAM中，主索引和辅助索引（Secondary key）在结构上没有任何区别，只是主索引要求key是唯一的，而辅助索引的key可以重复。如果我们在Col2上建立一个辅助索引，则此索引的结构如下图所示：
![pic3](http://blog.codinglabs.org/uploads/pictures/theory-of-mysql-index/9.png)

同样也是一颗B+Tree，data域保存数据记录的地址。因此，MyISAM中索引检索的算法为首先按照B+Tree搜索算法搜索索引，如果指定的Key存在，则取出其data域的值，然后以data域的值为地址，读取相应数据记录。

MyISAM的索引方式也叫做“非聚集”的，之所以这么称呼是为了与InnoDB的聚集索引区分。

### INNODB

_支持事物操作，锁行，外键,不支持全文搜索_
适用场景：事物居多的场景。
虽然InnoDB也使用B+Tree作为索引结构，但具体实现方式却与MyISAM截然不同。

第一个重大区别是InnoDB的数据文件本身就是索引文件。从上文知道，MyISAM索引文件和数据文件是分离的，索引文件仅保存数据记录的地址。而在InnoDB中，表数据文件本身就是按B+Tree组织的一个索引结构，这棵树的叶节点data域保存了完整的数据记录。这个索引的key是数据表的主键，因此InnoDB表数据文件本身就是主索引。
![pic4](http://blog.codinglabs.org/uploads/pictures/theory-of-mysql-index/10.png)

图10是InnoDB主索引（同时也是数据文件）的示意图，可以看到叶节点包含了完整的数据记录。这种索引叫做聚集索引。因为InnoDB的数据文件本身要按主键聚集，所以InnoDB要求表必须有主键（MyISAM可以没有），如果没有显式指定，则MySQL系统会自动选择一个可以唯一标识数据记录的列作为主键，如果不存在这种列，则MySQL自动为InnoDB表生成一个隐含字段作为主键，这个字段长度为6个字节，类型为长整形。

第二个与MyISAM索引的不同是InnoDB的辅助索引data域存储相应记录主键的值而不是地址。换句话说，InnoDB的所有辅助索引都引用主键作为data域。例如，图11为定义在Col3上的一个辅助索引(**_辅助索引是否存在文件？_**)：
![pic5](http://blog.codinglabs.org/uploads/pictures/theory-of-mysql-index/11.png)

这里以英文字符的ASCII码作为比较准则。聚集索引这种实现方式使得按主键的搜索十分高效，但是辅助索引搜索需要检索两遍索引：首先检索辅助索引获得主键，然后用主键到主索引中检索获得记录。

了解不同存储引擎的索引实现方式对于正确使用和优化索引都非常有帮助，例如知道了InnoDB的索引实现后，就很容易明白为什么不建议使用过长的字段作为主键，因为所有辅助索引都引用主索引，过长的主索引会令辅助索引变得过大。再例如，用非单调的字段作为主键在InnoDB中不是个好主意，**因为InnoDB数据文件本身是一颗B+Tree，非单调的主键会造成在插入新记录时数据文件为了维持B+Tree的特性而频繁的分裂调整，十分低效**，而使用自增字段作为主键则是一个很好的选择。

