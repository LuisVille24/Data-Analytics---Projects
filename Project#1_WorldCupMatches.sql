/*
NAME: LUIS VILLENEUVE
DATE: 2024/03/06

The following SQL exploration done in SQL SERVER 2019 delves into the FIFA archive website's extensive data, providing a detailed overview of every Men's FIFA World 
Cup event up until and including 2014.

The primary aim is to extract deeper insigths into the World Cup as a whole. This includes identifying influential teams, understanding which
nations have won the cup and how often, analyzing the impact of hosting the cup on a nation's chances of winning, and focusing on the most
successful nation to comprehend its influence. Additionally, I'll examine the goal-scoring trend per World Cup, determining whether the 
number of goals is on the rise or decline. 

Before importing the three available CSV files (WorldCupMatches, WorldCupPlayers, and WorldCupsLocations), a meticulous ETL process was executed.
This involved uploading the files to Excel for necessary cleaning and pre-screening. Actions such as removing duplicates, rectifying formatting
errors (often stemming from special characters), renaming columns, and dropping irrelevant or largely empty columns were carried out to streamline
the data. For instance, information regarding match assistants, deemed non-essential for analysis, was omitted. 

LINK to DATA: https://www.kaggle.com/datasets/abecklas/fifa-world-cup/data
*/


-- Q: Goals Scored 

SELECT
	Year, 
	Country, 
	GoalsScored, 
	AverageGoalsScored = AVG(GoalsScored) OVER(), 
	Actual_vs_Average = ROUND(CAST(GoalsScored AS FLOAT)/ AVG(CAST(GoalsScored AS FLOAT)) OVER(),2),
	DeviationInPercentage = ABS(ROUND(100 - CAST(GoalsScored AS FLOAT)/ AVG(CAST(GoalsScored AS FLOAT)) OVER() * 100,2)) -- Ever since 1994 goal_scoring has been above the average by approximately 20%
	-- lowest deviation from average occurred in 1990 and the highest in both, 1998 adn 2014
	
FROM WorldCupsLocation
ORDER BY Year

-- A: FROM 1930-2014, there was an average of 118 goals scored per edition
-- A: The lowest deviation from the average occurred in 1990 in Italy with 115 goals scored which resulted in a 3.32% deviation from the Average. 
-- A: The highest deviation is a tie between the 1998 edition in France and the 2014 edition in Brazil. Both amount to a total of 171 goals which was approximately 44% above average. 
-- A: Ever since 1994, the total number of goals scored per edition surpasses the Average by at least 18%. 


-- Q: Which country won the most World Cups? What years did they win? 
SELECT 
	Year,
	Winner,
	TotalWins = ROW_NUMBER() OVER(PARTITION BY Winner ORDER BY Year)

FROM WorldCupsLocation 

-- A: Brazil is the winner with 5 World Cups: 1958, 1962, 1970, 1994, 2002. 
-- A: Only 8 Unique countries have managed to win an edition. 


-- Q: How many Distinct Hosts?
SELECT Unique_Hosts = COUNT(DISTINCT(Country))

FROM WorldCupsLocation; 

-- A: 15 countries have hosted the World Cup. Some have hosted twice. 


-- Q: From the WC winners, Which countries scored the most goals?
SELECT
	Country, 
	SUM(GoalsScored) AS TotalGoalsScored

FROM WorldCupsLocation
GROUP BY Country
ORDER BY SUM(GoalsScored) DESC 

-- A: Brazil has the most and Uruguay the least goals accumulated accross all World Cup editions.


-- Q: How Many Host Nations have managed to Win the World Cup at home? How is that compared to the total number of World Cup Editions? 
WITH Host AS(
SELECT Year, Country, Winner
FROM WorldCupsLocation
WHERE Country = Winner
)


SELECT
	Year,
	Country, 
	Winner,
	Host_Winning = (SELECT COUNT(*) FROM Host),
	TotalWCs = (SELECT COUNT(*) FROM WorldCupsLocation),
	Probability =CAST((SELECT COUNT(*) FROM Host) AS FLOAT) / CAST((SELECT COUNT(*) FROM WorldCupsLocation) AS FLOAT)

FROM Host

-- A: Up until 2014, there were a total of 20 World Cup Editions
-- A: 5 host nations managed to win the trophy in front of its citizens. These countries include: Uruguay, Italy, England, Argentina & France





-- Q: What Countries have consistently made it to top 4? (semi-final round)

