SELECT
	location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM
	covid_deaths
ORDER BY
	1
	, 2;

-- Total cases vs Total Deaths;
SELECT
	location
	, date
	, total_cases
	, total_deaths
	, (total_deaths / total_cases)* 100 as DeathPercentage
FROM
	covid_deaths
ORDER BY
	1
	, 2;

-- Total cases vs Total Deaths in United States;
SELECT
	location
	, date
	, total_cases
	, total_deaths
	, (total_deaths / total_cases)* 100 as DeathPercentage
FROM
	covid_deaths
WHERE
	location like '%states%'
ORDER BY
	1
	, 2;

-- Total cases vs Population in United States;
SELECT
	location
	, date
	, total_cases
	, population
	, (total_cases / population)* 100 as CovidPercentage
FROM
	covid_deaths
WHERE
	location like '%states%'
ORDER BY
	1
	, 2;

-- Total Infection rate ;
SELECT
	location
	, MAX(cast(total_cases as bigint)) as HighestInfected
	, population
	, MAX((total_cases / population))* 100 as PopulationInfected
FROM
	covid_deaths
GROUP BY
	population
	, location
ORDER BY
	PopulationInfected desc;

-- Countries with the highest death count per population;
SELECT
	location
	, MAX(cast(total_deaths as bigint)) as TotalDeaths
FROM
	covid_deaths
WHERE
	continent is not null
GROUP BY
	location
ORDER BY
	TotalDeaths desc;

-- Total Deaths by continent;
SELECT
	location
	, MAX(cast(total_deaths as bigint)) as TotalDeaths
FROM
	covid_deaths
WHERE
	continent is null
	and location NOT LIKE '%income%'
GROUP BY
	location
ORDER BY
	TotalDeaths desc;

-- Global Numbers;
SELECT
	date
	, SUM(total_cases) as global_cases
	, SUM(cast(total_deaths as bigint)) as global_deaths
	, SUM(cast(total_deaths as bigint))/ SUM(total_cases)* 100 as GlobalDeathPercent
FROM
	covid_deaths
WHERE
	continent is not NULL
GROUP BY
	date
ORDER BY
	1
	, 2;

-- Total Vaccinations vs Total Population;
SELECT
	cd.continent
	, cd.location
	, cd.date
	, cd.population
	, cv.new_vaccinations
	, SUM(cast(cv.new_vaccinations AS bigint)) OVER (
		PARTITION by cd.location
		ORDER BY
		cd.location
		, cd.date
	) as TotalPopVaccinated
FROM
	covid_vaccinations cv
JOIN covid_deaths cd
	ON
	cd.location = cv.location
	AND cd.date = cv.date
WHERE
	cd.continent is not null
ORDER BY
	1
	, 2
	, 3;

-- USING CTE
WITH PopVsVac (
	continent
	, location
	, date
	, population
	, new_vaccinations
	, TotalPopVaccinated
)
AS 
(
	SELECT
		cd.continent
		, cd.location
		, cd.date
		, cd.population
		, cv.new_vaccinations
		, SUM(cast(cv.new_vaccinations AS bigint)) OVER (
			PARTITION by cd.location
			ORDER BY
			cd.location
			, cd.date
		) as TotalPopVaccinated
	FROM
		covid_vaccinations cv
	JOIN covid_deaths cd
	ON
		cd.location = cv.location
		AND cd.date = cv.date
	WHERE
		cd.continent is not null
)

SELECT *
	, (TotalPopVaccinated / cast(population AS float))* 100 AS PercentPopVaccinated
FROM
	PopVsVac

-- USING TEMP TABLE;
DROP TABLE if exists PercentagePopulationVaccinated 

CREATE TEMP TABLE PercentagePopulationVaccinated
(
	Continent nvarchar(255)
	, Location nvarchar(255)
	, Date datetime
	, Population numeric
	, New_Vaccinations numeric
	, TotalPopVaccinated numeric
) 

INSERT INTO
	PercentagePopulationVaccinated
SELECT
	cd.continent
	, cd.location
	, cd.date
	, cd.population
	, cv.new_vaccinations
	, SUM(cast(cv.new_vaccinations AS bigint)) OVER (
		PARTITION by cd.location
		ORDER BY
		cd.location
		, cd.date
	) as TotalPopVaccinated
FROM
	covid_vaccinations cv
JOIN covid_deaths cd
	ON
	cd.location = cv.location
	AND cd.date = cv.date
WHERE
	cd.continent is not null 

SELECT *
	, (TotalPopVaccinated / cast(population AS float))* 100 AS PercentPopVaccinated
FROM
	PercentagePopulationVaccinated


-- VIEWS --


