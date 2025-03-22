--GOALS Table
CREATE TABLE goals (
    goal_id VARCHAR(255) PRIMARY KEY, 
    match_id VARCHAR(255) ,  
    pid VARCHAR(255) ,       
    duration INTEGER ,      
    assist VARCHAR(255),         
    goal_desc VARCHAR(255)    
);

-- MATCHES table
CREATE TABLE matches (
    match_id VARCHAR(255) PRIMARY KEY,    
    season VARCHAR(255) ,         
    date DATE ,                   
    home_team VARCHAR(255) ,      
    away_team VARCHAR(255) ,      
    stadium VARCHAR(255) ,        
    home_team_score INTEGER ,     
    away_team_score INTEGER ,     
    penalty_shoot_out BOOLEAN ,   
    attendance INTEGER                    
);

--PLAYERS Table
CREATE TABLE players (
    player_id VARCHAR(255) PRIMARY KEY,    
    first_name VARCHAR(255) ,       
    last_name VARCHAR(255) ,        
    nationality VARCHAR(255) ,     
    dob DATE ,                      
    team VARCHAR(255) ,            
    jersey_number REAL ,            
    position VARCHAR(255) ,        
    height REAL,                           
    weight REAL,                            
    foot VARCHAR(1)                
);

--TEAMS Table
CREATE TABLE teams (
    team_name VARCHAR(255) PRIMARY KEY,   
    country VARCHAR(255) ,        
    home_stadium VARCHAR(255) 
);

--STADIUMS Table
CREATE TABLE stadiums (
    name VARCHAR(255),    
    city VARCHAR(255)  ,      
    country VARCHAR(255) ,    
    capacity INTEGER          
);

-- Imported the data into each table 

-- Goal Analysis (From the Goals table)
--(1)Which player scored the most goals in a each season?
WITH player_goal_count AS (
    SELECT p.first_name || ' ' || p.last_name AS player_name,m.season,
        COUNT(g.goal_id) AS total_goals,
        ROW_NUMBER() OVER (PARTITION BY m.season ORDER BY COUNT(g.goal_id) DESC) AS rank
    FROM goals g
    JOIN players p ON g.pid = p.player_id
    JOIN matches m ON g.match_id = m.match_id
    GROUP BY p.first_name, p.last_name, m.season
)
SELECT player_name, season, total_goals
FROM player_goal_count
WHERE rank = 1
ORDER BY season;

--(2)How many goals did each player score in a given season?
SELECT p.first_name || ' ' || p.last_name AS player_name, m.season, 
    COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN players p ON g.pid = p.player_id
JOIN matches m ON g.match_id = m.match_id
WHERE m.season = '2016-2017'  			-- Here, 2016-2017 season
GROUP BY p.first_name, p.last_name, m.season
ORDER BY total_goals DESC;

--(3)What is the total number of goals scored in ‘mt403’ match?
SELECT COUNT(goal_id) AS total_goals
	FROM goals
	WHERE match_id = 'mt403';

--(4)Which player assisted the most goals in a each season?
SELECT p.first_name || ' ' || p.last_name AS player_name, m.season, 
    COUNT(g.assist) AS total_assists
	FROM goals g
	JOIN players p ON g.assist = p.player_id
	JOIN matches m ON g.match_id = m.match_id
	GROUP BY p.first_name, p.last_name, m.season
	ORDER BY m.season, total_assists DESC;

--(5)Which players have scored goals in more than 10 matches?
SELECT p.first_name || ' ' || p.last_name AS player_name, 
    COUNT(DISTINCT g.match_id) AS matches_scored
 	FROM goals g
	JOIN players p ON g.pid = p.player_id
	GROUP BY p.first_name, p.last_name
	HAVING COUNT(DISTINCT g.match_id) > 10
	ORDER BY matches_scored DESC;

--(6)What is the average number of goals scored per match in a given season?
SELECT m.season, 
    ROUND(SUM(m.home_team_score + m.away_team_score)::NUMERIC / COUNT(m.match_id), 2) AS avg_goals_per_match
	FROM matches m
	GROUP BY m.season
	ORDER BY m.season;

--(7)Which player has the most goals in a single match?
WITH player_match_goals AS (
    SELECT g.pid AS player_id, g.match_id, COUNT(g.goal_id) AS goals_in_match
    	FROM goals g
    	GROUP BY g.pid, g.match_id
		), 
	ranked_players AS (
    SELECT p.player_id, p.first_name || ' ' || p.last_name AS player_name, pm.match_id, pm.goals_in_match,
       ROW_NUMBER() OVER (ORDER BY pm.goals_in_match DESC) AS rank
    	FROM player_match_goals pm
    	JOIN players p ON pm.player_id = p.player_id
		)
