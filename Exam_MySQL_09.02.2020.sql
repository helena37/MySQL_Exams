-- Table Design --
CREATE TABLE countries
(
    id   INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(45) NOT NULL
);

CREATE TABLE skills_data
(
    id        INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    dribbling INT DEFAULT 0,
    pace      INT DEFAULT 0,
    passing   INT DEFAULT 0,
    shooting  INT DEFAULT 0,
    speed     INT DEFAULT 0,
    strength  INT DEFAULT 0
);

CREATE TABLE towns
(
    id         INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name       VARCHAR(45) NOT NULL,
    country_id INT         NOT NULL,
    CONSTRAINT fk_towns_countries
        FOREIGN KEY (country_id)
            REFERENCES countries (id)
);

CREATE TABLE stadiums
(
    id       INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name     VARCHAR(45) NOT NULL,
    capacity INT         NOT NULL,
    town_id  INT         NOT NULL,
    CONSTRAINT fk_stadiums_towns
        FOREIGN KEY (town_id)
            REFERENCES towns (id)
);

CREATE TABLE teams
(
    id          INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(45) NOT NULL,
    established DATE        NOT NULL,
    fan_base    BIGINT(20)  NOT NULL DEFAULT 0,
    stadium_id  INT         NOT NULL,
    CONSTRAINT fk_teams_stadiums
        FOREIGN KEY (stadium_id)
            REFERENCES stadiums (id)
);

CREATE TABLE players
(
    id             INT            NOT NULL PRIMARY KEY AUTO_INCREMENT,
    first_name     VARCHAR(10)    NOT NULL,
    last_name      VARCHAR(20)    NOT NULL,
    age            INT            NOT NULL DEFAULT 0,
    position       CHAR(1)        NOT NULL,
    salary         DECIMAL(10, 2) NOT NULL DEFAULT 0,
    hire_date      DATETIME,
    skills_data_id INT            NOT NULL,
    team_id        INT,
    CONSTRAINT fk_players_skills_data
        FOREIGN KEY (skills_data_id)
            REFERENCES skills_data (id),
    CONSTRAINT fk_players_teams
        FOREIGN KEY (team_id)
            REFERENCES teams (id)
);

CREATE TABLE coaches
(
    id          INT            NOT NULL PRIMARY KEY AUTO_INCREMENT,
    first_name  VARCHAR(10)    NOT NULL,
    last_name   VARCHAR(20)    NOT NULL,
    salary      DECIMAL(10, 2) NOT NULL DEFAULT 0,
    coach_level INT            NOT NULL DEFAULT 0
);

CREATE TABLE players_coaches
(
    player_id INT NOT NULL,
    coach_id  INT NOT NULL,
    CONSTRAINT fk_players_coaches_players
        FOREIGN KEY (player_id)
            REFERENCES players (id),
    CONSTRAINT fk_players_coaches_coaches
        FOREIGN KEY (coach_id)
            REFERENCES coaches (id),
    PRIMARY KEY (player_id, coach_id)
);

-- 02.Insert -
INSERT INTO coaches(first_name, last_name, salary, coach_level)
SELECT p.first_name, p.last_name, p.salary * 2, CHAR_LENGTH(p.first_name)
FROM players p
WHERE p.age >= 45;

-- 03.Update --
UPDATE coaches c
    JOIN players_coaches pc on c.id = pc.coach_id
SET c.coach_level = c.coach_level + 1
WHERE c.first_name LIKE 'A%';

-- 04.Delete --
DELETE FROM players p
WHERE p.age >= 45;

-- 05.	Players --
#  Extract from the Football Scout Database (fsd) database, info about all of the players.
# Order the results by players - salary descending.
SELECT first_name, age, salary
FROM players
ORDER BY salary DESC;

-- 06. Young offense players without contract --
# One of the coaches wants to know more about all the young players (under age of 20)
# who can strengthen his team in the offensive (played on position ‘A’). As he is not
# paying a transfer amount, he is looking only for those who have not signed a contract
# so far (haven’t hire_date) and have strength of more than 50.
# Order the results ascending by salary, then by age.
SELECT p.id,
       CONCAT(p.first_name, ' ', p.last_name) full_name,
       p.age,
       p.position,
       p.hire_date
