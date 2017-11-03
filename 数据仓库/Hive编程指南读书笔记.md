[TOC]

# &lt;&lt;Hive编程指南&gt;&gt;读书笔记

## 1. 设置hive以本地模式运行(即使当前用户是在分布式模式或伪分布式模式下执行也使用这种模式)

```
set hive.exec.model.local.auto=true;
```

若想默认使用这个配置,可以将这个命令添加到```$HOME/.hiverc```文件中

## 2. 当频繁使用```hadoop``` ```dfs```命令时，最好为这个命令定义一个别名

```
alias hfs="hadoop dfs"
```

## 3. hive表数据默认存储位置(基于hadoop的运行模式)

* hadoop为本地模式:```file:///user/hive/warehouse```
* hadoop分布式模式:```hdfs://namenode_server/user/hive/warehouse```

## 4. 用户使用下面的命令可以自定义数据仓库的位置

```
set hive.metastore.warehouse.dir=/user/myname/hive/warehouse;
```

可以将这条语句写入到```$HOME/.hiverc```文件中

## 5. 开启在hive命令行中显示当前数据库名

```
set hive.cli.print.current.db=true;
```

## 6. hive -S 静默输出,在标准输出中不显示其他信息

* hive -e 后面直接跟HiveQL

* hive -S -e "select name from person;"

*Hive会将输出写到标准输出中,可以使用shell中的输出重定向将输出重定向到本地文件中,而不是hdfs中*

## 7. hive模糊取某个属性名

```
hive -S -e "set" | grep warehouse 查询数据仓库的位置
```

## 8. 从文件中执行Hive查询

```
hive -f /user/scott/hive.hql
```

或者在```hive shell```中使用```source```命令来执行脚本文件

```
hive > source /user/scott/hive.hql
```

## 9. hiverc文件

hive启动后默认会在当前用户home目录下寻找名为```.hiverc```的文件,且自动执行文件中的命令

一个典型的.hiverc文件中的内容为

```
ADD JAR /user/scott/hive-examples.jar;   #增加一个jar文件
set hive.cli.print.current.db=true;     #显示当前所在工作数据库
set hive.exec.model.local.auto=true;    #设置以本地文件模式运行(当hadoop是以分布式模式或者伪分布式模式执行时的话,就在本地执行,可以加快小数据集的查询速度)
```

*注:每行语句结尾的分号不可省略*

## 10. 在hive shell中执行shell命令

用户不需要退出hive就可以执行shell命令,只需要在命令前加上!并且以;结尾就可以,如:

```
hive > !pwd;  #查看当前目录
```

*注:hive shell中使用shell命令时,不能使用需要用户进行输入交互的命令,且不支持shell的管道功能和文件名自动补全功能。*

## 11. 在hive中使用hadoop命令

```
hive > dfs -ls /;
```

## 12. hive脚本中的注释

-- 用户使用以```--```开头的字符表示注释。该注释只能放在hiveql脚本中若直接在hive shell中使用的话会报错

## 13. 让cli显示字段名称

```
hive > set hive.cli.print.header=true;
```

同理可以将该语句添加到```$home/.hiverc```文件中

## 14. Hive中的数据库

如果用户没有显式指定数据库,默认数据库是default

下面这个例子展示了如何创建数据库

```
CREATE DATABASE simple;
```

若数据库```simple```已经存在的话,将会报错误消息。可以使用下面的语句避免错误信息

```
CREATE DATABASE IF NOT EXISTS simple;
```

使用```SHOW DATABASES```命令查看hive中所包含的数据库

```
SHOW DATABASES;
```
如果数据库比较多,可以使用正则表达式匹配筛选所需要的数据库名

```
SHOW DATABASES LIKE 'sim.*';
```
Hive为每个数据库创建一个目录,数据库中的表将会以这个数据库目录的子目录形式存储。有一个例外就是default数据库中的表。因为这个数据库本身没有自己的目录。数据库所在的目录位于属性```hive.metastore.warehouse.dir```所指定的顶层目录之后。假若用户使用的这个配置项的默认配置,也就是```/user/hive/warehouse```,那么当我们创建数据库```simple```时,Hive将会对应地创建一个目录为```/user/hive/warehouse/simple.db```。这里请注意,数据库的文件目录名是以```.db```结尾的。

