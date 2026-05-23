--remove duplicates
select show_id,count(*)
from net_raw
group by show_id
having count(*)>1


select * from net_raw
where concat(upper(title),type)  in (
select concat(upper(title),type) 
from net_raw
group by upper(title) ,type
having COUNT(*)>1
)
order by title

---datatype coversions for date_added 

with cte as (
select * 
, ROW_NUMBER() over(partition by title, type order by show_id) as rn 
from net_raw 
)
select show_id,type,title,cast(date_added as date) as date_added,release_year,
rating,case when duration is null then rating else duration end as duration,description
into net_stg
from cte 


select * from net_stg

--new table for listed_in,director,country,cast

select show_id , trim(value) as genre
into net_genre
from net_raw
cross apply string_split(listed_in,',')
select * from net_genre

select show_id , trim(value) as director
into net_director
from net_raw
cross apply string_split(director,',')
select * from net_director

select show_id , trim(value) as country
into net_country
from net_raw
cross apply string_split(director,',')
select * from net_country

select show_id , trim(value) as cast
into net_cast
from net_raw
cross apply string_split(director,',')
select * from net_cast




---populate rest of the nulls as not_available
---populating miss values

select * from net_raw where duration is null

select * from net_raw where director = 'Ahishor Solomon'

insert into net_country
select show_id,m.country 
from net_raw nr
inner join(
select director,country
from net_country nc
inner join net_director nd on nc.show_id = nd.show_id
group by director,country
) m on nr.director=m.director
where nr.country is null



select director,country
from net_country nc
inner join net_director nd on nc.show_id = nd.show_id
group by director,country
order by director


Data Analysis 


/*1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */

select nd.director, 
COUNT (distinct case when n.type ='Movie' then n.show_id end) as no_of_movies,
COUNT (distinct case when n.type ='Tv Show' then n.show_id end) as no_of_Tvshow
from net_stg n
inner join net_director nd on n.show_id = nd.show_id
group by nd.director
having count(distinct n.type)>1

--2 which country has highest number of comedy movies

select top 1 nc.country, COUNT(distinct ng.show_id) as no_of_movies
from net_genre ng
inner join net_country nc on ng.show_id = nc.show_id
inner join net_stg n on ng.show_id=n.show_id
where ng.genre='Comedies' and n.type='Movie'
group by nc.country
order by no_of_movies desc

--3 for each year (as per date added to netflix), which director has maximum number of movies released

with cte as (select nd.director,YEAR(date_added) as date_year,COUNT(distinct n.show_id) as no_of_movies
from net_stg n
inner join net_director nd on n.show_id = nd.show_id
where type='Movie'
group by nd.director,YEAR(date_added)
)
--order by no_of_movies desc
,cte2 as (
select *
,ROW_NUMBER() over(partition by date_year order by no_of_movies desc,director) as rn
from cte
--order by date_year,no_of_movies desc
)
select * from cte2 where rn=1

--4 what is average duration of movies in each genre

select ng.genre, avg(cast(replace(duration,' min','') AS int)) as avg_duration
from net_stg n 
inner join net_genre ng on n.show_id=ng.show_id
where type='Movie'
group by ng.genre

--5 find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them 

select nd.director
,count(distinct case when ng.genre ='Comedies' then n.show_id end) as no_of_comedy
,count(distinct case when ng.genre ='Horror Movies' then n.show_id end) as no_of_horror
from net_stg n
inner join net_genre ng on n.show_id = ng.show_id
inner join net_director nd on n.show_id = nd.show_id
where type='Movie' and ng.genre in ('Comedies','Horror Movies')
group by nd.director 
having COUNT(distinct ng.genre)=2

select * from net_genre where show_id in (
select show_id from net_director where director ='Steve Brill')
order by genre
