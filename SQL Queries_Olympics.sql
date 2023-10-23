
->Teams has won the maximum gold medals over the years.

SELECT TOP 1 team,
           COUNT(DISTINCT event) AS total_cnt
FROM Athletes a
LEFT JOIN Athlete_events ae ON a.id = ae.athlete_id
WHERE medal = 'Gold'
GROUP BY team
ORDER BY total_cnt DESC ;

->Teams peak years for winning silver medals are revealed, offering insights into their historical performances
           
WITH cte AS
  (SELECT a.team,
          ae.year,
          count(DISTINCT event) AS silver_medals,
          rank() over(PARTITION BY team
                      ORDER BY count(DISTINCT event) DESC) AS rn
   FROM athlete_events ae
   INNER JOIN athletes a ON ae.athlete_id=a.id
   WHERE medal='Silver'
   GROUP BY a.team,
            ae.year)
SELECT team,
       sum(silver_medals) AS total_silver_medals,
       max(CASE
               WHEN rn=1 THEN YEAR
           END) AS year_of_max_silver
FROM cte
GROUP BY team;

 -> Player has won maximum gold medals  amongst the players which have won only gold medal (never won silver or bronze) over the years

WITH cte AS
  (SELECT name,
          medal
   FROM athlete_events ae
   INNER JOIN athletes a ON ae.athlete_id = a.id)
SELECT name,
       COUNT(1) AS no_of_gold_medals
FROM cte
WHERE name NOT IN
    (SELECT DISTINCT name
     FROM cte
     WHERE medal IN ('Silver',
                     'Bronze'))
  AND medal = 'Gold'
GROUP BY name
ORDER BY no_of_gold_medals DESC;

-> Each year which player has won maximum gold medal .Print year,player name and no of golds won in that year . In case of a tie print comma separated player names.

WITH CTE AS
  (SELECT name,
          YEAR,
          COUNT(1) AS total
   FROM Athletes a
   LEFT JOIN Athlete_events ae ON a.id = ae.athlete_id
   WHERE medal = 'gold'
   GROUP BY YEAR,
            name),
     CTE1 AS
  (SELECT *,
          DENSE_RANK() OVER(PARTITION BY YEAR
                            ORDER BY total DESC) AS RNK
   FROM CTE)
SELECT YEAR,
       total,
       STRING_AGG(name, ',') AS players
FROM CTE1
WHERE RNK = 1
GROUP BY YEAR,
         total ;

-> In which event and year India has won its first gold medal,first silver medal and first bronze medal
           
WITH CTE AS
  (SELECT medal,
          YEAR,
          sport
   FROM Athletes A
   LEFT JOIN Athlete_events AE ON A.id = AE.athlete_id
   WHERE A.team= 'India'
   GROUP BY ae.medal,
            YEAR,
            sport)
SELECT *
FROM
  (SELECT *,
          RANK() OVER (PARTITION BY Medal
                       ORDER BY YEAR) AS rnk
   FROM cte) A
WHERE rnk = 1
  AND NOT medal = 'NA';


-> Players who won gold medal in summer and winter olympics both.

-----------------------
SELECT a.name
FROM Athletes A
LEFT JOIN Athlete_events AE ON A.id = AE.athlete_id
WHERE (medal= 'Gold'
       AND (season= 'summer'))
  OR (medal= 'Gold'
      AND (season= 'winter'))
GROUP BY name
HAVING COUNT(DISTINCT season)=2

-> Players who won gold, silver and bronze medal in a single olympics.
-------------------------------
SELECT name,
       YEAR
FROM Athlete_events AE
LEFT JOIN Athletes A ON AE.athlete_id = A.id
WHERE medal IN ('Gold',
                'Silver',
                'Bronze')
GROUP BY name,
         YEAR
HAVING COUNT(DISTINCT MEDAL) = 3
ORDER BY name,
         YEAR ;


-> Players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. Assume summer olympics happens every 4 year starting 2000. print player name and event name.

WITH CTE AS
  (SELECT name,
          event,
          YEAR
   FROM Athlete_events ae
   LEFT JOIN Athletes a ON a.id = ae.athlete_id
   WHERE YEAR >= 2000
     AND season= 'summer'
     AND medal = 'Gold'
   GROUP BY name,
            event,
            YEAR)
SELECT *
FROM
  (SELECT *,
          LAG(YEAR, 1) over(PARTITION BY name, event
                            ORDER BY YEAR) AS last_yr,
          LEAD(YEAR, 1) over(PARTITION BY name, event
                             ORDER BY YEAR) AS next_yr
   FROM CTE) A
WHERE YEAR = last_yr + 4
  AND YEAR = next_yr - 4 ;
