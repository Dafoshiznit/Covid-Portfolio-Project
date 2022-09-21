--This is the path I took as I was exploring the data. Queries shown are in a step by step order including mistakes and corrections.

/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/
/*
HOPE YOU LIKE IT!!
*/

SELECT *
FROM dbo.CovidDeaths
Where Continent is not null
Order by 3,4

SELECT *
FROM CovidPortfolioProject..CovidVaccinations
Order by 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject..CovidDeaths
Order by 1,2

-- Looking at Total Cases vs Total Deaths.
-- Shows the likelihood of Dying if you contract covid in the United stated.

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE LOCATION like '%states%'
Order by 1,2

-- Looking at Total Cases vs Population.
-- Shows the Percentage of the population that was infected.

SELECT Location, date, Population, total_cases, (total_cases/Population)*100 as PercentPopulationInfected
FROM CovidPortfolioProject..CovidDeaths
Order by 1,2

-- Looking at Countries with highest Infection Rate when compared to population.
--ordered by percent infected
---- To Filter by USA (or other country)
-- WHERE Location like '%states%'

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/Population))*100 as PercentPopulationInfected
FROM CovidPortfolioProject..CovidDeaths
group by Location, Population
Order by PercentPopulationInfected desc

-- Looking at Countries with Death Count per population.

SELECT Location, MAX(total_Deaths) AS TotalDeathCount, Max((total_Deaths/Population))*100 as PercentDeaths
FROM CovidPortfolioProject..CovidDeaths
group by Location
Order by TotalDeathCount desc

--Found Issue in Data. 
-- Recast data as Int or bigint respectively.

SELECT Location, MAX(cast(total_Deaths as bigint)) AS TotalDeathCount, Max((total_Deaths/Population))*100 as PercentDeaths
FROM CovidPortfolioProject..CovidDeaths
group by Location
Order by TotalDeathCount desc

--Discovered Issue with Data. Location info has redundant columns and has sections grouping entire regions such as 'World','asia','europe'.
--Intent of this query is to look at individual countries.
--Correction
----Where Continent is not null

SELECT Location, MAX(cast(total_Deaths as bigint)) AS TotalDeathCount, Max((total_Deaths/Population))*100 as PercentDeaths
FROM CovidPortfolioProject..CovidDeaths
Where Continent is not null
group by Location
Order by TotalDeathCount desc


--Now looking at entire Continents

SELECT Continent, MAX(cast(total_Deaths as bigint)) AS TotalDeathCount, Max((total_Deaths/Population))*100 as PercentDeaths
FROM CovidPortfolioProject..CovidDeaths
Where Continent is not null
group by Continent
Order by TotalDeathCount desc

--TotalDeathCount is innacurate due to reporting issues in the Original data set. Some countries in the selected region were not added to the total deaths of that region. 
--For example, Canadas Data was not added into the North American Total Death Count.

SELECT Location, MAX(cast(total_Deaths as bigint)) AS TotalDeathCount, Max((total_Deaths/Population))*100 as PercentDeaths
FROM CovidPortfolioProject..CovidDeaths
Where Continent is null
group by Location
Order by TotalDeathCount desc

--Data contains information about income levels as a location. In order to remove them from the results the previous Query has been updated.
-- Showing the Continents witht the highest death count per population.
--Correction:
--Location not like '%income%'

SELECT Location, MAX(cast(total_Deaths as bigint)) AS TotalDeathCount, Max((total_Deaths/Population))*100 as PercentDeaths
FROM CovidPortfolioProject..CovidDeaths
Where Continent is null
and Location not like '%income%'
group by Location
Order by TotalDeathCount desc


--Preparing for Visualization.

--GLOBAL NUMBERS

--Looking at Total Cases vs Total Deaths and adding in the continent correction.

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
Where Continent is null
and Location not like '%income%'
Order by 1,2

--Trying to look at the Global Numbers by looking at the countries and not the world numbers as that would make the numbers astronomical.

SELECT date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
Where Continent is not null
and Location not like '%income%'
Order by 1,2

--Query broke down the information by the date.

SELECT date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
Where Continent is not null
and Location not like '%income%'
Group by date
Order by 1,2