用户可以通过如下的命令来修改这个默认的配置

```
hive > CREATE DATABASE simple LOCATION '/user/myname/directory';
```

用户还可以为这个数据库增加一个描述信息。这样通过```DESCRIBE DATABASE databasename```命令就可以查看到该信息

```
hive > CREATE DATABASE simple COMMENT 'a simple database';
```

使用```DESCRIBE DATABASE databasename```查看

```
hive > DESCRIBE DATABASE simple;
simple a simple database
	hdfs://hostname/user/hive/warehouse/simple.db
```

从上面的例子可以看出```DESCRIBE DATABASE```不仅会显示这个数据库的描述信息还会显示这个数据库所在文件的目录位置。若Hadoop是本地模式的话前面的前缀为```file:///```若是分布式模式则前缀为```hdfs://```

此外用户还可以为数据库增加一些和其他相关的键-值对属性信息。可以使用```DESCRIBE DATABASE EXTENDED databasename```语句显示这些信息,如：

```
hive > CREATE DATABASE simple WITH DBPROERTIES ('creator'='scott','date'='2014-05-05');
hive > DESCRIBE DATABASE simple;
hive > DESCRIBE DATABASE EXTENDED simple;
```

命令```USE```用于将某个数据库设置为当前的工作数据库。如:

```
USE simple;
```

此时可以用```SHOW TABLES```显示当前数据库下所有的表。不幸的是,没有那个命令让用户查看当前所在的库。幸运的是在Hive中可以重复使用```USE```,这是因为在Hive中没有嵌套数据库的概念。

```
hive > set hive.cli.print.current.db=true;
hive (simple) > USE default;
hive (default) > set hive.cli.print.current.db=false;
```

最后用户可以删除数据库

```
hive > DROP DATABASE IF EXISTS simple;
```

```IF EXISTS```子句是可选的。可以避免因数据库不存在而抛出警告信息。默认情况下Hive是不允许用户删除一个包含有表的数据仓库。要么用户先删除库中的表,然后再删数据库。要么在删除命令的最后面加上关键字```CASCADE```，这样Hive先自行删除数据库中的表

```
hive > DROP DATABASE IF EXISTS simple CASCADE;
```

若使用的是```RESTRICT```这个关键字,而不是```CASCADE```这个关键字的话,那么就和默认情况一样。

如果某个数据库被删除了,那么其对应的目录也同时会被删除。

## 15. 修改数据库

用户可以使用```ALTER DATABASE```命令为某个数据库的```DBPROPERTIES```设置键-值对属性值,来描述数据库的属性信息。数据库的其他元数据信息是不可更改的,包括数据库名和数据库所在的目录位置。

```
hive > ALTER DATABASE simple SET DBPROPERTIES ('edited-by'='Join');
```

没有办法删除或者"重置"数据库属性。

## 16. 创建表

```
CREATE TABLE IF NOT EXISTS mydb.employees (
name STRING COMMENT 'Employee name',
salary FLOAT COMMENT 'Employee salary',
subordinates ARRAY<STRING> COMMENT 'Names of subordinates',
deductions MAP<STRING, FLOAT>
COMMENT 'Keys are deductions names, values are percentages',
address STRUCT<street:STRING, city:STRING, state:STRING, zip:INT>
COMMENT 'Home address')
COMMENT 'Description of the table'
TBLPROPERTIES ('creator'='me', 'created_at'='2012-01-02 10:00:00')
LOCATION '/user/hive/warehouse/mydb.db/employees';
```

首先,我们注意到,如果用户当前所处的数据库并非是目标数据库，那么用户是可以在表名前增加一个```数据库名```来进行指定的，也就是例子中的mydb

如果用户增加上选项```IF NOT EXISTS```，那么若表已经存在了，Hive就会忽略掉后面的执行语句。且不会有任何提示。用户可以在字段类型后使用```COMMENT```为每个字段增加一个注释。还可以指定一个或多个表属性。大多数情况下```TBLPROPERTIES```的主要作用是按键-值对的格式为表增加额外的文档说明。

Hive会自动增加两个表属性:一个是```last_modified_by```，其保存着最后修改这个表的用户的用户名;另一个是```last_modified_time```其保存着最后一次修改这个表的新纪元时间秒。

使用```SHOW TBLPROPERTIES table_name```列举出某个表的```TBLPROPERTIES```属性信息

