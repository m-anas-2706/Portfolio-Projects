

SELECT *
FROM [PortfolioProject]..CovidDeaths
ORDER BY 3, 4


SELECT *
FROM [PortfolioProject]..CovidVaccinations
ORDER BY 3, 4




SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [PortfolioProject]..CovidDeaths
ORDER BY 1,2


-- Total Cases vs. Total Deaths
-- Shows likelihood of dying if you contract COVID in Pakistan.
SELECT location, date, total_cases, total_deaths,
	   (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM [PortfolioProject]..CovidDeaths
WHERE location = 'Pakistan'
ORDER BY 1,2


-- Total cases vs population
-- Shows what percentage of population got COVID.
SELECT location, date, population, total_cases,
	   (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT))*100 AS PercentPopulationInfected
FROM [PortfolioProject]..CovidDeaths
WHERE location = 'Pakistan'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(CAST(total_cases AS FLOAT)) AS HighestInfectionCount,
	   MAX((CAST(total_cases AS FLOAT)) / CAST(population AS FLOAT))*100 AS PercentPopulationInfected
FROM [PortfolioProject]..CovidDeaths
-- WHERE location = 'Pakistan'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Countries with highest death count per population
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [PortfolioProject]..CovidDeaths
-- WHERE location = 'Pakistan'
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Highest death count by Continent
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [PortfolioProject]..CovidDeaths
-- WHERE location = 'Pakistan'
WHERE continent is NULL AND location NOT IN ('European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Global numbers
-- (i) by each day until 7th March, 2023.
SELECT date, 
	   SUM(new_cases) as total_cases, 
	   SUM(new_deaths) as total_deaths,
	   (SUM(new_deaths)/ SUM(new_cases))*100 AS DeathPercentage
FROM [PortfolioProject]..CovidDeaths
WHERE continent is not null
AND new_cases <> 0
GROUP BY date
ORDER BY 1,2

-- (ii) Global numbers as of 7th March, 2023.
SELECT SUM(new_cases) as total_cases, 
	   SUM(new_deaths) as total_deaths,
	   (SUM(new_deaths)/ SUM(new_cases))*100 AS DeathPercentage
FROM [PortfolioProject]..CovidDeaths
WHERE continent is not null
AND new_cases <> 0
--GROUP BY date
ORDER BY 1,2


SELECT *
FROM [PortfolioProject]..CovidDeaths
WHERE continent is not null
ORDER BY 3

SELECT *
FROM [PortfolioProject]..CovidVaccinations


-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
(RollingPeopleVaccinated/population)*100
FROM [PortfolioProject]..CovidDeaths dea
JOIN [PortfolioProject]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL AND vac.location NOT IN ('European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
AND new_vaccinations is not null
ORDER BY 2,3


-- Using CTE
WITH PopulationvsVaccinations (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [PortfolioProject]..CovidDeaths dea
JOIN [PortfolioProject]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL AND vac.location NOT IN ('European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
)
SELECT *, (RollingPeopleVaccinated/population)*100 as PercentageOfPeopleVaccinated
FROM PopulationvsVaccinations



-- Temp Tables
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [PortfolioProject]..CovidDeaths dea
JOIN [PortfolioProject]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL AND vac.location NOT IN ('European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')

SELECT *, (RollingPeopleVaccinated/population)*100 as PercentageOfPeopleVaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2,3



-- Creating View to store data for visualization.

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [PortfolioProject]..CovidDeaths dea
JOIN [PortfolioProject]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL AND vac.location NOT IN ('European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')

SELECT *
FROM [PortfolioProject]..PercentPopulationVaccinated