-- Percent of Population Vaccinated over time
CREATE VIEW PercentofPopVaccinatedOverTime AS
WITH VacPopPercent (
	location
	, date
	, population
	, TotalPopulationVaccinated
	, PercentagePopulationVaccinated
)
AS
(
	SELECT
		cd.location
		, cd.date
		, cd.population
		,
    MAX(cast(cv.people_fully_vaccinated AS bigint)) OVER (
			PARTITION by cd.location
			ORDER BY
			cd.location
			, cd.date
		) as TotalPopulationVaccinated
		, (
			MAX(cast(cv.people_fully_vaccinated AS bigint)) OVER (
				PARTITION by cd.location
				ORDER BY
				cd.location
				, cd.date
			) / CAST(cd.population AS float)
		  ) * 100 AS PercentPopulationVaccinated
	FROM
		covid_vaccinations cv
	JOIN covid_deaths cd 
	ON
		cd.location = cv.location
		AND cd.date = cv.date
	WHERE
		cd.continent IS NOT NULL
)
SELECT
	*
FROM
	VacPopPercent
WHERE
	TotalPopulationVaccinated IS NOT NULL;

-- Percent of Population Vaccinated over time for the UNITED STATES
CREATE VIEW PercentofPopVaccOverTimeUS AS
SELECT
	cd.location
	, cd.date
	, cd.population
	, cd.total_deaths
	, MAX(cast(cv.people_fully_vaccinated AS bigint)) OVER (
		PARTITION by cd.location
		ORDER BY
		cd.location
		, cd.date
	) as TotalPopulationVaccinated
	, (
		MAX(cast(cv.people_fully_vaccinated AS bigint)) OVER (
			PARTITION by cd.location
			ORDER BY
			cd.location
			, cd.date
		) / CAST(cd.population AS float)
	) * 100 AS PercentPopulationVaccinated
FROM
	covid_vaccinations cv
JOIN covid_deaths cd ON
	cd.location = cv.location
	AND cd.date = cv.date
WHERE
	cd.continent IS NOT NULL
	AND cv.location LIKE 'United States'
	AND cd.total_deaths IS NOT NULL;

-- Global Cases, Deaths, and percentage of deaths vs cases by date
CREATE VIEW GlobalCases AS
SELECT
	date
	, SUM(total_cases) as global_cases
	, SUM(cast(total_deaths as bigint)) as global_deaths
	, SUM(cast(total_deaths as bigint))/ SUM(total_cases)* 100 as GlobalDeathPercent
FROM
	covid_deaths
WHERE
	continent is not NULL
GROUP BY
	date
ORDER BY
	1
	, 2;

-- Total Deaths per Continent 
CREATE VIEW ContinentalTotalDeaths AS
SELECT
	location
	, MAX(cast(total_deaths as bigint)) as TotalDeaths
FROM
	covid_deaths
WHERE
	continent is null
	and location NOT LIKE '%income%'
GROUP BY
	location
ORDER BY
	TotalDeaths desc;

-- Countries with the highest death per population
CREATE VIEW HighestDeathPerPop AS
SELECT
	location
	, MAX(cast(total_deaths as bigint)) as TotalDeaths
FROM
	covid_deaths
WHERE
	continent is not null
GROUP BY
	location
ORDER BY
	TotalDeaths desc;

-- Percent of Population infected 
CREATE VIEW PercentagePopulationInfected AS
SELECT
	location
	, population
	, MAX(cast(total_cases as bigint)) as HighestInfected
	, MAX((total_cases / population))* 100 as PopulationInfected
FROM
	covid_deaths
WHERE
	continent is not null
GROUP BY
	population
	, location
ORDER BY
	PopulationInfected desc;

-- Percent of Population vaccinated
CREATE VIEW PercentagePopulationVaccinated AS
SELECT
	location
	, population
	, MAX(cast(people_fully_vaccinated as bigint)) as TotalPeopleVaccinated
	, MAX(cast(people_fully_vaccinated AS bigint) / cast(population AS FLOAT))* 100 as PopulationVaccinated
FROM
	covid_vaccinations
WHERE
	continent is not null
GROUP BY
	population
	, location
ORDER BY
	PopulationVaccinated desc;

-- Death Percent vs Cases in US over time
CREATE VIEW DeathVsCasesinUS AS
SELECT
	location
	, date
	, total_cases
	, total_deaths
	, (
		MAX(cast(total_deaths AS bigint)) OVER (
			PARTITION by location
			ORDER BY
			location
			, date
		) / CAST(total_cases AS float) * 100
	) AS DeathPercent
FROM
	covid_deaths
WHERE
	location = 'United States'
	AND total_cases IS NOT NULL
	AND total_deaths IS NOT NULL
ORDER BY
	date
