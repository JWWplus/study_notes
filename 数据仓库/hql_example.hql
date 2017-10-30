create external table `movies`(
    MovieID int,
    YearOfRelease string,
    Title string
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

create external table `moives_part`(
    MovieID int,
    Title string
)
partitioned by (YearOfRelease string)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

insert overwrite table `moives_part` partition (YearOfRelease)
select
    MovieID,
    Title,
    YearOfRelease
from movies;

select
    *
from movie_info a
left join train_data b
on a.MovieID = b.MovieID 
limit 10;

select
    custormer,
    case rating when 5 then "A"
          when 4 then "B"
          when 3 then "C"
          when 2 then "D"
          when 1 then "E"
    end as rate
from train_data limit 30; 

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


create external table `train_data_orc`(
    id int,
    MovieID int,
    custormer int,
    rating string,
    data string
)
STORED AS ORC;

insert overwrite table `train_data_orc`
select
    id, 
    MovieID,
    custormer, 
    rating, 
    data
from train_data; 

select MovieID, avg(rating) as avgs
from train_data_orc
group by 1 
order by avgs desc
limit 10;