最后，可以看到我们根据情况为表中的数据指定一个存储路径。在这个例子中,我们使用Hive默认的路径```/user/hive/warehouse/mydb.db/employees```,其中,```/user/hive/warehouse```是默认的数据仓库路径,```mydb.db```是数据库目录,```employees```是表目录。

默认情况下。Hive总是将创建的表的目录放置在这个表所属的数据库目录之下。不过,```default```数据库是个例外,其在```/user/hive/warehouse```下并没有对应一个数据库目录。因此```default```数据库中的表目录会直接位于```/user/hive/warehouse```目录下(用户明确指定除外).

用户还可以拷贝一张已经存在的表的模式(无需拷贝数据):

```
CREATE TABLE IF NOT EXISTS mydb.employees2
LIKE mydb.employees;
```

该语句可以接受可选的```LOCATION```子句,但是注意其他的属性，包括模式都是不可能重新定义的。这些信息直接从原是表获得.

```SHOW TABLES```命令可以列举出所有的表,如果不增加其他参数,那么只会显示当前工作数据库下的表。假设不在那么数据库下，还是可以列出指定数据库下的表使用```SHOW TABLES IN dbname```

```
hive > USE default;
hive > SHOW TABLES IN mydb;
employees
department
```
如果有很多的表，那么可以使用正则表达式来过滤出所需要的表名.

```
hive> USE mydb;
hive> SHOW TABLES 'empl.*';
employees
```

注意:```IN databasename```和表名使用正则表达式过滤这个两个功能尚不支持同时使用.

我们可以使用```DESCRIBE EXTENDED mydb.employees```命令来查看这个表的详细结构信息(如果当前所处的工作数据库就是mydb的话，可以不加mydb这个前缀).

```
hive> DESCRIBE EXTENDED mydb.employees;
name string Employee name
salary float Employee salary
subordinates array<string> Names of subordinates
deductions map<string,float> Keys are deductions names, values are percentages
address struct<street:string,city:string,state:string,zip:int> Home address
Detailed Table Information Table(tableName:employees, dbName:mydb, owner:me,
...
location:hdfs://master-server/user/hive/warehouse/mydb.db/employees,
parameters:{creator=me, created_at='2012-01-02 10:00:00',
last_modified_user=me, last_modified_time=1337544510,
comment:Description of the table, ...}, ...)
```

使用```FORMATTED```关键字替代```EXTENDED```关键字的话,可以提供更加可读的输出信息。在应用中多使用```FORMATTED```关键字

```
DESCRIBE FORMATTED employees;
```

如果用户只想查看某一个列的信息，那么只要在表名后面增加这个字段的名称即可.

```
hive> DESCRIBE mydb.employees.salary;
salary float Employee salary
```

注:```last_modified_by```和```last_modified_time```两个表属性是自动创建的。如果用户没有定义任何的自定义表属性的话,那么这两个表属性也不会显示在表的详细信息中!

## 17. 管理表

我们目前所创建的表均属于管理表,有时也被称为内部表.因为这种表,Hive会或多或少的控制着数据项的生命周期.如:Hive默认情况下会将这些表的数据存储在由配置项```hive.metastore.warehouse.dir```(如```/user/hive/warehouse```)所定义的目录的子目录下.

当我们删除一个管理表时,Hive也会删除这个表中的数据.管理表不方便和其他工作共享数据。

## 18. 外部表

```
CREATE EXTERNAL TABLE IF NOT EXISTS stocks (
exchange STRING,
symbol STRING,
ymd STRING,
price_open FLOAT,
price_high FLOAT,
price_low FLOAT,
price_close FLOAT,
volume INT,
price_adj_close FLOAT)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION '/data/stocks';
```

关键字```EXTERNAL```告诉Hive这个表是外部的。而后面的```LOCATION```子句告诉Hive数据位于那个路径下.
因为表是外部的,所以Hive并非认为其完全拥有这份数据，因此，删除该表并不会删除掉这份数据,不过描述表的元数据信息将会被删除掉.

用户可以在```DESCRIBE EXTENDED tablename```语句的输出中查看到表是管理表还是外部表.在末尾的详细表信息输出中,对于管理表，用户可以看到如下信息:

```
tableType:MANAGED_TABLE
```

对于外部表

