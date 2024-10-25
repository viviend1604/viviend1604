-- Showing data in CovidDeaths table
-- This query retrieves all the records from the CovidDeaths table, ordered by the 3rd and 4th columns.
SELECT * 
FROM CovidDeaths 
ORDER BY 3, 4;

-- Showing data in CovidVaccinations table
-- This query retrieves all the records from the CovidVaccinations table, ordered by the 3rd and 4th columns.
SELECT * 
FROM CovidVaccinations 
ORDER BY 3, 4;

-- Select data to be used
-- This query selects specific fields from the CovidDeaths table: Location, Date, Total Cases, New Cases, Total Deaths, and Population, ordered by Location and Date.
SELECT 
  Location, 
  Date, 
  Total_Cases, 
  New_Cases, 
  Total_Deaths, 
  Population 
FROM CovidDeaths 
ORDER BY 1, 2;

-- Percentage of Total Cases vs Total Deaths
-- This query calculates the percentage of deaths compared to total cases for each location and date, ordered by Location and Date.
SELECT 
  Location, 
  Date, 
  Total_Cases, 
  Total_Deaths, 
  (CAST(Total_Deaths AS FLOAT) / CAST(Total_Cases AS FLOAT)) * 100 AS DeathPercentage 
FROM CovidDeaths 
ORDER BY 1, 2;

-- Percentage of Total Cases vs Total Population
-- This query calculates the percentage of the population infected compared to the total population for each location, filtering out empty continents, ordered by Location and Date.
SELECT 
  Location, 
  Date, 
  Population, 
  Total_Cases, 
  (CAST(Total_Deaths AS FLOAT) / CAST(Population AS FLOAT)) * 100 AS PercentPopulationInfected 
FROM CovidDeaths 
WHERE 
  Continent IS NOT NULL 
  AND Continent <> '' 
ORDER BY 1, 2;

-- Countries with Highest Infection Rate compared to Population
-- This query returns the countries with the highest infection rate as a percentage of their population, ordered by the percentage of the population infected in descending order.
SELECT 
  Location, 
  Population, 
  MAX(Total_Cases) AS HighestInfectionCount, 
  MAX((CAST(Total_Deaths AS FLOAT) / CAST(Population AS FLOAT)) * 100) AS PercentPopulationInfected 
FROM CovidDeaths 
WHERE 
  Continent IS NOT NULL 
  AND Continent <> '' 
GROUP BY 
  Location, 
  Population 
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
-- This query returns the countries with the highest total death counts, ordered by the death count in descending order.
SELECT 
  Location, 
  MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount 
FROM CovidDeaths 
WHERE 
  Continent IS NOT NULL 
  AND Continent <> '' 
GROUP BY Location 
ORDER BY TotalDeathCount DESC;

-- Continents with the Highest Death Count per Population
-- This query returns the continents with the highest total death counts, ordered by the death count in descending order.
SELECT 
  Continent, 
  MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount 
FROM CovidDeaths 
WHERE 
  Continent IS NOT NULL 
  AND Continent <> '' 
GROUP BY Continent 
ORDER BY TotalDeathCount DESC;

-- Global Numbers
-- This query calculates the total number of cases, total deaths, and the death percentage globally, ordered by total cases and total deaths.
SELECT 
  SUM(New_Cases) AS Total_Cases, 
  SUM(CAST(New_Deaths AS INT)) AS Total_Deaths, 
  (SUM(CAST(New_Deaths AS FLOAT)) / SUM(New_Cases)) * 100 AS DeathPercentage 
FROM CovidDeaths 
WHERE 
  Continent IS NOT NULL 
  AND Continent <> '' 
ORDER BY 1, 2;

-- Total Population vs Vaccinations (Percentage of Population that has received at least one Covid Vaccination)
-- This query calculates the rolling sum of people vaccinated by location and date, showing the cumulative vaccination numbers for each location and date.
SELECT 
  dea.Continent, 
  dea.Location, 
  dea.Date, 
  dea.Population, 
  vac.New_Vaccinations, 
  SUM(CAST(vac.New_Vaccinations AS INT)) 
    OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated 
FROM CovidDeaths dea 
JOIN CovidVaccinations vac 
  ON dea.Location = vac.Location 
  AND dea.Date = vac.Date 
WHERE 
  dea.Continent IS NOT NULL 
  AND dea.Continent <> '' 
ORDER BY 2, 3;

-- Common Table Expression (CTE) for Population vs Vaccination Data
-- This CTE stores cumulative vaccination data per location and date for further calculations.
WITH PopvsVac AS (
  SELECT 
    dea.Continent, 
    dea.Location, 
    dea.Date, 
    dea.Population, 
    vac.New_Vaccinations, 
    SUM(CAST(vac.New_Vaccinations AS INT)) 
      OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated 
  FROM CovidDeaths dea 
  JOIN CovidVaccinations vac 
    ON dea.Location = vac.Location 
    AND dea.Date = vac.Date 
  WHERE vac.Continent IS NOT NULL 
    AND vac.Continent <> ''
)
-- Calculate percentage of vaccinated population from the CTE
SELECT *, 
  (CAST(RollingPeopleVaccinated AS FLOAT) / Population) * 100 AS PercentPopulationVaccinated 
FROM PopvsVac;

-- Percentage of Vaccinated Population
-- This query creates a new table to store the vaccinated population percentage data, then inserts the cumulative vaccination data for each location and date.
DROP TABLE IF EXISTS PercentPopulationVaccinated; -- -- This ensures that we are working with a fresh table, avoiding conflicts with an existing table by the same name.

CREATE TABLE PercentPopulationVaccinated (
  Continent NVARCHAR(255), 
  Location NVARCHAR(255), 
  Date DATETIME, 
  Population NUMERIC, 
  New_Vaccinations NUMERIC, 
  RollingPeopleVaccinated NUMERIC
);

-- Insert cumulative vaccination data into PercentPopulationVaccinated table
INSERT INTO PercentPopulationVaccinated 
SELECT 
  dea.Continent, 
  dea.Location, 
  dea.Date, 
  dea.Population, 
  vac.New_Vaccinations, 
  SUM(CAST(vac.New_Vaccinations AS FLOAT)) 
    OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated 
FROM CovidDeaths dea 
JOIN CovidVaccinations vac 
  ON dea.Location = vac.Location 
  AND dea.Date = vac.Date;

-- Calculate percentage of vaccinated population
SELECT *, 
  (CAST(RollingPeopleVaccinated AS FLOAT) / Population) * 100 AS PercentPopulationVaccinated 
FROM PercentPopulationVaccinated;
