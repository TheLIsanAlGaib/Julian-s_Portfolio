# World Life Expectancy Data Cleaning

# The first thing I like to do is glance through the data to see if I pick up on any errors. 
SELECT * FROM world_life_expectancyyyy
Order by country, year ASC;


# The first thing I notice is that we have a couple of blanks in the Status column. 
# Rather than take care of the blanks right away, I always take care of duplicate rows first. 
# There's many ways to do this. I decided to concatenate the country and year and then do a count on them. 
Select Country, Year, CONCAT(Country, Year), Count(CONCAT(Country,Year))
FROM world_life_expectancyyyy
Group By Country, Year, CONCAT(Country, Year)
Having Count(CONCAT(Country,Year)) > 1;

# I was able to identify which countries were duplicated along with their respective year by grouping by country and year. 
# Now I needed to identify the exact row number. So I used a window function to partition over my concantenated column and then filtered by row numbers greater than 1
SELECT *
FROM (SELECT Row_ID, CONCAT(Country, Year),
	  ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
FROM world_life_expectancyyyy) AS Row_table
WHERE Row_Num > 1;

# Once I identified the duplicate rows, I copy and pasted the previous query into a Delete statement. 
# I made sure to change the subquery so that it was only selecting the Row_ids instead of selecting everything.  
DELETE FROM world_life_expectancyyyy
WHERE Row_ID IN 
(SELECT Row_ID
FROM (SELECT Row_ID, CONCAT(Country, Year),
	  ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
FROM world_life_expectancyyyy) AS Row_table
WHERE Row_Num > 1);

# Now that we got rid of the duplicates, it was time to fill in the blanks. 
# When I was glancing at the data I found blanks in the Status column, so that's the column I'll be tackling first.
SELECT country, year, status, row_id 
FROM world_life_expectancyyyy
WHERE Status = '';

# Now that I identified all the blank cells in the Status column, I wanted to check all the potential values that could be in that column. 
# By checking all th non=blank cells in the status column and using the Distinct function, I found that there were only two possible values: Developed and Developing
SELECT DISTINCT(Status)
FROM world_life_expectancyyyy
WHERE Status <> '';

# Now that I knew all the countries were either Developed or Developing I wanted to see which countries fit into each category. 
# I did this by using the Distinct function and filtering by one of the status categories
SELECT DISTINCT(Country)
FROM world_life_expectancyyyy
WHERE Status = 'Developing';

# From here I THOUGHT I just needed copy and paste the previous query into an Update statement and use a sub query in the Where clause

UPDATE world_life_expectancyyyy
SET Status = 'Developing'
WHERE Country IN 
(SELECT DISTINCT(Country)
FROM world_life_expectancyyyy
WHERE Status = 'Developing');

# However, when I ran it I got an error. It turns out I couldn't update the columns by using a subquery
# After a few Google searches and chatting with ChatGPT I learned that the workaround is either a temp table or a self join. I decided to use a self join
# From my understanding, the reason why the subquery doesn't work is because you're filtering off of the same table; essentially canceling out the two executions. However, a self join works becuase you're filtering off of a different table. In this case t2.
UPDATE world_life_expectancyyyy t1
JOIN world_life_expectancyyyy t2
ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developing';

# Checking if there are any other blanks. 
# We have one blank with the USA
SELECT country, year, status, row_id 
FROM world_life_expectancyyyy
WHERE Status = '';

# Found that the reason it's still blank is because its status is Developed and we only Updated the column based on countries that are Developing.
SELECT country, year, status, row_id 
FROM world_life_expectancyyyy
WHERE country ='United States of America';

# Copy and pasted the previous update statement but changed Developing to Developed
UPDATE world_life_expectancyyyy t1
JOIN world_life_expectancyyyy t2
ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed';

# Checking for Null values in the Status column
SELECT country, year, status, row_id 
FROM world_life_expectancyyyy
WHERE Status IS NULL;

# No Nulls were found so I'm glancing at the data again and I found at least one blank in the Life Expectancy column
# This case is different from the status column because in the Status column it could only be one of two values. But in the Life Expectancy column each cell is a different value
SELECT * FROM world_life_expectancyyyy;

SELECT * 
FROM world_life_expectancyyyy
WHERE `Life expectancy` = '';

SELECT Country, Year, `Life expectancy`
FROM world_life_expectancyyyy
WHERE `Life expectancy` = '';

# Since it appears that life expectancy generally goes up year over year, I'm going to take the average life expectancy prior and after the blank and use that to fill in the blanks
# Here I'm going to align the 2018 blank cell next to the the 2019 data by using a Self Join and then align those to next to the 2017 data using another Self Join

SELECT t1.Country, t1.Year, t1.`Life expectancy`,
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
FROM world_life_expectancyyyy t1
JOIN world_life_expectancyyyy t2
ON t1.Country = t2.Country
AND t1.Year = t2.Year - 1
JOIN world_life_expectancyyyy t3
ON t1.Country = t3.Country
AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = '';

# Now that the data is aligned next to each other I'm going to create another column by getting the average of the two years mentioned before.
SELECT t1.Country, t1.Year, t1.`Life expectancy`,
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3. `Life expectancy`)/2,1)
FROM world_life_expectancyyyy t1
JOIN world_life_expectancyyyy t2
ON t1.Country = t2.Country
AND t1.Year = t2.Year - 1
JOIN world_life_expectancyyyy t3
ON t1.Country = t3.Country
AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = '';

# Now I can update the columns similarly to before where I used a join in the update statement
UPDATE world_life_expectancyyyy t1
JOIN world_life_expectancyyyy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancyyyy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3. `Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = '';

# No blanks in the output means that it worked. 
SELECT *
FROM world_life_expectancyyyy
WHERE `Life expectancy` = ''; 


