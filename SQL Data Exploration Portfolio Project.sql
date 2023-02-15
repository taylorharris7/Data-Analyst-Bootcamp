select * 
from PortfolioProject..CovidDeaths
where continent is not null
order by 3, 4

select * 
from PortfolioProject..CovidVaccinations
where continent is not null
order by 3, 4


-- data working with
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1, 2


-- total cases vs total deaths in Canada (likelihood of dying if you contract COVID19 and you're in Canada)
select location, date, total_cases, total_deaths, (total_deaths/total_cases*100) as percent_deaths
from PortfolioProject..CovidDeaths
where location = 'Canada' and continent is not null
order by 1, 2


-- total cases vs the population (percentage of people who got COVID19)
select location, date, total_cases, population, (total_cases/population)*100 as total_with_covid
from PortfolioProject..CovidDeaths
where location = 'Canada' and continent is not null
order by 1, 2


-- Countries with the highest infection rate compared to the population
select location, population, MAX(total_cases) as highest_infection_count, (max(total_cases)/population)*100 as infection_rate
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by 4 desc


-- countries with the highest death count compared to the population
-- is nvarchar(255) so have to cast as int
select location, MAX(cast(total_deaths as int)) as total_death_count
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by total_death_count desc


-- continents with the highest death count
select location, MAX(cast(total_deaths as int)) as total_death_count
from PortfolioProject..CovidDeaths
where continent is null
	and location <> 'World'
	and location not like '%income%'
group by location
order by total_death_count desc


-- continents with the highest death counts
select continent, MAX(cast(total_deaths as int)) as total_death_count
from PortfolioProject..CovidDeaths
where continent is not null
	and location <> 'World'
	and location not like '%income%'
group by continent
order by total_death_count desc


-- global numbers
-- group by date for the per day percent, no group by for the total
select sum(new_cases) as global_new_cases, sum(cast(new_deaths as int)) as global_new_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as global_death_percentage
from PortfolioProject..CovidDeaths
where continent is not null
--group by date
order by 1, 2


-- join deaths and vaccinations
select *
from PortfolioProject..CovidDeaths deaths
join PortfolioProject..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date


-- global population compared to vaccinations using the number of vaccinations per day (rolling count)
-- parition by location so it resets at each location, polling comes from the date
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations, 
	sum(convert(bigint, vaccinations.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as country_total_vaccination
from PortfolioProject..CovidDeaths deaths
join PortfolioProject..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null
order by 2, 3


-- get global % vaccinated using CTE
with PopulationVsVaccination (Continent, Location, Date, Population, new_vaccinations, country_total_vaccination)
as
(
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations, 
	sum(convert(bigint, vaccinations.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as country_total_vaccination
from PortfolioProject..CovidDeaths deaths
join PortfolioProject..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null
)
select *, (country_total_vaccination/population*100) as percent_vaccinated
from PopulationVsVaccination


-- get global % vaccinated using temp table
drop table if exists #PopulationVsVaccination
create table #PopulationVsVaccination
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
country_total_vaccination numeric
)

insert into #PopulationVsVaccination
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations, 
	sum(convert(bigint, vaccinations.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as country_total_vaccination
from PortfolioProject..CovidDeaths deaths
join PortfolioProject..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null

select *, (country_total_vaccination/population*100) as percent_vaccinated
from #PopulationVsVaccination

-- create a view to store data for later visualization
create view PercentPopulationVaccinated as
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations, 
	sum(convert(bigint, vaccinations.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as country_total_vaccination
from PortfolioProject..CovidDeaths deaths
join PortfolioProject..CovidVaccinations vaccinations
	on deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null

select *
from PercentPopulationVaccinated