-- Query showed an error. Probably because we cant group by date when the Query is trying to do multiple things. In order get the data im looking for I will likely need to use aggregate functions.
--total_deaths, (total_deaths/total_cases)*100 as DeathPercentage.

--Changed Query to collect data of the total new cases globally per day

SELECT date, SUM(new_cases) as GlobalDailyNewCases
FROM CovidPortfolioProject..CovidDeaths
Where Continent is not null
Group by date
Order by 1,2

--Updated for ratio of new cases per day and new deaths per day.

SELECT date, SUM(new_cases) as DailyNewCases, SUM(new_deaths) as DailyNewDeaths
FROM CovidPortfolioProject..CovidDeaths
Where Continent is not null
Group by date
Order by 1,2

--Nvarchar is invalid for sum operator. New cases is a float and New Deaths is nvarchar(255). Need to recast column as either int or bigint.

SELECT date, SUM(new_cases) as DailyNewCases, SUM(cast(new_deaths as bigint)) as DailyNewDeaths, SUM(cast(new_deaths as bigint))/SUM(New_Cases)*100 as DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
Where Continent is not null
Group by date
Order by 1,2

--Total cases and total deaths with percentage of deaths.

SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as bigint)) as TotalDeaths, SUM(cast(new_deaths as bigint))/SUM(New_Cases)*100 as DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
Where Continent is not null
Order by 1,2

--Adding the Covid Vaccinations table.

SELECT *
FROM CovidPortfolioProject..CovidDeaths as Dea
Join CovidPortfolioProject..CovidVaccinations as Vac
	ON Dea.location = Vac.location
	and Dea.Date = Vac.date
	
--Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidPortfolioProject..CovidDeaths as Dea
Join CovidPortfolioProject..CovidVaccinations as Vac
	ON Dea.location = Vac.location
	and Dea.Date = Vac.date
Where dea.continent is not null
Order by 2, 3

--I want to make the vaccination count show the rolling total vaccinated in each country.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location) as TotalVaccinated
FROM CovidPortfolioProject..CovidDeaths as Dea
Join CovidPortfolioProject..CovidVaccinations as Vac
	ON Dea.location = Vac.location
	and Dea.Date = Vac.date
Where dea.continent is not null
Order by 2, 3

--Query added a column for TotalVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths as Dea
Join CovidPortfolioProject..CovidVaccinations as Vac
	ON Dea.location = Vac.location
	and Dea.Date = Vac.date
Where dea.continent is not null
and dea.Location not like '%income%'
Order by 2, 3

--Example of CTE

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths as Dea
Join CovidPortfolioProject..CovidVaccinations as Vac
	ON Dea.location = Vac.location
	and Dea.Date = Vac.date
Where dea.continent is not null
and dea.Location not like '%income%'
--Order by 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as RollingPercentageVaccinated
FROM PopvsVac

--Example of TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths as Dea
Join CovidPortfolioProject..CovidVaccinations as Vac
	ON Dea.location = Vac.location
	and Dea.Date = Vac.date
Where dea.continent is not null
and dea.Location not like '%income%'

SELECT *, (RollingPeopleVaccinated/Population)*100 as RollingPercentageVaccinated
FROM #PercentPopulationVaccinated

--Looks fancy but something about the data doesn't work.
---Copied from PortfolioProject for review

------DROP Table if exists #PercentPopulationVaccinated
------Create Table #PercentPopulationVaccinated
------(
------Continent nvarchar(255),
------Location nvarchar(255),
------Date datetime,
------Population numeric,
------New_vaccinations numeric,
------RollingPeopleVaccinated numeric
------)

------Insert into #PercentPopulationVaccinated
------Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
------, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
------, (RollingPeopleVaccinated/population)*100
------From CovidPortfolioProject..CovidDeaths dea
------Join CovidPortfolioProject..CovidVaccinations vac
------	On dea.location = vac.location
------	and dea.date = vac.date
------where dea.continent is not null 
------order by 2,3

------Select *, (RollingPeopleVaccinated/Population)*100
------From #PercentPopulationVaccinated