SELECT player_name, match_id, goals_in_match
FROM ranked_players
WHERE rank = 1;

--(8)Which team scored the most goals in the all seasons?
WITH team_goals AS (
    SELECT m.home_team AS team, SUM(m.home_team_score) AS total_home_goals
    FROM matches m
    GROUP BY m.home_team
    UNION ALL
    SELECT m.away_team AS team, SUM(m.away_team_score) AS total_away_goals
    FROM matches m
    GROUP BY m.away_team
)
SELECT team, SUM(total_home_goals) AS total_goals
FROM team_goals
GROUP BY team
ORDER BY total_goals DESC LIMIT 1;


--(9)Which stadium hosted the most goals scored in a single season?
WITH stadium_goals AS (
    SELECT m.stadium, m.season, 
        SUM(m.home_team_score + m.away_team_score) AS total_goals
    FROM matches m
    GROUP BY m.stadium, m.season
	), 
	ranked_stadiums AS (
    SELECT stadium, season, total_goals,
        ROW_NUMBER() OVER (PARTITION BY season ORDER BY total_goals DESC) AS rank
    FROM stadium_goals
	)
SELECT stadium, season, total_goals
FROM ranked_stadiums
WHERE rank = 1;

--Match Analysis (From the Matches table)
--(10)What was the highest-scoring match in a particular season?
SELECT m.match_id, m.season, m.home_team, m.away_team,m.home_team_score, m.away_team_score, 
    (m.home_team_score + m.away_team_score) AS total_goals
FROM matches m
WHERE m.season = '2021-2022'				--Here, 2021-2022 season
ORDER BY total_goals DESC LIMIT 1;

--(11)How many matches ended in a draw in a given season?
SELECT COUNT(*) AS draw_matches
FROM matches m
WHERE m.season = '2021-2022' AND m.home_team_score = m.away_team_score;

--(12)Which team had the highest average score (home and away) in the season 2021-2022?
WITH team_avg_score AS (
    SELECT m.season,m.home_team AS team,AVG(m.home_team_score) AS avg_home_score,
        0 AS avg_away_score
    FROM matches m
    WHERE m.season = '2021-2022'
    GROUP BY m.season, m.home_team
    UNION ALL
    SELECT m.season,m.away_team AS team,0 AS avg_home_score,
        AVG(m.away_team_score) AS avg_away_score
    FROM matches m
    WHERE m.season = '2021-2022'
    GROUP BY m.season, m.away_team
)
SELECT team, ROUND(AVG(avg_home_score + avg_away_score), 2) AS avg_total_score
FROM team_avg_score
GROUP BY team
ORDER BY avg_total_score DESC LIMIT 1;


--(13)How many penalty shootouts occurred in a each season?
SELECT m.season, COUNT(*) AS penalty_shootouts
FROM matches m
WHERE m.penalty_shoot_out = TRUE
GROUP BY m.season
ORDER BY m.season;

--(14)What is the average attendance for home teams in the 2021-2022 season?
SELECT m.home_team, ROUND(AVG(m.attendance), 2) AS avg_attendance
FROM matches m
WHERE m.season = '2021-2022'
GROUP BY m.home_team
ORDER BY avg_attendance DESC;

--(15)Which stadium hosted the most matches in a each season?
WITH stadium_match_count AS (
    SELECT m.season,m.stadium,COUNT(*) AS match_count,
        ROW_NUMBER() OVER (PARTITION BY m.season ORDER BY COUNT(*) DESC) AS rn
    FROM matches m
    GROUP BY m.season, m.stadium
)
SELECT season,stadium,match_count
FROM stadium_match_count
WHERE rn = 1
ORDER BY season;


--(16)What is the distribution of matches played in different countries in a season?
SELECT s.country, COUNT(m.match_id) AS matches_played
FROM matches m
JOIN stadiums s ON m.stadium = s.name
WHERE m.season = '2021-2022' 			--Here season 2021-2022
GROUP BY s.country
ORDER BY matches_played DESC;

--(17)What was the most common result in matches (home win, away win, draw)?
SELECT result_type, COUNT(*) AS result_count
FROM (SELECT 
        CASE 
            WHEN m.home_team_score > m.away_team_score THEN 'Home Win'
            WHEN m.home_team_score < m.away_team_score THEN 'Away Win'
            ELSE 'Draw'
        END AS result_type
    FROM matches m
) results
GROUP BY result_type
ORDER BY result_count DESC LIMIT 1;