FROM players p
JOIN skills_data sd on p.skills_data_id = sd.id
WHERE p.position = 'A' AND p.hire_date IS NULL AND sd.strength > 50
ORDER BY p.salary,
         p.age;

-- 07.Detail info for all teams --
# Extract from the database all of the teams and the count of the players that they have.
# Order the results descending by count of players, then by fan_base descending.
SELECT t.name AS team_name,
       t.established,
       t.fan_base,
       COUNT(p.id) players_count
FROM teams t
LEFT JOIN players p on t.id = p.team_id
GROUP BY t.id, t.fan_base
ORDER BY players_count DESC,
         t.fan_base DESC;

-- 08.The fastest player by towns --
# Extract from the database, the fastest player (having max speed), in terms of towns where their team played.
# Order players by speed descending, then by town name.
# Skip players that played in team ‘Devify’
SELECT MAX(sd.speed) max_speed, t.name town_name
FROM players p
RIGHT JOIN teams tm on p.team_id = tm.id
RIGHT JOIN stadiums s on tm.stadium_id = s.id
RIGHT JOIN towns t on s.town_id = t.id
LEFT JOIN skills_data sd on p.skills_data_id = sd.id
WHERE tm.name != 'Devify'
GROUP BY t.id, t.name
ORDER BY max_speed desc, t.name;

-- 09.Total salaries and players by country --
# And like everything else in this world, everything is ultimately about finances.
# Now you need to extract detailed information on the amount of all salaries given
# to football players by the criteria of the country in which they played.
# If there are no players in a country, display NULL.  Order the results by total count of players
# in descending order, then by country name alphabetically
SELECT c.name,
       COUNT(p.id) total_count_of_players,
       SUM(p.salary) total_sum_of_salries
FROM countries c
LEFT JOIN towns t on c.id = t.country_id
LEFT JOIN stadiums s on t.id = s.town_id
LEFT JOIN teams t2 on s.id = t2.stadium_id
LEFT JOIN players p on t2.id = p.team_id
GROUP BY c.name
ORDER BY total_count_of_players DESC,
         c.name ASC;

-- 10.Find all players that play on stadium --
# Create a user defined function with the name udf_stadium_players_count (stadium_name VARCHAR(30))
# that receives a stadium’s name and returns the number of players that play home matches there.
CREATE FUNCTION udf_stadium_players_count (stadium_name VARCHAR(30))
RETURNS INT
BEGIN
DECLARE count_players_with_home_matches INT;
SET count_players_with_home_matches := (
    SELECT COUNT(p.id)
    FROM players p
    LEFT JOIN teams t on p.team_id = t.id
    LEFT JOIN towns t2 on t.name = t2.name
    JOIN stadiums s on t.stadium_id = s.id
    WHERE s.name = stadium_name
    );
RETURN count_players_with_home_matches;
end;

SELECT udf_stadium_players_count ('Linklinks') as `count`;

-- 11.Find good playmaker by teams --
# Create a stored procedure udp_find_playmaker which accepts the following parameters:
# •	min_dribble_points
# •	team_name (with max length 45)
#  And extracts data about the players with the given skill stats (more than min_dribble_points),
# played for given team (team_name) and have more than average speed for all players.
# Order players by speed descending. Select only the best one.
# Show all needed info for this player: full_name, age, salary, dribbling, speed, team name.
CREATE PROCEDURE udp_find_playmaker(min_dribble_points INT, team_name VARCHAR(45))
BEGIN
    SELECT CONCAT(p.first_name, ' ', p.last_name) full_name,
           p.age,
           p.salary,
           sd.dribbling,
           sd.speed,
           tm.name team_name
           FROM players p
    JOIN skills_data sd ON p.skills_data_id = sd.id
    JOIN teams tm ON p.team_id = tm.id
    WHERE sd.dribbling > min_dribble_points AND tm.name = team_name
    GROUP BY p.id
    ORDER BY AVG(sd.speed) DESC
    LIMIT 1;
end;

CALL udp_find_playmaker (20, 'Skyble');