--Example of Creating View


Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths as Dea
Join CovidPortfolioProject..CovidVaccinations as Vac
	ON Dea.location = Vac.location
	and Dea.Date = Vac.date
Where dea.continent is not null
and dea.Location not like '%income%'



--After Further review I hypothesize the reporting numbers for these countries may be incorrect. Spefically when looking at Cuba, their reporting increases to well over 200 percent of their population.
--They are either vaccinating more people than actually live their or they are submitting fraudulent numbers. Not sure how likely this is. More analysis needed.


Select location, date, population, Total_vaccinations, people_vaccinated, people_fully_vaccinated
From CovidPortfolioProject..CovidVAccinations
Where location = 'Cuba'

--Something strange is happening within this data that I do not understand.


Select location, date, population, Total_vaccinations, people_vaccinated, people_fully_vaccinated
From CovidPortfolioProject..CovidVAccinations
Where location = 'Cuba'
Order by 1, 2, 3

--It appears that on 07/20/2022 the total population of Cuba Changed. Would this mean that I should exclude the data after this date as it seems to be messing with my Queries?
-- Removing All Data after said Date.


Select location, date, population, Total_vaccinations, people_vaccinated, people_fully_vaccinated
From CovidPortfolioProject..CovidVAccinations
Where location = 'Cuba'
and date <= '2022-07-19 00:00:00.000'
Order by 1, 2, 3

--Tried to change the where statement for "date <= '2022-07-19 00:00:00.000'" to "date <= '2022-07-19%'" recieved error message "Conversion failed when converting date and/or time from character string."
--lets look at other locations for the same anamoly.


Select location, date, population, Total_vaccinations, people_vaccinated, people_fully_vaccinated
From CovidPortfolioProject..CovidVAccinations
Where location = 'Afghanistan'
Order by 1, 2, 3

--Similar anomoly but on a different date. Perhaps this is due to that difference in reporting rules for that region post Covid. 
--Perhaps the only way to recieve accurate data is to only use data collected between certain dates. If we looked only at data from before Jan 2022 would the information
--Revised Query bound by those 2 dates.


Select location, date, population, Total_vaccinations, people_vaccinated, people_fully_vaccinated
From CovidPortfolioProject..CovidVAccinations
Where location = 'Cuba'
and date <= '2022-01-01 00:00:00.000'
Order by 1, 2, 3

--Adding in RollingPeopleVaccinated for Cuba

Select location, date, population, Total_vaccinations, people_vaccinated, people_fully_vaccinated
From CovidPortfolioProject..CovidVAccinations
Where location = 'Cuba'
and date <= '2022-01-01 00:00:00.000'
Order by 1, 2, 3

--Take existing query and joining table CovidPortfolioProject..CovidDeaths 

SELECT vac.location, vac.date, vac.population, vac.Total_vaccinations, vac.people_vaccinated, vac.people_fully_vaccinated
FROM CovidPortfolioProject..CovidDeaths as Dea
Join CovidPortfolioProject..CovidVaccinations as Vac
	on Dea.location = Vac.location
	and Dea.Date = Vac.date
Where vac.location = 'Cuba'
and vac.date <= '2022-01-01 00:00:00.000'
Order by 1, 2, 3


--Now Adding in RollingPeopleVaccinated for Cuba

SELECT vac.location, vac.date, vac.population, vac.Total_vaccinations, vac.people_vaccinated, vac.people_fully_vaccinated
, vac.new_vaccinations, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths as Dea
Join CovidPortfolioProject..CovidVaccinations as Vac
	on Dea.location = Vac.location
	and Dea.Date = Vac.date
Where vac.location = 'Cuba'
and vac.date <= '2022-01-01 00:00:00.000'
Order by 2, 3

--For Reference
--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--FROM CovidPortfolioProject..CovidDeaths as Dea
--Join CovidPortfolioProject..CovidVaccinations as Vac
--	ON Dea.location = Vac.location
--	and Dea.Date = Vac.date
--Where dea.continent is not null
--and dea.Location not like '%income%'


--For some Reason The RollingPeopleVaccinated column consistantly counts over the total population. That should not be possible right?