--Player Analysis (From the Players table)
--(18)Which players have the highest total goals scored (including assists)?
SELECT g.pid AS player_id,p.first_name || ' ' || p.last_name AS player_name,
    COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN players p ON g.pid = p.player_id
GROUP BY g.pid, p.first_name, p.last_name
ORDER BY total_goals DESC LIMIT 1;

--(19)What is the average height and weight of players per position?
SELECT position, 
    ROUND(AVG(height)::numeric, 2) AS avg_height,
    ROUND(AVG(weight)::numeric, 2) AS avg_weight
FROM players
GROUP BY position
ORDER BY position;

--(20)Which player has the most goals scored with their left foot?
SELECT g.pid AS player_id,p.first_name || ' ' || p.last_name AS player_name,
    COUNT(g.goal_id) AS left_foot_goals
FROM goals g
JOIN players p ON g.pid = p.player_id
WHERE p.foot = 'L'
GROUP BY g.pid, p.first_name, p.last_name
ORDER BY left_foot_goals DESC LIMIT 1;

--(21)What is the average age of players per team?
SELECT team, ROUND(AVG(EXTRACT(YEAR FROM AGE(dob))), 2) AS avg_age
FROM players
GROUP BY team
ORDER BY avg_age DESC;

--(22)How many players are listed as playing for a each team in a season?
SELECT p.team, COUNT(p.player_id) AS player_count
FROM players p
JOIN goals g ON p.player_id = g.pid
JOIN matches m ON g.match_id = m.match_id
WHERE m.season = '2021-2022'  -- Replace with the season you're interested in
GROUP BY p.team
ORDER BY player_count DESC;

--(23)Which player has played in the most matches in the each season?
WITH player_match_count AS (
    SELECT g.pid AS player_id,COUNT(DISTINCT g.match_id) AS match_count,m.season
    FROM goals g
    JOIN matches m ON g.match_id = m.match_id
    GROUP BY g.pid, m.season
)
SELECT player_id, match_count, season
FROM player_match_count
WHERE (season, match_count) IN (
        SELECT season, MAX(match_count)
        FROM player_match_count
        GROUP BY season
    )ORDER BY season;

--(24)What is the most common position for players across all teams?
SELECT position, COUNT(*) AS position_count
FROM players
GROUP BY position
ORDER BY position_count DESC LIMIT 1;

--(25)Which players have never scored a goal?
SELECT p.player_id, p.first_name || ' ' || p.last_name AS player_name
FROM players p
LEFT JOIN goals g ON p.player_id = g.pid
WHERE g.goal_id IS NULL;

--Team Analysis (From the Teams table)
--(26)Which team has the largest home stadium in terms of capacity?
SELECT t.team_name, s.name AS stadium_name, s.capacity
FROM teams t
JOIN stadiums s ON t.home_stadium = s.name
ORDER BY s.capacity DESC LIMIT 1;

--(27)Which teams from a each country participated in the UEFA competition in a season?
SELECT m.season, t.team_name, t.country
FROM teams t
JOIN matches m ON t.team_name = m.home_team OR t.team_name = m.away_team
WHERE m.season = '2021-2022'  		-- Here, season 2021-2022
GROUP BY m.season, t.team_name, t.country
ORDER BY t.country, t.team_name;

--(28)Which team scored the most goals across home and away matches in a given season?
SELECT team, SUM(home_goals + away_goals) AS total_goals
FROM (
    SELECT home_team AS team,home_team_score AS home_goals,away_team_score AS away_goals
    FROM matches
    WHERE season = '2021-2022'  -- Replace with the season you're interested in
    UNION ALL
    SELECT away_team AS team,away_team_score AS home_goals,home_team_score AS away_goals
    FROM matches
    WHERE season = '2021-2022'  -- Replace with the season you're interested in
) AS goals
GROUP BY team
ORDER BY total_goals DESC LIMIT 1;

--(29)How many teams have home stadiums in a each city or country?
SELECT city, COUNT(DISTINCT team_name) AS team_count
FROM teams t
JOIN stadiums s ON t.home_stadium = s.name
GROUP BY city
ORDER BY team_count DESC;

--(30)Which teams had the most home wins in the 2021-2022 season?
SELECT home_team, COUNT(*) AS home_wins
FROM matches
WHERE season = '2021-2022'  
    AND home_team_score > away_team_score
GROUP BY home_team
ORDER BY home_wins DESC LIMIT 1;

--Stadium Analysis (From the Stadiums table)
--(31)Which stadium has the highest capacity?
SELECT name AS stadium_name, capacity
FROM stadiums
ORDER BY capacity DESC LIMIT 1;

