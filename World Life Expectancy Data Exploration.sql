# World Life Expectancy Data Exploration


# Glancing through the data
SELECT *
FROM world_life_expectancyyyy;

SELECT * 
FROM world_life_expectancyyyy
WHERE country in ('Cook Islands', 'Monaco', 'Niue', 'Saint Kitts and Nevis', 'San Marino');


# First thing I want to take a look at is the minimum life expectancy and the maximum and then I'd like to see the difference between those two numbers to see how much it's grown as well as the percent growth
# While scrolling through the data I saw some countries had zeros so I filtered them out.

Select country, min(`life expectancy`), max(`life expectancy`), round(max(`life expectancy`) - min(`life expectancy`), 1) as le_growth, 
round((max(`life expectancy`) - min(`life expectancy`)) / MIN(`life expectancy`) * 100, 1) as le_percent_growth
FROM world_life_expectancyyyy
where `life expectancy` != 0
group by country
order by le_percent_growth DESC;

# It's important to remember that we're looking at life expectancy over a 15 year time frame. So to see that some countries have increased there life expectancy by over 20 years in 15 years is pretty amazing.

# Now that I've checked the life expectancy based on country, let's look at it based on the year for the enitre world.
SELECT Year, ROUND(AVG(`Life expectancy`),2)
FROM world_life_expectancyyyy
WHERE `Life expectancy` <> 0
AND `Life expectancy` <> 0
GROUP BY Year
ORDER BY Year;

# I'd like to know how much life expectancy increased year over year
# I'm thinking we can use a self join on the year before and then subtract them. 
SELECT w1.Year AS Year1, ROUND(AVG(w1.`Life expectancy`), 2) AS Avg_le_y1,
       w2.Year AS Year2, ROUND(AVG(w2.`Life expectancy`), 2) AS Avg_le_y2,
       Round(ROUND(AVG(w1.`Life expectancy`), 2) - ROUND(AVG(w2.`Life expectancy`), 2), 2) as change_in_le
FROM world_life_expectancyyyy w1
JOIN world_life_expectancyyyy w2
ON w1.Year = w2.Year + 1
WHERE w1.`Life expectancy` <> 0
AND   w2.`Life expectancy` <> 0
GROUP BY w1.Year, w2.Year
ORDER BY w1.Year;

# Interesting that 2009 to 2010 and 2021 to 2022 were the only period where life expectancy increased by less than 0.1

# Curious what the average increase in life expectancy was during that time.

Select Round(avg(change_in_le), 2)
FROM (SELECT w1.Year AS Year1, ROUND(AVG(w1.`Life expectancy`), 2) AS Avg_le_y1,
       w2.Year AS Year2, ROUND(AVG(w2.`Life expectancy`), 2) AS Avg_le_y2,
       Round(ROUND(AVG(w1.`Life expectancy`), 2) - ROUND(AVG(w2.`Life expectancy`), 2), 2) as change_in_le
FROM world_life_expectancyyyy w1
JOIN world_life_expectancyyyy w2
ON w1.Year = w2.Year + 1
WHERE w1.`Life expectancy` <> 0
AND   w2.`Life expectancy` <> 0
GROUP BY w1.Year, w2.Year
ORDER BY w1.Year) T2;




# I want to check if there's any correlation between life expectancy and some of the other columns
# First I'm going to check the orreclation between life expectancy and GDP
SELECT Country, ROUND(AVG(`Life expectancy`),1) AS Life_Exp, ROUND(AVG(GDP),1) AS GDP
FROM world_life_expectancyyyy
GROUP BY Country
HAVING Life_Exp > 0
AND GDP > 0
ORDER BY GDP DESC;

# It definitely looks like there's a positive correlation between life expectancy and GDP
# Now I want to find the median GDP

Select gdp
FROM world_life_expectancyyyy
Where gdp <> 0
Order by GDP;