```
tableType:EXTERNAL_TABLE
```

对于管理表,用户可以对一张存在的表进行结构复制(不会复制数据)

```
CREATE EXTERNAL TABLE IF NOT EXISTS mydb.employees3
LIKE mydb.employees
LOCATION '/path/to/data';
```

若语句中省略掉```EXTERNAL```关键字,且源表是外部表的话,那么新生成的表也将是外部表,若语句中省略掉```EXTERNAL```关键字,且源表是管理表的话,那么新生成的表也将是管理表。
若语句中含有```EXTERNAL```关键字,且源表是管理表的话，那么生成的新表将是外部表。
即使在这种场景下,```LOCATION```子句同样是可选的。


## 19. 分区表、管理表

Hive中有分区表的概念。分区表将数据以一种符合逻辑的方式进行组织。比如分层存储。

```
CREATE TABLE employees (
name STRING,
salary FLOAT,
subordinates ARRAY<STRING>,
deductions MAP<STRING, FLOAT>,
address STRUCT<street:STRING, city:STRING, state:STRING, zip:INT>
)
PARTITIONED BY (country STRING, state STRING);
```

如果表中的数据以及分区个数非常大的话,执行一个包含所有分区的查询可能会触发一个巨大的MapReduce任务。建议的安全措施是将Hive设置为```“strict”```模式,这样对分区表查询WHERE子句没有加分区过滤的话,将会禁止提交这个任务.可以按照下面的语句将属性设置为```“nonstrict”```模式。

```
hive> set hive.mapred.mode=strict;

hive> SELECT e.name, e.salary FROM employees e LIMIT 100;
FAILED: Error in semantic analysis: No partition predicate found for
Alias "e" Table "employees"

hive> set hive.mapred.mode=nonstrict;

hive> SELECT e.name, e.salary FROM employees e LIMIT 100;
```

可以通过使用```SHOW PARTITIONS```命令查看表中存在的所有分区

```
hive> SHOW PARTITIONS employees;
...
Country=CA/state=AB
country=CA/state=BC
...
country=US/state=AL
country=US/state=AK
```

如果表中存在很多的分区，而只想查看是否存储某个特定分区键的分区的话。可以在这个命令上增加一个指定了一个或者多个特定分区字段值的```PARTITION```子句，进行过滤

```
hive> SHOW PARTITIONS employees PARTITION(country='US');
country=US/state=AL
country=US/state=AK
...
hive> SHOW PARTITIONS employees PARTITION(country='US', state='AK');
country=US/state=AK
```

```DESCRIBE EXTENDED employees```命令也会显示出分区键

```
hive> DESCRIBE EXTENDED employees;
name string,
salary float,
...
address struct<...>,
country string,
state string
Detailed Table Information...
partitionKeys:[FieldSchema(name:country, type:string, comment:null),
FieldSchema(name:state, type:string, comment:null)],
```

在管理表中用户可以通过载入数据的方式创建分区。下面的例子将从本地目录()载入数据到表中的时候.将会创建一个US和CA分区.用户需要为每个分区字段指定一个值.注意在HiveQL中是如何引用HOME环境变量的:

```
LOAD DATA LOCAL INPATH '${env:HOME}/california-employees'
INTO TABLE employees
PARTITION (country = 'US', state = 'CA');
```

Hive将会创建这个分区对应的目录```/employees/country=US/state=CA```且```$HOME/california-employees```目录下的文件将会被拷贝到上述分区目录下。

## 20. 外部分区表

```
CREATE EXTERNAL TABLE IF NOT EXISTS log_messages (
hms INT,
severity STRING,
server STRING,
process_id INT,
message STRING)
PARTITIONED BY (year INT, month INT, day INT)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';
```

分区外部表对```LOCATION```没有要求,使用```ALTER TABLE```语句单独进行增加分区.这个语句需要为每一个分区键指定一个值。如:

```
ALTER TABLE log_messages ADD PARTITION(year = 2012, month = 1, day = 2)
LOCATION 'hdfs://master_server/data/log_messages/2012/01/02';
```

Hive并不控制这些数据,即使表被删除,数据也不会被删除.

和分区管理表一样.通过```SHOW PARTITIONS```查看外部表的分区。如:

```
hive> SHOW PARTITIONS log_messages;
...
year=2011/month=12/day=31
year=2012/month=1/day=1
year=2012/month=1/day=2
...
```