--(32)How many stadiums are located in a ‘Russia’ country or ‘London’ city?
SELECT  COUNT(*) AS stadium_count
FROM stadiums
WHERE country = 'Russia' OR city = 'London';

--(33)Which stadium hosted the most matches during a season?
SELECT stadium, COUNT(*) AS match_count
FROM matches
WHERE season = '2021-2022'  -- Here 2021-2022 season
GROUP BY stadium
ORDER BY match_count DESC LIMIT 1;

--(34)What is the average stadium capacity for teams participating in a each season?
SELECT m.season, AVG(s.capacity) AS avg_stadium_capacity
FROM matches m
JOIN teams t ON m.home_team = t.team_name OR m.away_team = t.team_name
JOIN stadiums s ON t.home_stadium = s.name
GROUP BY m.season
ORDER BY m.season;

--(35)How many teams play in stadiums with a capacity of more than 50,000?
SELECT COUNT(DISTINCT team_name) AS team_count
FROM teams t
JOIN stadiums s ON t.home_stadium = s.name
WHERE s.capacity > 50000;

--(36)Which stadium had the highest attendance on average during a season?
SELECT s.name AS stadium_name,  AVG(m.attendance) AS avg_attendance
FROM matches m
JOIN stadiums s ON m.stadium = s.name
WHERE m.season = '2021-2022'  -- Replace with the season you're interested in
GROUP BY s.name
ORDER BY avg_attendance DESC LIMIT 1;

--(37)What is the distribution of stadium capacities by country?
SELECT s.country, AVG(s.capacity) AS avg_stadium_capacity
FROM stadiums s
GROUP BY s.country
ORDER BY avg_stadium_capacity DESC;

--Cross-Table Analysis (Combining multiple tables)
--(38)Which players scored the most goals in matches held at a specific stadium?
SELECT g.pid AS player_id, COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
WHERE m.stadium = 'Giuseppe Meazza'  	-- Here Giuseppe Meazza Stadium
GROUP BY g.pid
ORDER BY total_goals DESC LIMIT 1;

-- More stadium names
select name from stadiums;

--(39)Which team won the most home matches in the season 2021-2022 (based on match scores)?
SELECT home_team, COUNT(*) AS home_wins
FROM matches
WHERE season = '2021-2022' AND home_team_score > away_team_score
GROUP BY home_team
ORDER BY home_wins DESC LIMIT 1;

--(40)Which players played for a team that scored the most goals in the 2021-2022 season?
WITH team_goals AS (
    SELECT home_team AS team, SUM(home_team_score) + SUM(away_team_score) AS total_goals
    FROM matches
    WHERE season = '2021-2022'
    GROUP BY home_team
    ORDER BY total_goals DESC
    LIMIT 1
)
SELECT p.first_name, p.last_name, p.team
FROM players p
JOIN team_goals tg ON p.team = tg.team;

--(41)How many goals were scored by home teams in matches where the attendance was above 50,000?
SELECT SUM(home_team_score) AS total_goals
FROM matches
WHERE attendance > 50000;

--(42)Which players played in matches where the score difference (home team score - away team score) was the highest?
WITH max_score_diff AS (
    SELECT match_id, home_team_score - away_team_score AS score_diff
    FROM matches
    ORDER BY score_diff DESC LIMIT 1
	)
SELECT g.pid AS player_id, COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN max_score_diff msd ON g.match_id = msd.match_id
GROUP BY g.pid
ORDER BY total_goals DESC;

--(43)How many goals did players score in matches that ended in penalty shootouts?
SELECT g.pid AS player_id, COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
WHERE m.penalty_shoot_out = TRUE
GROUP BY g.pid;
--Penlaty shoot outs is false for each row so no output
--Select penalty_shoot_out from matches;

--(44)What is the distribution of home team wins vs away team wins by country for all seasons?
SELECT m.season, t.country, 
    SUM(CASE WHEN m.home_team_score > m.away_team_score THEN 1 ELSE 0 END) AS home_team_wins,
    SUM(CASE WHEN m.away_team_score > m.home_team_score THEN 1 ELSE 0 END) AS away_team_wins
FROM matches m
JOIN teams t ON m.home_team = t.team_name OR m.away_team = t.team_name
GROUP BY m.season, t.country
ORDER BY m.season;

--(45)Which team scored the most goals in the highest-attended matches?
WITH max_attendance_matches AS (
    SELECT match_id
    FROM matches
    WHERE attendance = (SELECT MAX(attendance) FROM matches)
)
SELECT m.home_team AS team, SUM(m.home_team_score) AS total_goals
FROM matches m
JOIN max_attendance_matches mam ON m.match_id = mam.match_id
GROUP BY m.home_team
ORDER BY total_goals DESC LIMIT 1;