Select Round(COUNT(gdp)/ 2, 
FROM world_life_expectancyyyy
Where gdp <> 0 and `Life expectancy` <> 0;

# After getting the count of the non zero gdp rows, since there's an even amount of rows I'm going to need to get the average of the two middle rows

Select Round(AVG(GDP),1)
FROM (Select GDP, 
ROW_NUMBER() OVER(Order by GDP) as row_num
FROM world_life_expectancyyyy
wHERE GDP <> 0 and `Life expectancy` <> 0
Order by GDP) T1;
#Where row_num IN (1244, 1245);

# 1764.5 is our median GDP

# Now I'd like to see the average life expectancy of countries under the median gdp vs countries above the median gdp
SELECT 
Sum(Case When gdp > 1764.5 Then 1 Else 0 End) as high_gdp,
Round(avg(case when gdp > 1764.5 Then `life expectancy` Else Null End), 1) as high_gdp_le,
Sum(Case When gdp <= 1764.5 Then 1 Else 0 End) as low_gdp,
Round(avg(case when gdp <= 1764.5 Then `life expectancy` Else Null End), 1) as low_gdp_le
FROM 
(
Select country, year, gdp, `life expectancy`
from world_life_expectancyyyy
Where year = 2022
ORDER BY GDP DESC) AS t1
where gdp != 0 and `life expectancy` != 0
;

# Wow, so if your country's GDP is above the median then your likely to live ten and a half more years than if you're in a country whose GDP is below the median. That's pretty staggering.

# Now I want to see the number of developing countries vs developed countries and the average life expectancy based on stautus
SELECT status, count(distinct country), round(avg(`life expectancy`), 1) 
FROM world_life_expectancyyyy
where `life expectancy` != 0
group by status;

#Curious which countries are both below the median GDP and labeled as Developed
Select country, year, GDP, Status
FROM world_life_expectancyyyy
Where status = 'Developed' AND  GDP < 1764.5 AND YEAR = 2022; 

# The difference between life expectancy when you're a developing country as opposed to a developed country is even greater than the difference of life expectancy when you compare countries' GDP to the median GDP. However it's important to keep in mind that this is being skewed by the fact that there are so many more developing countries than developed.

# Correlation between average amount of major diseases by country and the average life expectancy
# Major diseases include: Measles, Polio, Diphtheria
SELECT 
country, 
Round(AVG(Measles + Polio + Diphtheria), 1) AS avg_major_diseases, 
Round(SUM(Measles + Polio + Diphtheria), 1), 
Round(avg(`life expectancy`), 1) avg_le
FROM world_life_expectancyyyy
Where `life expectancy` != 0
GROUP BY country
Having avg_le > 72.4
Order by avg_le DESC;

# Some of the countries that have the lowest average life expectancy alos have some of the lowerest amount of major diseases
# There doesn't seem to be a correlation between number of major diseases and life expectancy

# Now I'm curious if there's any correlation between life expectancy and BMI
# I'm going to compare the average life expectancy and the average bmi and then group by country
SELECT Country, ROUND(AVG(`Life expectancy`),1) AS Life_Exp, ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancyyyy
GROUP BY Country
HAVING Life_Exp > 0
AND BMI > 0
ORDER BY life_exp DESC
Limit 10;

# Looking at the top ten countries based on life_expectancy, Japan is the only country that seems to have a healthy BMI. Every other country is about double Japan's BMI. 
# Let's look at the bottom ten countries now

SELECT Country, ROUND(AVG(`Life expectancy`),1) AS Life_Exp, ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancyyyy
GROUP BY Country
HAVING Life_Exp > 0
AND BMI > 0
ORDER BY life_exp ASC
Limit 10;

# As expected, the bottom 10 countries have significanly lower BMIs compared to the top 10 countries
# Let's add GDP to this equation and order by GDP

Select * 
FROM 
(
SELECT 
Country, 
ROUND(AVG(`Life expectancy`),1) AS Life_Exp, 
Round(AVG(GDP), 1) AS avg_gdp,
ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancyyyy
GROUP BY Country
HAVING Life_Exp > 0
AND BMI > 0
ORDER BY avg_gdp DESC, life_exp DESC
Limit 10) AS t1
Order by BMI DESC;

# After finding Singapore's inverse relationship withe life expectancy and BMI, I was curious what other countries had a low BMI with a high life expectancy. 
Select 
country,
ROUND(AVG(`Life expectancy`),1) AS Life_Exp, 
Round(AVG(GDP), 1) AS avg_gdp,
ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancyyyy
GROUP BY Country
HAVING ROUND(AVG(`Life expectancy`),1) > 75 AND ROUND(AVG(BMI),1) < 30
;


# All of the top ten countries in GDP also have very high BMIs except Singapore, who also has a very high life expectancy.
# The correlation I'm seeing is that the higher your GDP the higher your BMI. Also all of the top 10 in gdp have high life expectancy. I would have thought that if a country has a high BMI then there would be a lower life expectancy since I would think having a high BMI woudl lead to more health issues. But I'm guessing that if you also have a high GDP then you have the medical infrastructure to keep your population alive even though they're more sick from being more overweight.
# Interesting that Japan and Singapore both have very high life expectancy while maintaining a healthy BMI. I'm guessing this is because they have a culture of eating healthier food. I have heard that kid's lunches at school are very healthy so this healthy eating mentality is instilled at a very early age.

# Lastly I want to check the adult mortality of each country
# I'm going to use a window function to do a rolling total
SELECT country, year, 
	   sum(`adult mortality`) over( partition by country  order by year) as rolling_total
FROM world_life_expectancyyyy
order by country, year;








SELECT 
Sum(Case When gdp > 1764.5 Then 1 Else 0 End) as high_gdp,
Round(avg(case when gdp > 1764.5 Then `life expectancy` Else Null End), 1) as high_gdp_le,
Sum(Case When gdp <= 1764.5 Then 1 Else 0 End) as low_gdp,
Round(avg(case when gdp <= 1764.5 Then `life expectancy` Else Null End), 1) as low_gdp_le
FROM world_life_expectancyyyy
where gdp != 0
Order by gdp;




#This is the query I did before to findout the average life expectancy of countries below and above the median, but I'm not sure if it's correct. I changed it to a different query that can be seen above.
#SELECT 
#Sum(Case When gdp > 1764.5 Then 1 Else 0 End) as high_gdp,
#Round(avg(case when gdp > 1764.5 Then `life expectancy` Else Null End), 1) as high_gdp_le,
#Sum(Case When gdp <= 1764.5 Then 1 Else 0 End) as low_gdp,
#Round(avg(case when gdp <= 1764.5 Then `life expectancy` Else Null End), 1) as low_gdp_le
#FROM world_life_expectancyyyy
#where gdp != 0
#Order by gdp;





Select * 
FROM (SELECT 
Country, 
ROUND(AVG(`Life expectancy`),1) AS Life_Exp, 
Round(AVG(GDP), 1) AS avg_gdp,
ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancyyyy
GROUP BY Country
HAVING Life_Exp > 0
AND BMI > 0
ORDER BY avg_gdp DESC, life_exp DESC
Limit 10) AS t1
Order by avg_gdp DESC
