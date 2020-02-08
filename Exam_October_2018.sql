CREATE DATABASE colonial_journey_management_system_db;

-- Table Design --
CREATE TABLE planets
(
    id   INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL
);

CREATE TABLE spaceports
(
    id        INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name      VARCHAR(50) NOT NULL,
    planet_id INT,
    CONSTRAINT fk_spaceports_planets
        FOREIGN KEY (planet_id)
            REFERENCES planets (id)
);

CREATE TABLE spaceships
(
    id               INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name             VARCHAR(50) NOT NULL,
    manufacturer     VARCHAR(30) NOT NULL,
    light_speed_rate INT DEFAULT 0
);

CREATE TABLE colonists
(
    id         INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(20) NOT NULL,
    last_name  VARCHAR(20) NOT NULL,
    ucn        CHAR(10)    NOT NULL UNIQUE,
    birth_date DATE        NOT NULL
);

CREATE TABLE journeys
(
    id                       INT                                                      NOT NULL PRIMARY KEY AUTO_INCREMENT,
    journey_start            DATETIME                                                 NOT NULL,
    journey_end              DATETIME                                                 NOT NULL,
    purpose                  ENUM ('Medical', 'Technical', 'Educational', 'Military') NOT NULL,
    destination_spaceport_id INT,
    spaceship_id             INT,
    CONSTRAINT fk_journeys_spaceports
        FOREIGN KEY (destination_spaceport_id)
            REFERENCES spaceports (id),
    CONSTRAINT fk_journeys_spaceships
        FOREIGN KEY (spaceship_id)
            REFERENCES spaceships (id)
);

CREATE TABLE travel_cards
(
    id                 INT                                                      NOT NULL PRIMARY KEY AUTO_INCREMENT,
    card_number        CHAR(10)                                                 NOT NULL UNIQUE,
    job_during_journey ENUM ('Pilot', 'Engineer', 'Trooper', 'Cleaner', 'Cook') NOT NULL,
    colonist_id        INT,
    journey_id         INT,
    CONSTRAINT fk_travel_cards_colonists
        FOREIGN KEY (colonist_id)
            REFERENCES colonists (id),
    CONSTRAINT fk_travel_cards_journeys
        FOREIGN KEY (journey_id)
            REFERENCES journeys (id)
);

-- 01.	Data Insertion --
/*You will have to INSERT records of data into the travel_cards table, based on the colonists table.
For colonists with id between 96 and 100(inclusive), insert data in the travel_cards table with the following values:
•	For colonists born after ‘1980-01-01’, the card_number must be combination between the year of birth, day and the first 4 digits from the ucn. For the rest – year of birth, month and the last 4 digits from the ucn.
•	For colonists with id that can be divided by 2 without remainder, job must be ‘Pilot’, for colonists with id that can be divided by 3 without remainder – ‘Cook’, and everyone else – ‘Engineer’.
•	Journey id is the first digit from the colonist’s ucn.
 */
INSERT INTO travel_cards (card_number, job_during_journey, colonist_id, journey_id)
(SELECT IF(c.birth_date > DATE('1980-01-01'),
    CONCAT(YEAR(c.birth_date), DAY(c.birth_date), SUBSTRING(c.ucn,1, 4)),
    CONCAT(YEAR(c.birth_date), MONTH(c.birth_date), RIGHT(c.ucn, 4))),
    IF (c.id % 2 = 0, 'Pilot', IF(c.id % 3 = 0, 'Cook', 'Engineer')),
        c.id,
    SUBSTRING(c.ucn, 1, 1)
    FROM colonists c
    WHERE c.id BETWEEN 96 AND 100
    );


-- 02.	Data Update --
/*
 UPDATE those journeys’ purpose, which meet the following conditions:
•	If the journey’s id is dividable by 2 without remainder – ‘Medical’.
•	If the journey’s id is dividable by 3 without remainder – ‘Technical’.
•	If the journey’s id is dividable by 5 without remainder – ‘Educational’.
•	If the journey’s id is dividable by 7 without remainder – ‘Military’.
 */
UPDATE journeys j
    SET j.purpose =
