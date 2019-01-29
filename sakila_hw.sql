USE sakila;

-- 1a first and last names from table actor --
SELECT first_name, last_name FROM actor;

-- 1b display first and last name in single column, Actor Name --
SELECT CONCAT(actor.first_name, " ", actor.last_name) AS actor_name
FROM actor;

-- 2a Frist name Joe --
SELECT * from actor
WHERE first_name = "Joe";

-- 2b Last name contains GEN --
SELECT * FROM actor
WHERE last_name LIKE "%gen%";

-- 2c Last name contains LI, ordered by last name, first name --
SELECT * FROM actor
WHERE last_name LIKE "%li%"
ORDER BY last_name, first_name;

-- 2d display country_id and country column for Afghanistan, Bangladesh, China --
SELECT country_id, country FROM country
WHERE country IN ("Afghanistan", "Bangladesh", "China");

-- 3a create column named description in the actor table data type BLOB --
ALTER TABLE actor
ADD COLUMN description BLOB;

-- 3b delete column description from actor table --
ALTER TABLE actor
DROP COLUMN description;

-- 4a list last names of actors, how many have that last name --
SELECT last_name, COUNT(*) FROM actor GROUP BY last_name;

-- 4b list last names of actors, how many have that last name for names shared by at least 2 actors --
SELECT last_name, COUNT(*) AS count FROM actor GROUP BY last_name
HAVING count > 1;

-- 4c Change Groucho Williams to Harpo Williams --
UPDATE actor
SET first_name = "HARPO" WHERE first_name = "Groucho" AND last_name = "Williams";

-- 4d Change Harpo back to Groucho --
UPDATE actor SET first_name = "GROUCHO" WHERE first_name = "HARPO";

-- 5a find the schema of the address table --
DESCRIBE address;

-- 6a use join to show first name, last name, and address of each staff member --
#grab staff name from staff table, address from address table, join on address_id
SELECT staff.first_name, staff.last_name, address.address, address.address2
FROM staff
INNER JOIN address ON
staff.address_id = address.address_id;

-- 6b use join to show total sold by each staff member in August 2005 --
#grab staff name from staff table, amount from payment table, join on staff_id
#must include all non-aggregate columns in group by row
SELECT staff.first_name, staff.last_name, sum(payment.amount) AS total_sold
FROM staff
INNER JOIN payment ON
staff.staff_id = payment.staff_id WHERE payment.payment_date LIKE "2005-08%"
GROUP BY staff.last_name, staff.first_name;

-- 6c list films and the number of actors per film --
#grab film title from film table, actor_id (as proxy for number of actors) from film_actor table, join on film_id
SELECT film.title, COUNT(film_actor.actor_id) AS number_of_actors
FROM film
JOIN film_actor ON 
film.film_id = film_actor.film_id
GROUP BY film.film_id;

-- 6d # of copies of Hunchback Impossible --
#grab title from film table, number of copies from inventory table, join on film_id
SELECT film.title, COUNT(inventory.inventory_id) AS number_of_copies
FROM inventory
JOIN film ON
film.film_id = inventory.film_id WHERE title = "Hunchback Impossible";

-- 6e Total paid by each customer, ordered by customer last name --
#grab name from customer table, amount from payment table, join on customer_id
SELECT customer.first_name, customer.last_name, SUM(payment.amount) AS total_paid
FROM customer
JOIN payment ON
customer.customer_id = payment.customer_id
GROUP BY customer.customer_id
ORDER BY customer.last_name;

-- 7a Movies whose titles start with K and Q, language English --
#basic query - get film info, but need right language_id
SELECT * FROM film
WHERE language_id = (
	#language_id subquery - find english
	SELECT language_id FROM language
	WHERE language_id = 1)
AND title LIKE"K%" OR title LIKE "Q%";

