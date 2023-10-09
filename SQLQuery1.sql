select * from athlete_events
select * from noc_regions
-----------------------------------------------------------------------

update noc_regions
set NOC = 'SGP'
where NOC = 'SIN'
-----------------------------------------------------------------------

update athlete_events
set Medal = 0
where Medal = 'NA'
-----------------------------------------------------------------------

--1. How many olympics games have been held?

Select count(distinct Games) as No_olympic_games
from athlete_events
-----------------------------------------------------------------------

--2. List down all Olympics games held so far.

Select distinct Games as olympic_games
from athlete_events
-----------------------------------------------------------------------

--3. Mention the total no of nations who participated in each olympics game?
_
Select distinct ae.Games as games,count(n.region)  as participated_nations
from athlete_events ae
inner join noc_regions n
on ae.NOC = n.NOC
group by games
-----------------------------------------------------------------------

--4. Which year saw the highest and lowest no of countries participating in olympics
with t1 as
(select ae.Year ,count(n.region) as no_of_countries
from athlete_events ae
join noc_regions n
on ae.NOC = n.NOC
group by ae.Year
)
select Year ,no_of_countries
from t1

where
no_of_countries = (select min(no_of_countries) from t1) or
no_of_countries = (select max(no_of_countries) from t1)
-----------------------------------------------------------------------


--5. Which nation has participated in all of the olympic games

with cte as
(select n.region, count(distinct ae.Games) as no_of_games 
from noc_regions n 
join athlete_events ae
on ae.NOC = n.NOC
group by n.region ) 
SELECT
  region,
  no_of_games  
FROM (
select  region , no_of_games , dense_rank() over ( order by no_of_games desc) as max_participated_countries
from cte ) as subquery
where max_participated_countries =1
-----------------------------------------------------------------------

--6. Identify the sport which was played in all summer olympics.

select distinct Season , Sport
from athlete_events
where Season = 'Summer'
-----------------------------------------------------------------------


--7. Which Sports were just played only once in the olympics.

select sport , count(sport) as No_of_count
from athlete_events
group by sport
having count(sport) = 1
order by No_of_count
-----------------------------------------------------------------------

--8. Fetch the total no of sports played in each olympic games.

select Games , count(distinct sport) as Total_no_of_sports
from athlete_events
group by Games
-----------------------------------------------------------------------

--9. Fetch oldest athletes to win a gold medal

select *
from athlete_events
where Medal = 'Gold' and Age =
(select  max(Age) from athlete_events where Medal ='Gold' and Age != 'NA') 
-----------------------------------------------------------------------

--10. Find the Ratio of male and female athletes participated in all olympic games.

select 
sum(case when Sex = 'M' then 1 else 0 end) as No_male,
sum(case when Sex = 'F' then 1 else 0 end) as No_female,
convert(decimal(5,2),sum(case when Sex = 'M' then 1 else 0 end)*1.0/sum(case when Sex = 'F' then 1 else 0 end)) as Ratio
from athlete_events

---alternate



with t1 as
(
    select  count(*) as Male_count
    from athlete_events
    where Sex = 'M'
   
),
t2 as
(
    select count(*) as Female_count
    from athlete_events
    where Sex = 'F'
    
)

select concat(convert(decimal(5, 2), t1.Male_count * 1.0 / t2.Female_count),': 1 ') as ratio
from t1, t2;
-----------------------------------------------------------------------

--11. Fetch the top 5 athletes who have won the most gold medals.

with t1 as
(select Name , Team , count(Medal) as Total_medals
from athlete_events
where Medal = 'Gold'
group by Name ,Team 
--order by Total_medals desc
)
select Name , Team , Total_medals
from (
select Name , Team , Total_medals , dense_rank() over(order by Total_medals desc) as top_rank
from t1) t2
where t2.top_rank <6

-----------------------------------------------------------------------

--12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)?

with t1 as
(select Name , Team , count(Medal) as Total_medals
from athlete_events
--where Medal != 'NA'
group by Name ,Team 
--order by Total_medals desc
)
select Name , Team , Total_medals
from (
select Name , Team , Total_medals , dense_rank() over(order by Total_medals desc) as top_rank
from t1) t2
where t2.top_rank <=5
-----------------------------------------------------------------------

--13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