CASE
    WHEN j.id % 2 = 0 THEN 'Medical'
WHEN j.id % 3 = 0 THEN 'Technical'
WHEN j.id % 5 = 0 THEN 'Educational'
WHEN j.id % 7 = 0 THEN 'Military'
END
WHERE j.id % 2 = 0 OR j.id % 3 = 0 OR j.id % 5 = 0 OR j.id % 7 = 0;


-- 03.	Data Deletion --
/*
 REMOVE from colonists, those which are not assigned to any journey
 */
DELETE colonists
FROM colonists
    LEFT JOIN travel_cards tc on colonists.id = tc.colonist_id
WHERE tc.colonist_id IS NULL;


-- 4.	Section: Querying – 100 pts --
-- 4. Extract all travel cards --
/*
 Extract from the database, all travel cards. Sort the results by card number ascending.
Required Columns
•	card_number
•	job_during_journey
 */
SELECT card_number,
       job_during_journey
FROM travel_cards
ORDER BY card_number;


-- 05. Extract all colonists --
/*
 Extract from the database, all colonists. Sort the results by first name, them by last name, and finally by id in ascending order.

Required Columns
•	id
•	full_name(first_name + last_name separated by a single space)
•	ucn
 */
SELECT id,
       CONCAT(first_name, ' ', last_name) full_name,
       ucn
FROM colonists
ORDER BY first_name,
         last_name,
         id;


-- 06.	Extract all military journeys --
/*
 Extract from the database, all Military journeys. Sort the results ascending by journey start.

Required Columns
•	id
•	journey_start
 */
SELECT id,
       journey_start,
       journey_end
FROM journeys
WHERE purpose = 'Military'
ORDER BY journey_start;


-- 07.	Extract all pilots --
/*
 Extract from the database all colonists, which have a pilot job. Sort the result by id, ascending.

Required Columns
•	id
•	full_name
 */
SELECT c.id,
       CONCAT(c.first_name, ' ', c.last_name) full_name
FROM colonists c
JOIN travel_cards tc on c.id = tc.colonist_id
WHERE tc.job_during_journey = 'Pilot'
ORDER BY c.id;


-- 08.	Count all colonists that are on technical journey --
/*
 Count all colonists, that are on technical journey.

Required Columns
•	Count
 */
SELECT COUNT(*) count
FROM colonists c
JOIN travel_cards tc on c.id = tc.colonist_id
JOIN journeys j on tc.journey_id = j.id
WHERE j.purpose = 'Technical';


-- 09.  Extract the fastest spaceship --
/*
 Extract from the database the fastest spaceship and its destination spaceport name. In other words, the ship with the highest light speed rate.

Required Columns
•	spaceship_name
•	spaceport_name
 */
SELECT s.name,
       s2.name
FROM spaceports s2
JOIN planets p on s2.planet_id = p.id
JOIN journeys j on s2.id = j.destination_spaceport_id
JOIN spaceships s on j.spaceship_id = s.id
ORDER BY s.light_speed_rate DESC
LIMIT 1;


-- 10.  Extract spaceships with pilots younger than 30 years --
/*
 Extract from the database those spaceships, which have pilots, younger than 30 years old. In other words, 30 years from 01/01/2019. Sort the results alphabetically by spaceship name.

Required Columns
•	name
•	manufacturer
 */
SELECT s.name,
       s.manufacturer
FROM spaceships s
JOIN journeys j on s.id = j.spaceship_id
JOIN travel_cards tc on j.id = tc.journey_id
JOIN colonists c on tc.colonist_id = c.id
WHERE tc.job_during_journey = 'Pilot' AND TIMESTAMPDIFF(year, c.birth_date, '2019-01-01') < 30
GROUP BY s.name,s.manufacturer
ORDER BY s.name;


-- 11. Extract all educational mission planets and spaceports --
/*
 Extract from the database names of all planets and their spaceports, which have educational missions. Sort the results by spaceport name in descending order.

Required Columns
•	planet_name
•	spaceport_name
 */
SELECT p.name,
       s.name