--(46)Which players assisted the most goals in matches where their team lost(you can include 3)?
SELECT g.assist AS player_id, COUNT(g.goal_id) AS total_assists
FROM goals g
JOIN matches m ON g.match_id = m.match_id
WHERE ((m.home_team = g.assist AND m.home_team_score < m.away_team_score) 
     OR (m.away_team = g.assist AND m.away_team_score < m.home_team_score))
GROUP BY g.assist
ORDER BY total_assists DESC LIMIT 3;

--(47)What is the total number of goals scored by players who are positioned as defenders?
SELECT SUM(g.duration) AS total_goals
FROM goals g
JOIN players p ON g.pid = p.player_id
WHERE p.position = 'Defender';

--(48)Which players scored goals in matches that were held in stadiums with a capacity over 60,000?
SELECT g.pid AS player_id, COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
JOIN stadiums s ON m.stadium = s.name
WHERE s.capacity > 60000
GROUP BY g.pid;

--(49)How many goals were scored in matches played in cities with specific stadiums in a season?
SELECT SUM(m.home_team_score + m.away_team_score) AS total_goals
FROM matches m
JOIN stadiums s ON m.stadium = s.name
WHERE s.city = 'Amsterdam' 				-- Any city from stadium table
    AND m.season = '2021-2022';  		-- Here season 2021-2022
--select city from stadiums;

--(50)Which players scored goals in matches with the highest attendance (over 100,000)?
SELECT g.pid AS player_id, COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
WHERE m.attendance > 100000
GROUP BY g.pid
ORDER BY total_goals DESC;     		--No attandance>100000
--select attendance from matches where attendance>100000;

--Additional Complex Queries (Combining multiple aspects)
--(51)What is the average number of goals scored by each team in the first 30 minutes of a match?
SELECT m.home_team AS team, 
    ROUND(AVG(CASE WHEN g.duration <= 30 THEN 1 ELSE 0 END), 2) AS avg_goals_first_30
FROM matches m
LEFT JOIN goals g ON m.match_id = g.match_id
GROUP BY m.home_team
UNION ALL
SELECT m.away_team AS team, 
    ROUND(AVG(CASE WHEN g.duration <= 30 THEN 1 ELSE 0 END), 2) AS avg_goals_first_30
FROM matches m
LEFT JOIN goals g ON m.match_id = g.match_id
GROUP BY m.away_team
ORDER BY avg_goals_first_30 DESC;

--(52)Which stadium had the highest average score difference between home and away teams?
SELECT m.stadium,ROUND(AVG(ABS(m.home_team_score - m.away_team_score)), 2) AS avg_score_diff
FROM matches m
GROUP BY m.stadium
ORDER BY avg_score_diff DESC LIMIT 1;

--(53)How many players scored in every match they played during a given season?
SELECT p.player_id, COUNT(DISTINCT m.match_id) AS total_matches,
    COUNT(DISTINCT g.match_id) AS matches_scored_in
FROM players p
JOIN matches m ON m.season = '2020-2021' -- specify the season
LEFT JOIN goals g ON g.pid = p.player_id AND g.match_id = m.match_id
GROUP BY p.player_id
HAVING COUNT(DISTINCT m.match_id) = COUNT(DISTINCT g.match_id);

--(54)Which teams won the most matches with a goal difference of 3 or more in the 2021-2022 season?
SELECT team, COUNT(match_id) AS win_count
FROM 
    (
        SELECT m.home_team AS team,m.home_team_score - m.away_team_score AS score_diff, 
            m.match_id
        FROM matches m
        WHERE m.season = '2021-2022' AND m.home_team_score - m.away_team_score >= 3
        UNION ALL
        SELECT m.away_team AS team,m.away_team_score - m.home_team_score AS score_diff, 
            m.match_id
        FROM matches m
        WHERE m.season = '2021-2022' AND m.away_team_score - m.home_team_score >= 3
    ) AS winning_matches
GROUP BY team
ORDER BY win_count DESC LIMIT 1;

--(55)Which player from a specific country has the highest goals per match ratio?
SELECT p.player_id,
    ROUND(COUNT(g.goal_id) * 1.0 / COUNT(DISTINCT m.match_id), 2) AS goals_per_match_ratio
FROM players p
JOIN goals g ON p.player_id = g.pid
JOIN matches m ON g.match_id = m.match_id
WHERE p.nationality = 'Brazil'  				-- Here country Brazil
GROUP BY p.player_id
ORDER BY goals_per_match_ratio DESC LIMIT 1;
