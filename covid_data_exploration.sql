-- Starting data
SELECT [location],
    [date],
    total_cases,
    new_cases,
    total_deaths,
    population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Total cases vs total deaths
-- Shows lileihood of dying if you contract Covid in your country
SELECT [location],
    [date],
    total_cases,
    total_deaths,
    ROUND((total_deaths/total_cases) * 100, 2) AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Total cases vs population
-- Shows % of population that contracted COVID
SELECT [location],
    [date],
    population,
    total_cases,
    ROUND((total_cases/population) * 100, 2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Countries with highest infection rate compared to population
SELECT [location],
    population,
    MAX(total_cases) AS HighestInfectionCount,
    ROUND(MAX((total_cases/population))*100,2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location], population
ORDER BY 4 DESC


-- Countries with highest death rate compared to population
SELECT [location],
    population,
    MAX(total_deaths) AS TotalDeathCount,
   ROUND(MAX((total_deaths/population))*100,2) AS PercentPopulationDeceased
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location], population
ORDER BY 4 DESC


-- Continents with the highest death count
SELECT [location],
    MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL AND [location] NOT LIKE '%income%'
GROUP BY [location]
ORDER BY 2 DESC


-- Global numbers
SELECT --[date], 
    SUM(new_cases) AS TotalNewCases,
    SUM(new_deaths) AS TotalNewDeaths,
    ROUND(SUM(new_deaths)/ NULLIF(SUM(new_cases),0) * 100, 2) AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL AND new_cases IS NOT NULL
--GROUP BY [date]
ORDER BY 1


-- Total population vs vaccinations
SELECT cd.continent,
    cd.[location],
    cd.[date],
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.[location] ORDER BY cd.location, cd.[date]) AS RollingTotalNewVaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
    ON cd.[location] = cv.[location] AND cd.[date]=cv.[date]
WHERE cd.continent IS NOT NULL
ORDER BY 2,3


-- Use CTE
WITH PopulationvsVaccines (continent, location, date, population, new_vaccinations, RollingTotalNewVaccinations) 
AS (
SELECT cd.continent,
    cd.[location],
    cd.[date],
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.[location] ORDER BY cd.location, cd.[date]) AS RollingTotalNewVaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
    ON cd.[location] = cv.[location] AND cd.[date]=cv.[date]
WHERE cd.continent IS NOT NULL
)
SELECT *, (CAST(RollingTotalNewVaccinations AS float)/population) * 100
FROM PopulationvsVaccines
ORDER BY 2,3


-- Temp table
DROP TABLE IF EXISTS #PercentPopulationvsNewVaccines
CREATE TABLE #PercentPopulationvsNewVaccines (
    continent NVARCHAR(225),
    location NVARCHAR(225),
    date DATETIME,
    population NUMERIC,
    new_caccinations NUMERIC,
    RollingTotalNewVaccinations NUMERIC
)

INSERT INTO #PercentPopulationvsNewVaccines
SELECT cd.continent,
    cd.[location],
    cd.[date],
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.[location] ORDER BY cd.location, cd.[date]) AS RollingTotalNewVaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
    ON cd.[location] = cv.[location] AND cd.[date]=cv.[date]

SELECT *, (RollingTotalNewVaccinations/population) * 100
FROM #PercentPopulationvsNewVaccines


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationvsNewVaccines AS
SELECT cd.continent,
    cd.[location],
    cd.[date],
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.[location] ORDER BY cd.location, cd.[date]) AS RollingTotalNewVaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
    ON cd.[location] = cv.[location] AND cd.[date]=cv.[date]
WHERE cd.continent IS NOT NULL

SELECT *
FROM PercentPopulationvsNewVaccines