From planets p
JOIN spaceports s on p.id = s.planet_id
JOIN journeys j on s.id = j.destination_spaceport_id
WHERE j.purpose = 'Educational'
ORDER BY s.name DESC;


-- 12. Extract all planets and their journey count --
/*
 Extract from the database all planets’ names and their journeys count. Order the results by journeys count, descending and by planet name ascending.
Required Columns
•	planet_name
•	journeys_count
 */
SELECT p.name,
       COUNT(j.destination_spaceport_id) journeys_count
FROM planets p
JOIN spaceports s on p.id = s.planet_id
JOIN journeys j on s.id = j.destination_spaceport_id
GROUP BY p.name
ORDER BY journeys_count DESC,
         p.name;


-- 13.  Extract the shortest journey --
/*
 Extract from the database the shortest journey, its destination spaceport name, planet name and purpose.
Required Columns
•	Id
•	planet_name
•	spaceport_name
•	journey_purpose
 */
SELECT j.id,
       p.name,
       sp.name,
       j.purpose
FROM journeys j
JOIN spaceports sp on j.destination_spaceport_id = sp.id
JOIN planets p on sp.planet_id = p.id
ORDER BY TIMESTAMPDIFF(year, j.journey_start, j.journey_end) ASC
LIMIT 1;


-- 14.  Extract the less popular job --
/*
 Extract from the database the less popular job in the longest journey. In other words, the job with less assign colonists.

Required Columns
•	job_name
 */
SELECT tc.job_during_journey
FROM travel_cards tc
JOIN colonists c on tc.colonist_id = c.id
JOIN journeys j on tc.journey_id = j.id
LIMIT 1;


-- 5.	Section: Programmability – 30 pts --
-- 15. Get colonists count --
/*
 Create a user defined function with the name udf_count_colonists_by_destination_planet (planet_name VARCHAR (30))
 that receives planet name and returns the count of all colonists sent to that planet.
 */
CREATE FUNCTION udf_count_colonists_by_destination_planet (planet_name VARCHAR (30))
RETURNS INT
BEGIN
    DECLARE count_colonists INT;
    SET count_colonists := (
        SELECT COUNT(tc.colonist_id) count
        FROM travel_cards tc
        JOIN colonists c on tc.colonist_id = c.id
        JOIN journeys j on tc.journey_id = j.id
        JOIN spaceports s on j.destination_spaceport_id = s.id
        JOIN planets p on s.planet_id = p.id
        WHERE p.name = planet_name
    );
    RETURN count_colonists;
end;

SELECT p.name, udf_count_colonists_by_destination_planet('Otroyphus') AS count
FROM planets AS p
WHERE p.name = 'Otroyphus';

-- 16. Modify spaceship --
/*
 Create a user defined stored procedure with the name udp_modify_spaceship_light_speed_rate(spaceship_name VARCHAR(50),
 light_speed_rate_increse INT(11)) that receives a spaceship name and light speed
 increase value and increases spaceship light speed
 only if the given spaceship exists. If the modifying is not successful rollback any changes and
 throw an exception with error code ‘45000’ and message: “Spaceship you are trying to modify does not exists.”
 */
CREATE PROCEDURE udp_modify_spaceship_light_speed_rate(spaceship_name VARCHAR(50), light_speed_rate_increse INT(11))
BEGIN
    If spaceship_name = (SELECT s.name
        FROM spaceships s
        WHERE s.name = spaceship_name) THEN
        START TRANSACTION;
        UPDATE spaceships s2
        SET s2.light_speed_rate = s2.light_speed_rate + light_speed_rate_increse
        WHERE s2.name = spaceship_name;
        COMMIT;
        ELSE
              SELECT
                'Spaceship you are trying to modify does not exists.'
        ROLLBACK;
    end if;
end;

CALL udp_modify_spaceship_light_speed_rate ('USS Templar', 5);
CALL udp_modify_spaceship_light_speed_rate ('Na Pesho koraba', 1914);
SELECT name, light_speed_rate FROM spaceships WHERE name = 'USS Templar';
SELECT name, light_speed_rate FROM spaceships WHERE name = 'Na Pesho koraba';