同样,```DESCRIBE EXTENDED log_messages```语句会将分区键作为表的模式一部分和partitionKeys列表的内容同时显示

```
hive> DESCRIBE EXTENDED log_messages;
...
message string,
year int,
month int,
day int
Detailed Table Information...
partitionKeys:[FieldSchema(name:year, type:int, comment:null),
FieldSchema(name:month, type:int, comment:null),
FieldSchema(name:day, type:int, comment:null)],
...
```
这个输出少了一个非常重要的信息.那就是分区数据实际存在的路径.

通过以下方式查看分区数据所在路径

```
hive> DESCRIBE EXTENDED log_messages PARTITION (year=2012, month=1, day=2);
...
location:s3n://ourbucket/logs/2011/01/02,
...
```

通常会使用分区外部表.

## 21. 自定义表的存储格式

Hive默认的存储格式是文本文件格式.可以通过可选的子句```STORED AS TEXTFILE```显式指定.同时用户可以在创建表的时指定各种各样的分隔符.

```
CREATE TABLE employees (
name STRING,
salary FLOAT,
subordinates ARRAY<STRING>,
deductions MAP<STRING, FLOAT>,
address STRUCT<street:STRING, city:STRING, state:STRING, zip:INT>
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\001'
COLLECTION ITEMS TERMINATED BY '\002'
MAP KEYS TERMINATED BY '\003'
LINES TERMINATED BY '\n'
STORED AS TEXTFILE;
```

注:```TEXTFILE```意味着所有字段都使用字母、数字、字符编码,包括那么国际字符集.Hive默认是使用不可见字符来作为分隔符的。使用```TEXTFILE```意味着，每一行被认为是一个单独的记录.可以使用```SEQUENCEFILE```和```RCFILE```两种文件格式来替换```TEXTFILE```.这两种文件格式都是使用二进制编码和压缩来优化磁盘空间及I/O带宽性能的。

记录编码是通过一个```input format```对象来控制的。Hive使用了一个名为```org.apache.hadoop.mapred.TextInputFormat```的java类.

记录的解析是由序列化/反序列化(SerDe)来控制的，对于```TEXTFILE```Hive所使用的```SerDe```是```org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe```java类.

Hive使用一个叫做```output format```的对象将查询输出写入到文件中或者输出到控制台.对于```TEXTFILE```Hive所使用的输出类为```org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat```

可以使用第三方的输入输出格式及SerDe，允许用户自定义Hive本身不支持的其他文件格式

```
CREATE TABLE kst
PARTITIONED BY (ds string)
ROW FORMAT SERDE 'com.linkedin.haivvreo.AvroSerDe'
WITH SERDEPROPERTIES ('schema.url'='http://schema_provider/kst.avsc')
STORED AS
INPUTFORMAT 'com.linkedin.haivvreo.AvroContainerInputFormat'
OUTPUTFORMAT 'com.linkedin.haivvreo.AvroContainerOutputFormat';
```

```ROW FORMAT SERDE …```指定了使用的SerDe。Hive提供了```WITH SERDEPROPERTIES```功能，允许用户传递配置信息给SerDe。每个属性名称和值都应该是带引号的字符串.

```STORED AS INPUTFORMAT … OUTPUTFORMAT```分别定义了用于输入和输出格式的java类。如果要指定，必须对输入和输出格式都指定.

```DESCRIBE EXTENDED table```会列出输入和输出格式以及SerDe和SerDe所自带的属性信息。如:

```
hive> DESCRIBE EXTENDED kst
...
inputFormat:com.linkedin.haivvreo.AvroContainerInputFormat,
outputFormat:com.linkedin.haivvreo.AvroContainerOutputFormat,
...
serdeInfo:SerDeInfo(name:null,
serializationLib:com.linkedin.haivvreo.AvroSerDe,
parameters:{schema.url=http://schema_provider/kst.avsc})
...
```

## 22. 删除表

```
DROP TABLE IF EXISTS employees;
```

对于管理表,表的元数据信息和表内的数据都被删除

对于外部表,表的元数据信息会被删除,但是表中的数据不会被删除

## 23. 修改表

大多数的表属性可以通过使用```ALTER TABLE```语句来修改.该操作会修改元数据,但不会修改数据本身.用于修改表模式中的错误及分区路径.

