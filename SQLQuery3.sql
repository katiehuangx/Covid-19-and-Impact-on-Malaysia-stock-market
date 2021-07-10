-----------------------
-- Covid-19 Analysis --
-----------------------

--View table
SELECT *
FROM dbo.covid_deaths;

SELECT *
FROM dbo.covid_vaccs;

SELECT *
FROM dbo.klse;

-- *********************
-- ANALYSIS BY LOCATION
-- *********************

-- 1 Worldwide > Total Cases, Total Deaths & Death Rate by Country and Date
-- Shows the likelihood of dying if you contract Covid-19
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_rate
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- 2 Malaysia > Total Cases, Total Deaths & Death Rate by Date
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_rate
FROM dbo.covid_deaths
WHERE location = 'Malaysia'
ORDER BY date;

-- 3 Worldwide > Infection Rate per Population by Country & Date
-- Show the percentage of population contracting Covid-19 at a given date
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infection_rate
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- 4 Malaysia > Infection Rate per Population by Date
-- Show the percentage of population contracting Covid-19 in Malaysia
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infection_rate
FROM dbo.covid_deaths
WHERE location = 'Malaysia'
ORDER BY date;

-- 5 Worldwide > Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS total_cases, MAX((total_cases/population)) * 100 AS infection_rate
FROM dbo.covid_deaths
GROUP BY location, population
ORDER BY infection_rate DESC;

-- 6 Malaysia > Overall Highest Infection Rate in Malaysi
SELECT location, population, MAX(total_cases) AS total_cases, MAX((total_cases/population)) * 100 AS infection_rate
FROM dbo.covid_deaths
WHERE location = 'Malaysia'
GROUP BY location, population
--ORDER BY infection_rate DESC;

-- 7 Worldwide > Highest Death Count per Population & Death Rate
SELECT location, population, MAX(total_deaths) AS total_deaths, (MAX(total_deaths)/population) * 100 AS death_rate_by_population
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY death_rate_by_population DESC;

-- 8 Malaysia > Highest Death Count by Population & Death Rate
SELECT location, population, MAX(total_deaths) AS total_deaths, 
	(MAX(total_deaths)/population) * 100 AS death_rate_by_population
FROM dbo.covid_deaths
WHERE location = 'Malaysia'
GROUP BY location, population
--ORDER BY death_rate_by_population DESC;

-- *********************
-- ANALYSIS BY CONTINENT
-- *********************

-- Worldwide > Infection Rate & Death Rate by Continent
SELECT d.location, d.population, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths,
	(MAX(total_cases)/d.population) * 100 AS infection_rate, 
	(MAX(total_deaths)/MAX(total_cases)) * 100 AS death_perc
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccs AS v
	ON d.date = v.date
WHERE d.continent IS NULL
	AND d.location != 'World'
	AND d.location != 'International'
	AND d.location != 'European Union'
GROUP BY d.continent, d.location, d.population
ORDER BY (MAX(total_cases)/d.population) * 100 DESC;

---- *********************
---- GLOBAL NUMBERS
---- *********************

---- Worldwide > Looking at Death Percentage by Date
---- Show the highest death percentage by date
--SELECT date, SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, (SUM(new_deaths)/SUM(new_cases)) * 100 AS death_perc
--FROM dbo.covid_deaths
--WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY death_perc DESC;

---- Worldwide > Looking at Death Percentage
--SELECT SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, (SUM(new_deaths)/SUM(new_cases)) * 100 AS death_perc
--FROM dbo.covid_deaths
--WHERE continent IS NOT NULL
----GROUP BY date
--ORDER BY total_new_cases;

-- ***********************
-- ANALYSIS BY VACCINATION
-- ***********************

-- 10 Worldwide > Rolling Vaccinations by Country & Date
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
	ORDER BY d.location, d.date) 
	AS rolling_vaccinations
-- Partition by location & date to ensure that once the rolling sum of new vaccinations for a location stops, the rolling sum starts for the next location
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccs AS v
	ON d.location = v.location 
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.location, d.date;

-- 11 Malaysia > Rolling Vaccinations by Date
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
		ORDER BY d.location, d.date) AS rolling_vaccinations
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccs AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE d.location = 'Malaysia'
ORDER BY d.location, d.date;

-- Use CTE
-- 12 Malaysia > Rolling Vaccinations & Percentage of Vaccinated Population
WITH vaccination_per_population (continent, location, date, population, new_vaccinations, rolling_vaccinations) 
AS 
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
		ORDER BY d.location, d.date) AS rolling_vaccinations
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccs AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.location = 'Malaysia'
)
SELECT *, (rolling_vaccinations/population) * 100 AS vaccinated_per_population
FROM vaccination_per_population;

