#Showing data in CovidDeaths table
Select  * 
From CovidDeaths 
order by  3,  4;

#Showing data in Covid Vaccinations TABLE
select   * 
from  CovidVaccinations 
order by 3,  4;
  
#Select Data which going to be used
Select 
  Location, 
  date, 
  total_cases, 
  new_cases, 
  total_deaths, 
  population 
From  CovidDeaths 
order by  1,  2;


#Percentage of Total Cases vs Total Deaths
Select 
  Location, 
  date, 
  total_cases, 
  total_deaths, 
  ( cast(total_deaths as float)  )/( cast (total_cases as float) )* 100 as DeathPercentage 
From  CovidDeaths 
order by  1,  2;


#Percentage of Total cases vs Total population
Select 
  Location, 
  date, 
  Population, 
  total_cases, 
  (  cast(total_deaths as float)  )/(   cast (population as float)  )* 100 as PercentPopulationInfected 
From  CovidDeaths 
where 
  continent is not null 
  and continent <> '' 
order by  1,  2;


#Countries with Highest Infection Rate compared to Population
Select 
  Location, 
  Population, 
  MAX(total_cases) as HighestInfectionCount, 
  Max(( cast(total_deaths as float)/ cast (population as float)  )* 100 ) as PercentPopulationInfected 
From   CovidDeaths 
where 
  continent is not null 
  and continent <> '' 
Group by 
  Location, 
  Population 
order by 
  PercentPopulationInfected desc;
#Countries with Highest Death Count per Population
Select 
  Location, 
  MAX( cast(Total_deaths as int)  ) as TotalDeathCount 
From  CovidDeaths 
where 
  continent is not null 
  and continent <> '' 
Group by 
  Location 
order by 
  TotalDeathCount desc;
  
  
#Contintents with the highest death count per population
Select 
  continent, 
  MAX( cast(Total_deaths as int) ) as TotalDeathCount 
From   CovidDeaths 
where 
  continent is not null 
  and continent <> '' 
Group by 
  continent 
order by 
  TotalDeathCount desc;
  
  
#GLOBAL NUMBERS
Select 
  SUM(new_cases) as total_cases, 
  SUM(cast(new_deaths as int)  ) as total_deaths, 
  (  SUM(  cast(new_deaths as FLOAY) )/ SUM(New_Cases)  )* 100 as DeathPercentage 
From  CovidDeaths 
where 
  continent is not null 
  and continent <> '' 
order by  1,  2;


#Total Population vs Vaccinations
#Shows Percentage of Population that has recieved at least one Covid Vaccination
Select 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations, 
  SUM( CAST(vac.new_vaccinations AS int) ) 
    OVER (
    Partition by dea.Location 
    Order by 
      dea.location, 
      dea.Date
  ) as RollingPeopleVaccinated 
From  CovidDeaths as dea 
  Join CovidVaccinations as vac On dea.location = vac.location 
  and dea.date = vac.date 
where 
  dea.continent is not null 
  and dea.continent <> '' 
order by 
  2, 
  3;
With PopvsVac (
  Continent, Location, Date, Population, 
  New_Vaccinations, RollingPeopleVaccinated
) --- CTE
as (
  Select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(
      cAST(vac.new_vaccinations AS int)
    ) OVER (
      Partition by dea.Location 
      Order by 
        dea.location, 
        dea.Date
    ) as RollingPeopleVaccinated 
  From  CovidDeaths as dea 
    Join CovidVaccinations as vac On dea.location = vac.location 
    and dea.date = vac.date 
  where 
    vac.continent is not null 
    and vac.continent <> ''
) 
Select   *, 
  ( cast(RollingPeopleVaccinated as float)/ Population)* 100 
From  PopvsVac;



#Percentage of Vaccinated Population
DROP 
  Table if exists PercentPopulationVaccinated;
Create Table PercentPopulationVaccinated (
  Continent nvarchar(255), 
  Location nvarchar(255), 
  Date datetime, 
  Population numeric, 
  New_vaccinations numeric, 
  RollingPeopleVaccinated numeric
);
Insert into PercentPopulationVaccinated 
Select 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations, 
  SUM(
    cast (vac.new_vaccinations as float)
  ) OVER (
    Partition by dea.Location 
    Order by 
      dea.location, 
      dea.Date
  ) as RollingPeopleVaccinated 
From  CovidDeaths as dea 
  Join CovidVaccinations as vac On dea.location = vac.location 
  and dea.date = vac.date;
Select *, 
  (Cast(RollingPeopleVaccinated as float)/ Population )* 100 
From  PercentPopulationVaccinated;