-- 7b All actors in the movie Alone Trip --
#basic query - get actors, but need to know only those in one film
SELECT * from actor
WHERE actor_id IN
	#subquery to connect actor_id and film_id, but need the right film_id
	(SELECT actor_id FROM film_actor
	WHERE film_id IN
		#subquery to sort by the film_id for Alone Trip
		(SELECT film_id FROM film
		WHERE title = "Alone Trip"
        )
	);

-- 7c Canadian customers name and email address (using JOIN) --
SELECT customer.first_name, customer.last_name, customer.email
FROM customer
JOIN address ON
customer.address_id = address.address_id
#use city_id from address table to narrow down to only Canadian customers
WHERE city_id IN
	#subquery to get the city_ids from country_id, but need right country_id
	(SELECT city_id FROM city
	WHERE country_id IN
		#subquery to find only country_id for Canada
		(SELECT country_id FROM country
		WHERE country = "Canada"
        )
    );

-- 7d Movies categorized as family films --
#there are a large number of films that should probably be re-categorized 
		#as some NC-17 films fall under the "Family" label
SELECT * FROM film
WHERE film_id IN
	#connect film_id to category_id, but need to narrow down to only family category
	(SELECT film_id FROM film_category
	WHERE category_id IN
		#pull only films from family category
		(SELECT category_id FROM category
		WHERE name = "Family"
        )
    );

-- 7e Most frequently rented movies in reverse order --
SELECT title, COUNT(rental_id) AS number_of_rentals FROM film 
	#rental data lists transactions with inventory_id, need to connect to film through inventory
    #join film to inventory
	JOIN inventory ON film.film_id=inventory.film_id
    #join inventory to rental
	JOIN rental ON rental.inventory_id = inventory.inventory_id
    GROUP BY title
    ORDER BY number_of_rentals DESC;

-- 7f How much business each store brought in ($) --
SELECT store.store_id, SUM(amount) AS total_sales FROM store
	#payment data lists transactions using staff_id, need to connect to store
    #join store to staff
	JOIN staff ON staff.store_id = store.store_id
    #join staff to payment
	JOIN payment ON payment.staff_id = staff.staff_id
    GROUP BY store.store_id
    ORDER BY total_sales DESC;


-- 7g Display for each store its Store ID, city and country --
SELECT store.store_id, city.city, country.country FROM store
	
    #address info from store tied to address_id in address table
	JOIN address ON address.address_id = store.address_id
    
    #city info from address tied to city_id in city table
	JOIN city ON city.city_id = address.city_id
    
    #country info from city tied to country_id in country table
	JOIN country ON country.country_id = city.country_id;


-- 7h Top five genres in gross revenue in descending order --
SELECT category.name, SUM(amount) AS genre_revenue FROM category
	
    #find which films are in which category using film_category fact table
	JOIN film_category ON category.category_id = film_category.category_id
	JOIN film ON film_category.film_id = film.film_id
    
    #connect film_id to inventory_id in order to access rental data
	JOIN inventory ON inventory.film_id = film.film_id
	JOIN rental ON rental.inventory_id = inventory.inventory_id
    
    #payment data connects to rental_id
	JOIN payment ON payment.rental_id = rental.rental_id
    
    GROUP BY name
    ORDER BY genre_revenue DESC
    LIMIT 5;


-- 8a Create a view using results from 7h (above) --
CREATE OR REPLACE VIEW top_five_genres AS
SELECT category.name, SUM(amount) AS genre_revenue FROM category
	
    #find which films are in which category using film_category fact table
	JOIN film_category ON category.category_id = film_category.category_id
	JOIN film ON film_category.film_id = film.film_id
    
    #connect film_id to inventory_id in order to access rental data
	JOIN inventory ON inventory.film_id = film.film_id
	JOIN rental ON rental.inventory_id = inventory.inventory_id
    
    #payment data connects to rental_id
	JOIN payment ON payment.rental_id = rental.rental_id
    
    GROUP BY name
    ORDER BY genre_revenue DESC
    LIMIT 5;

-- 8b Display view from 8a (above) --
SHOW CREATE VIEW top_five_genres;

-- 8c Delete top_five_genres --
DROP VIEW top_five_genres;




