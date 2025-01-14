CREATE DATABASE imdb;

SELECT first_name, last_name FROM actors WHERE id IN 
(SELECT actor_id FROM roles WHERE movie_id IN 
(SELECT id FROM movies WHERE name = "Schindler's List"));

SELECT * FROM roles WHERE movie_id = 290070;

SELECT id FROM movies WHERE name = "Schindler's List";

SELECT * FROM movies WHERE name LIKE "Schindler's List";

SELECT name, rankscore FROM movies WHERE rankscore > ALL (SELECT MAX(rankscore) FROM movies);

SELECT name, rankscore FROM movies WHERE rankscore > ALL (SELECT MAX(rankscore) FROM movies);

SELECT name, rankscore FROM movies WHERE rankscore >= (SELECT MAX(rankscore) FROM movies);

SELECT COUNT(*) FROM roles WHERE movie_id = 290070;