SELECT CountryName, COUNT(*) AS TotalOccurrences
FROM (
    SELECT Winner AS CountryName FROM WorldCupsLocation
    UNION ALL
    SELECT Runners_Up AS CountryName FROM WorldCupsLocation
    UNION ALL
    SELECT Third AS CountryName FROM WorldCupsLocation
    UNION ALL
    SELECT Fourth AS CountryName FROM WorldCupsLocation
) AS AllPlaces
WHERE CountryName IS NOT NULL
GROUP BY CountryName
ORDER BY COUNT(*) DESC

-- A: Brazil, Germany, Italy are the top 3. 

/*

Primary Key of Interest: MatchID
INNER JOINED WorldCupPlayers to WorldCupMatches to get a detailed/full picture of those involved in each match(MatchID).
Created a TEMP table to store the following query to be later referenced
 */

SELECT
	Year = YEAR(Datetime),
	Stage,
	HomeTeamName,
	HomeTeamGoals, 
	AwayTeamGoals,
	AwayTeamName, 
	Referee, 
	A.MatchID, 
	Coach_Name, 
	Player_Name

INTO #WCMatchSummary -- Temp Table
FROM FIFAWC.dbo.WorldCupMatches A
	INNER JOIN FIFAWC.dbo.WorldCupPlayers B on A.MatchID = B.MatchID



-- Deeper investigation into BRAZIL. Attempt to investigate its World Cup numbers. 
SELECT
	DISTINCT(Year), 
	HomeTeamName, 
	AwayTeamName

INTO #BRAZIL
FROM #WCMatchSummary
WHERE HomeTeamName = 'Brazil' or AwayTeamName = 'Brazil'


-- Q: How many matches has Brazil played and how many world cups was Brazil a part of?
SELECT 
	Year, HomeTeamName, AwayTeamName,
	COUNT(Year) OVER() AS TotalWCMatches, -- 101 matches
	DENSE_RANK() OVER(ORDER BY Year) AS NumberOfParticipations -- Brazil completed its 20th participation in 2014. Up until 2014, Brazil was present in every World Cup Event. 

FROM #BRAZIL;

-- A: Brazil played a total of 101 World Cup Matches
-- A: Brazil participated in 20 World Cups. Since there have been 20 editions, Brazil participated in every single World Cup edition. 


-- Q: How Many Goals did Brazil score per edition? How Many Goals did Brazil Concede?
With Goal_Summary AS(
SELECT 
	Year(Datetime) AS WorldCupYear, 
	HomeTeamName, 
	AwayTeamName, 
	HomeTeamGoals, 
	AwayTeamGoals,
	ScoredGoals = CASE
					WHEN HomeTeamName = 'Brazil' THEN HomeTeamGoals
					WHEN AwayTeamName = 'Brazil' THEN AwayTeamGoals
					ELSE 0 END,

	ConcededGoals = CASE
						WHEN HomeTeamName = 'Brazil' THEN AwayTeamGoals
						WHEN AwayTeamName = 'Brazil' THEN HomeTeamGoals
						ELSE 0 END
FROM WorldCupMatches
WHERE HomeTeamName = 'Brazil' or AwayTeamName = 'Brazil')


-- Grouping ScoredGoals and ConcededGoals
SELECT 
	WorldCupYear, 
	SUM(ScoredGoals) AS TotalGoalsScored,
	SUM(ConcededGoals) AS TotalGoalsConceded

FROM Goal_Summary 
GROUP BY WorldCupYear
ORDER BY WorldCupYear



-- A: Brazil's highest goalscoring editon was the 1950 edition with 22 goals scored. Their worst edition was in 1934 with just 1 goal scored. 
-- A: Brazil conceded the most in 2014 (total of 14 goals). This comes to surprise at all to all Soccer fans since in 2014 Brazil lost 7x1 to Germany. On the other hand, they conceded the least in 1986 (only 1 goal). 


DROP TABLE #WCMatchSummary
DROP TABLE #BRAZIL

/*

CONCLUSION: 
	
	By analyzing various aspects such as goal scoring trends, World Cup winners, host nations, and Brazil's performance, we
	gained a comprehensive understanding of the tournament's dynamics. 

	The analysis revealed that the average number of goals scored per World Cup edition has been consistently above the historical
	average since 1994. Notably, the 1998 and 2014 editions saw a significant increase in goal scoring, with Brazil being the
	highest scoring team across all editions. 

	Brazil emerged as the most succesful nation in the tournament's history, winning the World Cup five times. They've participated 
	in every World Cup edition up to 2014, playing a total of 101 matches and scoring the most goals in several editions. Additionally,
	we observed that hosting the World Cup did not guarantee success for the host nation, with only five host nations managing to 
	win the trophy on home soil. 

	Overal, this SQL exploration was succesful in shedding light on the performances of different nations and the factors influencing
	tournament outcomes. 
	
	



*/