### 23.1 表重命名

```
ALTER TABLE log_messages RENAME TO logmsgs;
```

### 23.2 增加、修改和删除表分区

增加表分区

```
ALTER TABLE log_messages ADD IF NOT EXISTS
PARTITION (year = 2011, month = 1, day = 1) LOCATION '/logs/2011/01/01'
PARTITION (year = 2011, month = 1, day = 2) LOCATION '/logs/2011/01/02'
PARTITION (year = 2011, month = 1, day = 3) LOCATION '/logs/2011/01/03'
...;
```

修改分区路径

```
ALTER TABLE log_messages PARTITION(year = 2011, month = 12, day = 2)
SET LOCATION 's3n://ourbucket/logs/2011/01/02';
```
这个命令不会将数据从旧的路径移走，也不会删除旧的数据


删除分区

```
ALTER TABLE log_messages DROP IF EXISTS PARTITION(year = 2011, month = 12, day = 2);
```
对于管理表分区内的数据和元数据会一起被删除。对应外部表，分区内的数据不会被删除

### 23.3 修改列信息

可以对字段重命名、修改其位置、类型或者注释:

```
ALTER TABLE log_messages
CHANGE COLUMN hms hours_minutes_seconds INT
COMMENT 'The hours, minutes, and seconds part of the timestamp'
AFTER severity;
```
即使字段名和字段类型都没有改变，也需要完全指定旧的字段名。并给出新的字段名以及新的字段类型。若要将字段移动到第一个位置，只需要使用```FIRST```关键字替代```AFTER other_column```子句即可.

这个操作，只会修改元数据信息。要注意数据与模式匹配.

### 23.4 增加列

可以在分区字段前增加新的字段到已有字段之后

```
ALTER TABLE log_messages ADD COLUMNS (
app_name STRING COMMENT 'Application name',
session_id LONG COMMENT 'The current session id');
```

### 23.5 删除或者替换列

```
ALTER TABLE log_messages REPLACE COLUMNS (
hours_mins_secs INT COMMENT 'hour, minute, seconds from timestamp',
severity STRING COMMENT 'The message severity'
message STRING COMMENT 'The rest of the message');
```

### 23.6 修改表属性

```
ALTER TABLE log_messages SET TBLPROPERTIES (
'notes' = 'The process id is no longer captured; this column is always NULL');
```
可以增加附加的表属性或者修改已经存在的表属性。但是无法删除属性。

### 23.7 修改存储属性

```
ALTER TABLE log_messages
PARTITION(year = 2012, month = 1, day = 1)
SET FILEFORMAT SEQUENCEFILE;
```

如果是分区表，需要使用```PARTITION```子句

```
ALTER TABLE table_using_JSON_storage
SET SERDE 'com.example.JSONSerDe'
WITH SERDEPROPERTIES (
'prop1' = 'value1',
'prop2' = 'value2');
```

### 23.8 众多的修改表语句

```ALTER TABLE … TOUCH```语句用于触发钩子

```
ALTER TABLE log_messages TOUCH
PARTITION(year = 2012, month = 1, day = 1);
```

```ALTER TABLE … ARCHIVE PARTITION```将分区内的文件打成一个Hadoop压缩包(HAR)文件.仅仅降低文件系统中的文件数和NameNode的压力，不会减少存储空间

```
ALTER TABLE log_messages ARCHIVE
PARTITION(year = 2012, month = 1, day = 1);
```

最后Hive提供了保护，下面的语句防止分区被删除和被查询

```
ALTER TABLE log_messages
PARTITION(year = 2012, month = 1, day = 1) ENABLE NO_DROP;
```

```
ALTER TABLE log_messages
PARTITION(year = 2012, month = 1, day = 1) ENABLE OFFLINE;
```

## 24.HIVE DDL

### Create/Drop/Truncate Table

Create语法大全