-- Create TEMP TABLE
DROP TABLE IF EXISTS perc_population_vaccinated
CREATE TABLE perc_population_vaccinated
	(
	continent NVARCHAR(255),
	location NVARCHAR(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	rolling_vaccinations NUMERIC
	)

-- Insert into TEMP TABLE
INSERT INTO perc_population_vaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
		ORDER BY d.location, d.date) AS rolling_vaccinations
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccs AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, (rolling_vaccinations/population) * 100 AS vaccinated_per_population
FROM perc_population_vaccinated
WHERE location = 'Malaysia';

---- Create View to store data for visualisation
--CREATE VIEW perc_population_vaccinated_view AS
--SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
--	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
--		ORDER BY d.location, d.date) 
--		AS rolling_vaccinations
--FROM dbo.covid_deaths AS d
--JOIN dbo.covid_vaccs AS v
--	ON d.location = v.location 
--	AND d.date = v.date
--WHERE d.continent IS NOT NULL;

-- ******************************************
-- ANALYSIS OF IMPACT ON MALAYSIA INDEX PRICE
-- ******************************************

-- 13 Malaysia > Infection Rate & Death Rate vs KLSE Index Price by Date during MCO 1.0
SELECT d.date, location, new_cases, total_cases, new_deaths, total_deaths, (total_cases/population) * 100 AS infection_rate, 
	(total_deaths/population) * 100 AS death_perc, 
	k.adj_close
FROM dbo.covid_deaths AS d
LEFT JOIN dbo.klse AS k
	ON d.date = k.Date
WHERE location = 'Malaysia' 
	AND d.date BETWEEN '2020-03-17' AND '2020-05-03'
ORDER BY d.date ASC;

-- 14 Malaysia > Infection Rate & Death Rate vs KLSE Index Price by Date during MCO 2.0
SELECT d.date, location, new_cases, total_cases, new_deaths, total_deaths, (total_cases/population) * 100 AS infection_rate,  
	(total_deaths/population) * 100 AS death_perc, 
	k.adj_close
FROM dbo.covid_deaths AS d
LEFT JOIN dbo.klse AS k
	ON d.date = k.Date
WHERE location = 'Malaysia' 
	AND d.date BETWEEN '2021-01-13' AND '2021-04-03'
ORDER BY d.date ASC;

-- 15 Malaysia > Infection Rate & Death Rate vs KLSE Index Price by Date during MCO 3.0
SELECT d.date, location, new_cases, total_cases, new_deaths, total_deaths, (total_cases/population) * 100 AS infection_rate, 
	(total_deaths/population) * 100 AS death_perc, 
	k.adj_close
FROM dbo.covid_deaths AS d
LEFT JOIN dbo.klse AS k
	ON d.date = k.Date
WHERE location = 'Malaysia' 
	AND d.date BETWEEN '2021-05-07' AND '2021-05-31';

-- 16 Malaysia > Infection Rate & Death Rate vs KLSE Index Price by Date in early July
SELECT d.date, location, new_cases, total_cases, new_deaths, total_deaths, (total_cases/population) * 100 AS infection_rate, 
	(total_deaths/population) * 100 AS death_perc, 
	k.adj_close
FROM dbo.covid_deaths AS d
LEFT JOIN dbo.klse AS k
	ON d.date = k.Date
WHERE location = 'Malaysia' 
ORDER BY d.date DESC;

-- 17 Malaysia > Vaccination Rate by Date
SELECT v.date, location, new_vaccinations, total_vaccinations, (total_vaccinations/population) * 100 AS vaccination_rate, k.adj_close
FROM dbo.covid_vaccs AS v
LEFT JOIN dbo.klse AS k
	ON v.date = k.Date
WHERE location = 'Malaysia' 
	AND (total_vaccinations/population) * 100 > 1
ORDER BY v.date DESC;


CREATE VIEW covid_cases_deaths AS
SELECT continent, location, population, MAX(total_cases) AS total_cases, 
	MAX(total_deaths) AS total_deaths, 
	(MAX(total_cases)/population) * 100 AS infection_rate,
	(MAX(total_deaths)/population) * 100 AS death_rate,
	(MAX(total_cases)/1000000) * 100 AS infection_rate_over_million,
	(MAX(total_deaths)/1000000) * 100 AS death_rate_over_million
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population;

CREATE VIEW covid_vaccinations AS
SELECT continent, location, population, MAX(total_vaccinations) AS total_vaccinations, 
	(MAX(total_vaccinations)/population) * 100 AS people_vaccinated
FROM dbo.covid_vaccs
WHERE continent IS NOT NULL
GROUP BY continent, location, population;

SELECT *
FROM dbo.covid_vaccs
