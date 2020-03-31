CREATE TABLE users
(
    id        INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    username  VARCHAR(30) NOT NULL UNIQUE,
    password  VARCHAR(30) NOT NULL,
    email     VARCHAR(50) NOT NULL,
    gender    CHAR(1)     NOT NULL,
    age       INT         NOT NULL,
    job_title VARCHAR(40) NOT NULL,
    ip        VARCHAR(30) NOT NULL
);

CREATE TABLE addresses
(
    id      INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    address VARCHAR(30) NOT NULL,
    town    VARCHAR(30) NOT NULL,
    country VARCHAR(30) NOT NULL,
    user_id INT         NOT NULL,
    CONSTRAINT fk_addresses_users
        FOREIGN KEY (user_id)
            REFERENCES users (id)
);

CREATE TABLE photos
(
    id          INT      NOT NULL PRIMARY KEY AUTO_INCREMENT,
    description TEXT     NOT NULL,
    date        DATETIME NOT NULL,
    views       INT      NOT NULL DEFAULT 0
);

CREATE TABLE likes
(
    id       INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    photo_id INT,
    user_id  INT,
    CONSTRAINT fk_likes_photos
        FOREIGN KEY (photo_id)
            REFERENCES photos (id),
    CONSTRAINT fk_likes_users
        FOREIGN KEY (user_id)
            REFERENCES users (id)
);

CREATE TABLE comments
(
    id       INT          NOT NULL PRIMARY KEY AUTO_INCREMENT,
    comment  VARCHAR(255) NOT NULL,
    date     DATETIME     NOT NULL,
    photo_id INT          NOT NULL,
    CONSTRAINT fk_comments_photos
        FOREIGN KEY (photo_id)
            REFERENCES photos (id)
);

CREATE TABLE users_photos
(
    user_id  INT NOT NULL,
    photo_id INT NOT NULL,
    CONSTRAINT fk_users_photos_users
        FOREIGN KEY (user_id)
            REFERENCES users (id),
    CONSTRAINT fk_users_photos_photos
        FOREIGN KEY (photo_id)
            REFERENCES photos (id)
);

-- 02.Insert --
# You will have to insert records of data into the addresses table, based on the users table.
# For users with male gender, insert data in the addresses table with the following values:
# •	address – set it to username of the user.
# •	town – set it to password of the user.
# •	country – set it to ip of the user.
# •	user_id – set it to age of the user.
INSERT INTO addresses (address, town, country, user_id)
SELECT username, password, ip, age
FROM users
WHERE gender = 'M';

-- 03.Update --
# Rename those countries, which meet the following conditions:
# •	If the country name starts with 'B' – change it to 'Blocked'.
# •	If the country name starts with 'T' – change it to 'Test'.
# •	If the country name starts with 'P' – change it to 'In Progress'.
UPDATE addresses a
SET a.country =
        CASE
            WHEN a.country LIKE 'B%' THEN 'Blocked'
            WHEN a.country LIKE 'T%' THEN 'Test'
            WHEN a.country LIKE 'P%' THEN 'In Progress'
            ELSE a.country
            END;
-- 04.Delete --
# As you remember at the beginning of our work, we inserted and updated some data. Now you need to remove some addresses.
# Delete all addresses from table addresses, which id is divisible by 3.
DELETE a
from addresses a
WHERE a.id % 3 = 0;

-- 05. Users --
# Extract from the Insta Database (instd), info about all the users.
# Order the results by age descending then by username ascending.
# Required Columns
# •	username
# •	gender
# •	age
SELECT username,
       gender,
       age
FROM users
ORDER BY age DESC,
         username;

-- 06.Extract 5 Most Commented Photos --
# Extract from the database, 5 most commented photos with their count of comments.
# Sort the results by commentsCount, descending, then by id in ascending order.
# Required Columns
# •	id
# •	date_and_time
# •	description
# •	commentsCount
SELECT p.id,
       p.date           date_and_time,
       p.description,
       COUNT(c.comment) commentsCount
FROM photos p
         JOIN comments c on p.id = c.photo_id
GROUP BY p.id
ORDER BY commentsCount DESC,
         p.id ASC
LIMIT 5;


-- 07. Lucky Users --
# When the user has the same id as its photo, it is considered Lucky User. Extract from the database all lucky users.
# Extract id_username (concat id + " " + username) and email of all lucky users. Order the results ascending by user id.
# Required Columns
# •	id_username
# •	email
SELECT CONCAT(u.id, ' ', u.username) id_username,
       u.email
FROM users u
         JOIN users_photos up on u.id = up.user_id
WHERE u.id = up.photo_id
ORDER BY u.id;

-- 08.Count Likes and Comments --
# Extract from the database, photos id with their likes and comments. Order them by count of likes descending,
# then by comments count descending and lastly by photo id ascending.
# Required Columns
# •	photo_id
# •	likes_count
# •	comments_count
SELECT p.id              photo_id,
       (SELECT COUNT(l.photo_id) FROM likes l
           WHERE l.photo_id = p.id) likes_count,
       (SELECT COUNT(c.photo_id) FROM comments c
           where c.photo_id = p.id) comments_count
FROM photos p
ORDER BY likes_count DESC,
         comments_count DESC,
         p.id;

-- 09.The Photo on the Tenth Day of the Month --
# Extract from the database those photos that their upload day is 10 and summarize their description.
# The summary must be 30 symbols long plus "..." at the end. Order the results by date descending order.
# Required Columns
# •	summary
# •	date
SELECT CONCAT(LEFT(p.description, 30), '...') summary,
       p.date                                 upload_date
FROM photos p
WHERE DAYOFMONTH(p.date) = 10
ORDER BY p.date DESC;

-- 10.Get User’s Photos Count --
# Create a user defined function with the name udf_users_photos_count(username VARCHAR(30))
# that receives a username and returns the number of photos this user has upload.
CREATE FUNCTION udf_users_photos_count(username VARCHAR(30))
    RETURNS INT
BEGIN
    DECLARE photos_count INT;
    SET photos_count := (
        SELECT COUNT(up.photo_id)
        FROM users_photos up
                 JOIN users u on up.user_id = u.id
        WHERE u.username = username
    );
    RETURN photos_count;
end;

SELECT udf_users_photos_count('ssantryd') AS photosCount;

-- 11.Increase User Age --
# Create a stored procedure udp_modify_user which accepts the following parameters:
# •	address
# •	town
# udp_modify_user (address VARCHAR(30), town VARCHAR(30)) that receives an address and town
# and increase the age of the user by 10 years only if the given user exists.
# Show all needed info for this user: username, email, gender, age and job_title.
CREATE PROCEDURE udp_modify_user(user_address VARCHAR(30), user_town VARCHAR(30))
BEGIN
    UPDATE users u
        JOIN addresses a on u.id = a.user_id
    SET age = age + 10
    WHERE a.address = user_address && a.town = user_town;

    SELECT username,
           email,
           gender,
           age,
           job_title
    FROM users
             JOIN addresses ON users.id = addresses.user_id
    WHERE address = user_address
      AND town = user_town;
end;

CALL udp_modify_user('97 Valley Edge Parkway', 'Divinópolis');