``` sql
CREATE [TEMPORARY] [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name    -- (Note: TEMPORARY available in Hive 0.14.0 and later)
  [(col_name data_type [COMMENT col_comment], ... [constraint_specification])]
  [COMMENT table_comment]
  [PARTITIONED BY (col_name data_type [COMMENT col_comment], ...)]
  [CLUSTERED BY (col_name, col_name, ...) [SORTED BY (col_name [ASC|DESC], ...)] INTO num_buckets BUCKETS]
  [SKEWED BY (col_name, col_name, ...)                  -- (Note: Available in Hive 0.10.0 and later)]
     ON ((col_value, col_value, ...), (col_value, col_value, ...), ...)
     [STORED AS DIRECTORIES]
  [
   [ROW FORMAT row_format] 
   [STORED AS file_format]
     | STORED BY 'storage.handler.class.name' [WITH SERDEPROPERTIES (...)]  -- (Note: Available in Hive 0.6.0 and later)
  ]
  [LOCATION hdfs_path]
  [TBLPROPERTIES (property_name=property_value, ...)]   -- (Note: Available in Hive 0.6.0 and later)
  [AS select_statement];   -- (Note: Available in Hive 0.5.0 and later; not supported for external tables)
 
CREATE [TEMPORARY] [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name
  LIKE existing_table_or_view_name
  [LOCATION hdfs_path];
 
data_type
  : primitive_type
  | array_type
  | map_type
  | struct_type
  | union_type  -- (Note: Available in Hive 0.7.0 and later)
 
primitive_type
  : TINYINT
  | SMALLINT
  | INT
  | BIGINT
  | BOOLEAN
  | FLOAT
  | DOUBLE
  | DOUBLE PRECISION -- (Note: Available in Hive 2.2.0 and later)
  | STRING
  | BINARY      -- (Note: Available in Hive 0.8.0 and later)
  | TIMESTAMP   -- (Note: Available in Hive 0.8.0 and later)
  | DECIMAL     -- (Note: Available in Hive 0.11.0 and later)
  | DECIMAL(precision, scale)  -- (Note: Available in Hive 0.13.0 and later)
  | DATE        -- (Note: Available in Hive 0.12.0 and later)
  | VARCHAR     -- (Note: Available in Hive 0.12.0 and later)
  | CHAR        -- (Note: Available in Hive 0.13.0 and later)
 
array_type
  : ARRAY < data_type >
 
map_type
  : MAP < primitive_type, data_type >
 
struct_type
  : STRUCT < col_name : data_type [COMMENT col_comment], ...>
 
union_type
   : UNIONTYPE < data_type, data_type, ... >  -- (Note: Available in Hive 0.7.0 and later)
 
row_format
  : DELIMITED [FIELDS TERMINATED BY char [ESCAPED BY char]] [COLLECTION ITEMS TERMINATED BY char]
        [MAP KEYS TERMINATED BY char] [LINES TERMINATED BY char]
        [NULL DEFINED AS char]   -- (Note: Available in Hive 0.13 and later)
  | SERDE serde_name [WITH SERDEPROPERTIES (property_name=property_value, property_name=property_value, ...)]
 
file_format:
  : SEQUENCEFILE
  | TEXTFILE    -- (Default, depending on hive.default.fileformat configuration)
  | RCFILE      -- (Note: Available in Hive 0.6.0 and later)
  | ORC         -- (Note: Available in Hive 0.11.0 and later)
  | PARQUET     -- (Note: Available in Hive 0.13.0 and later)
  | AVRO        -- (Note: Available in Hive 0.14.0 and later)
  | INPUTFORMAT input_format_classname OUTPUTFORMAT output_format_classname
 
constraint_specification:
  : [, PRIMARY KEY (col_name, ...) DISABLE NOVALIDATE ]
    [, CONSTRAINT constraint_name FOREIGN KEY (col_name, ...) REFERENCES table_name(col_name, ...) DISABLE NOVALIDATE 
```

### Managed and External Tables

hive中存在内部表和外部表,内部表所有的数据由hive来掌管,drop表后对应的数据也会相应的被删除~
外部表中hive只管理元数据,数据存放在ddl指定的location位置上,删除表不会删除数据.

*当使用外部表时,如果外部表的结构或者分区发生了变化, 请使用`msck repair table table_name` 来刷新元数据,否则不会读取新的分区的数据.*

### Storage Formats

hive目前支持一下几种存储格式:

- TEXTFILE
- SEQUENCEFILE
- ORC
- PARQUET
- AVRO
- RCFILE
- STORED BY 其他定制的文件类型,需要定制jar包并指明输入输出格式
- INPUTFORMAT OUTPUTFORMAT (必须成对出现)

example:

``` sql
create external table `train_data`(
    id int,
    MovieID int,
    custormer int,
    rating string,
    data string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
;
```

### Row Formats & SerDe

每一行数据的解析格式/序列化格式
内置有 正则re json csv,都有对应的serde
可以用 WITH SERDEPROPERTIES 来设定参数

### Partitioned Tables

利用partitioned by 语句可以对数据文件分区,其实就是按照partition的值细分文件夹,然后把对应的数据文件存储到文件夹中,最常见的就是按天分区.
值得注意的是partition by 指定的col不在数据文件中,他是一个虚列.如果在跑query的时候出现`FAILED: Error in semantic analysis: Column repeated in partitioning columns` 表明你即想把一个列作为分区列又想把他放在数据文件中,正确的做法是将数据列重起一个名字.

### External Tables

可以使用关键字EXTERNAL和LOCATION创建不存储在默认位置中的表，其中LOCATION指定了表存在HDFS上的位置。外部表在LOCATION已经存在数据时会派上用场，当删除一个EXTERNAL表时，表中的数据不会在文件系统删除。

### Create Table As Select (CTAS)

可以使用create-table-as-select (CTAS)语句创建表并加载查询结果到表中。该语句的操作是原子性，即直到所有查询结果被加载到表中之前，表对于其他用户是不可见的。所以其他用户要么看见带完整查询结果的表，要么根本看不见表。
CTAS有CREATE和SELECT两部分，SELECT部分可以是任何被Hive支持的select语句，CREATE采用SELECT部分的schema并且创建带有其它表属性如SerDe和存储格式的目标表。如果SELECT部分没有指定所查询列的别名，目标表的列名将自动分配为_col0, _col1, 和 _col2 等，否则按照别名命名目标表的列名。CTAS有几个限制：

1. 目标表不能是分区表
1. 目标表不能是外部表
1. 标表不能是list bucketing表

``` sql

CREATE TABLE new_key_value_store
   ROW FORMAT SERDE "org.apache.hadoop.hive.serde2.columnar.ColumnarSerDe"
   STORED AS RCFile
   AS
SELECT (key % 1024) new_key, concat(key, value) key_value_pair
FROM key_value_store
SORT BY new_key, key_value_pair;
```

### Create Table Like

``` sql
CREATE [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name
LIKE existing_table_or_view_name
[LOCATION hdfs_path];
```

like不复制数据,只复制表结构

### Bucketed Sorted Tables

```sql
CREATE TABLE page_view(viewTime INT, userid BIGINT,
     page_url STRING, referrer_url STRING,
     ip STRING COMMENT 'IP Address of the User')
 COMMENT 'This is the page view table'
 PARTITIONED BY(dt STRING, country STRING)
 CLUSTERED BY(userid) SORTED BY(viewTime) INTO 32 BUCKETS
 ROW FORMAT DELIMITED
   FIELDS TERMINATED BY '\001'
   COLLECTION ITEMS TERMINATED BY '\002'
   MAP KEYS TERMINATED BY '\003'
 STORED AS SEQUENCEFILE;
```

在上面的例子中，表page_view根据userid分桶并且在每个桶中数据按照viewTime升序排序。对表进行分桶可以在聚类列上（如userid）进行高效率的抽样，排序允许内部操作符在执行查询时利用熟悉的数据结构进而提高效率。MAP KEYS 和 COLLECTION ITEMS 关键字在列是列表或者map时使用。 CLUSTERED BY和SORTED BY不影响数据如何插入到表中，只会影响如何读取数据。这意味着必须通过指定与桶数目相同的reducer来小心正确地插入数据，并在查询时使用CLUSTER BY和SORT BY子句。
[参考创建实例](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL+BucketedTables)


### Skewed Tables
切斜表:针对某列有几种值经常出现,单独为这几种创建文件存储

``` sql
CREATE TABLE list_bucket_single (key STRING, value STRING)
  SKEWED BY (key) ON (1,5,6) [STORED AS DIRECTORIES];

CREATE TABLE list_bucket_multiple (col1 STRING, col2 int, col3 STRING)
  SKEWED BY (col1, col2) ON (('s1',1), ('s3',3), ('s13',13), ('s78',78)) [STORED AS DIRECTORIES];

```

### Temporary Tables
临时表只会在本次回话可见, 在会话结束后就会被删除

### Constraints