with t1 as
(select n.region as country, count(ae.Medal) as Total_medals
from athlete_events as ae
join noc_regions as n
on ae.NOC= n.NOC
--where Medal != 'NA'
group by n.region
--order by Total_medals desc
)
select country, Total_medals
from (
select country, Total_medals , dense_rank() over(order by Total_medals desc) as top_rank
from t1) t2
where t2.top_rank <6
-----------------------------------------------------------------------

--14. List down total gold, silver and bronze medals won by each country.

select n.region ,t1.Gold, t1.Silver , t1.Bronze
from 
(select NOC, 
sum(case when Medal = 'Gold' then 1 else 0 end ) as Gold,
sum(case when Medal = 'Silver' then 1 else 0 end ) as Silver,
sum(case when Medal = 'Bronze' then 1 else 0 end ) as Bronze
from athlete_events 
group by NOC
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 2 desc

-- alternate with pivot table

SELECT country,  Gold, Silver, Bronze 
FROM 
(
    SELECT n.NOC , ae.Medal , n.region as country
    FROM athlete_events AS ae
    JOIN noc_regions AS n ON ae.NOC = n.NOC
) AS source_table
PIVOT
(
    count(Medal) FOR Medal IN (Gold, Silver, Bronze) 
) AS pivotTable
ORDER BY Gold DESC, Silver DESC, Bronze DESC

-----------------------------------------------------------------------

--15. List down total gold, silver and bronze medals and Total Medals  won by each country corresponding to each olympic games.
select t1.Games,n.region ,t1.Gold, t1.Silver , t1.Bronze
from 
(select NOC,Games ,
sum(case when Medal = 'Gold' then 1 else 0 end ) as Gold,
sum(case when Medal = 'Silver' then 1 else 0 end ) as Silver,
sum(case when Medal = 'Bronze' then 1 else 0 end ) as Bronze
from athlete_events 
group by NOC,Games
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 3 desc

-----------------------------------------------------------------------

--16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.


SELECT top 1 country,  Gold, Silver, Bronze 
FROM 
(
    SELECT n.NOC , ae.Medal , n.region as country
    FROM athlete_events AS ae
    JOIN noc_regions AS n ON ae.NOC = n.NOC
) AS source_table
PIVOT
(
    count(Medal) FOR Medal IN (Gold, Silver, Bronze) 
) AS pivotTable
ORDER BY Gold DESC, Silver DESC, Bronze DESC
-----------------------------------------------------------------------


--17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.


select Top 1 t1.Games,n.region ,t1.Gold, t1.Silver , t1.Bronze , (Gold + Silver + Bronze) as Total_Medals
from 
(select NOC,Games ,
sum(case when Medal = 'Gold' then 1 else 0 end ) as Gold,
sum(case when Medal = 'Silver' then 1 else 0 end ) as Silver,
sum(case when Medal = 'Bronze' then 1 else 0 end ) as Bronze
from athlete_events 
group by NOC,Games
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 3 desc

-----------------------------------------------------------------------
-- 18. Which countries have never won gold medal but have won silver/bronze medals?

select nr.region,
SUM(CASE WHEN ae.Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN ae.Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN ae.Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from noc_regions nr
join athlete_events ae
on nr.NOC = ae.NOC
group by nr.region
having SUM(CASE WHEN ae.Medal = 'Gold' THEN 1 ELSE 0 END) = 0  
AND (SUM(CASE WHEN ae.Medal = 'Silver' THEN 1 ELSE 0 END) + SUM(CASE WHEN ae.Medal = 'Bronze' THEN 1 ELSE 0 END)) > 0

----------------------------------------------------------
--19. In which Sport/event, India has won highest medals.

select Top 1  n.region as country , ae.Sport , ae.Event , count(ae.Medal) as Total_Medal
from athlete_events ae
join noc_regions n 
on ae.NOC = n.NOC 
where n.region = 'India' and ae.Medal != '0'
GROUP BY n.region,ae.Sport , ae.Event 
order by count(ae.Medal) desc

----------------------------------------------------------

--20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

select  n.region as country , ae.Sport ,ae.Event, ae.Games , count(ae.Medal) as Total_Medal
from athlete_events ae
join noc_regions n 
on ae.NOC = n.NOC 
where n.region = 'India' and ae.Medal != '0'
GROUP BY n.region,ae.Sport , ae.Games , ae.Event
order by count(ae.Medal) desc
