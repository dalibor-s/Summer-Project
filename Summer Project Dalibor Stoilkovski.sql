create database [ProjectDB]
go

use [ProjectDB]
GO


-- create tables and insert values into each

-- 1. Seniority Level

create table [dbo].[SeniorityLevel](
	[Id] [int] IDENTITY(1,1) not null,
	[Name] [nvarchar](100) not null,
	CONSTRAINT [PK_SeniorityLevel] PRIMARY KEY CLUSTERED ([Id] ASC)
	)
go


insert into dbo.SeniorityLevel (Name)
values ('Junior'),
		('Intermediate'),
		('Senior'),
		('Lead'),
		('Project Manager'),
		('Division Manager'),
		('Office Manager'),
		('CEO'),
		('CTO'),
		('CIO')
go

select * from dbo.SeniorityLevel


-- 2. Location

create table [dbo].[Location](
	[Id] [int] IDENTITY(1,1) not null,
	[CountryName] [nvarchar] (100) null,
	[Continent] [nvarchar](30) null,
	[Region] [nvarchar](100) null,
	CONSTRAINT [PK_Location] PRIMARY KEY CLUSTERED ([Id] ASC)
)
go

insert into [dbo].[Location] (CountryName, Continent, Region)
select 
	c.CountryName, c.Continent, c.Region
from
	WideWorldImporters.Application.Countries as c

go


select * from dbo.Location


--3. Department

create table [dbo].[Department](
	[Id] [int] IDENTITY(1,1) not null,
	[Name] [nvarchar](100) not null,
	CONSTRAINT [PK_Department] PRIMARY KEY CLUSTERED ([Id] ASC)
)  
go


insert into dbo.Department (Name)
values ('Personal Banking & Operations'),
		('Digital Banking Department'),
		('Retail Banking & Marketing Department'),
		('Wealth Management & Third Party Products'),
		('International Banking Division & DFB'),
		('Treasury'),
		('Information Technology'),
		('Corporate Communications'),
		('Support Services & Branch Expansion'),
		('Human Resources')
go


select * from dbo.Department



-- 4. Employee

create table [dbo].[Employee]
(
	[ID] [int] IDENTITY(1,1) not null,
	[FirstName] [nvarchar](100) not null,
	[LastName] [nvarchar](100) not null,
	[LocationId] [int] not null,
	[SeniorityLevelId] [int] not null,
	[DepartmentId] [int] not null,
	CONSTRAINT [PK_Employee] PRIMARY KEY CLUSTERED ([ID] ASC)
)
go

alter table dbo.Employee
add constraint [FK_Employee_Location] foreign key (LocationId) 
references dbo.[Location] (Id)

go

alter table dbo.Employee
add constraint [FK_Employee_SeniorityLevel] foreign key (SeniorityLevelId) 
references dbo.[SeniorityLevel] (Id)

go

alter table dbo.Employee
add constraint [FK_Employee_Department] foreign key (DepartmentId) 
references dbo.[Department] (Id)

go


--select * from WideWorldImporters.Application.People as p

insert into [dbo].[Employee] (FirstName, LastName, LocationId, SeniorityLevelId, DepartmentId )
select 
	SUBSTRING(FullName, 1, CHARINDEX(' ', FullName) - 1) AS FirstName,     
		SUBSTRING(FullName,
                 CHARINDEX(' ', FullName) + 1,
                 LEN(FullName) - CHARINDEX(' ', FullName)) AS LastName,
	NTILE(190) OVER (ORDER BY p.PersonId asc) as LocationId,
	NTILE(10) OVER (ORDER BY p.PersonId  asc) as SeniorityLevelId,
	NTILE(10) OVER (ORDER BY p.PersonId desc) as DepartmentId
	
from
	WideWorldImporters.Application.People as p
go


select * from dbo.Employee


-- 5. Salary

create table [dbo].[Salary](
	[Id] [int] IDENTITY(1,1) not null,
	[EmployeeId] [int] not null,
	[Month] [smallint] not null,
	[Year] [smallint] not null,
	[GrossAmount] [decimal](18,2) not null,
	[NetAmount] [decimal](18,2) not null,
	[RegularWorkAmount] [decimal](18,2) not null,
	[BonusAmount] [decimal](18,2) not null,
	[OvertimeAmount] [decimal](18,2) not null,
	[VacationDays] [smallint] not null,
	[SickLeaveDays] [smallint] not null,
	CONSTRAINT [PK_Salary] PRIMARY KEY CLUSTERED 
	([Id] asc)
)
go

alter table dbo.Salary
add constraint [FK_Salary_Employee] foreign key (EmployeeId) 
references dbo.Employee (Id)

go

-- create temporary date table for cross joinig the EmployeeId
create table #period (dt date)    

declare @dateFrom date
declare @dateTo date

set @dateFrom = '2001/01/01'
set @dateTo = '2020/12/31';

;with calendarCTE
as
(select @dateFrom as dt
union all
select dateadd(m, 1, dt)
from calendarCTE
where dateadd (m, 1, dt) <= @dateTo
)
insert into #period select dt
--select 
--datepart(m, dt) as mnt,
--datepart(yy, dt) as yr
from calendarCTE option (MAXRECURSION 0);



select * from #period


insert into dbo.Salary (EmployeeId, Month, Year, GrossAmount, NetAmount, RegularWorkAmount, BonusAmount, OvertimeAmount, VacationDays, SickLeaveDays)
    select 
	  e.ID, MONTH(dt), YEAR(dt), 0, 0, 0, 0, 0, 0, 0
	from dbo.Employee as e 
	cross join #period
go


select * from dbo.Salary


-- Random number for GrossAMount
Declare @max int, @min int;
	
set @max = 60000
set @min = 30000
 
update dbo.Salary 
set GrossAmount =  abs(cast(newid() as binary(6))%(1+@max - @min))+@min


--check
--select GrossAmount from dbo.Salary where GrossAmount < 30000 or GrossAmount > 60000
	
update dbo.Salary
set
	NetAmount = 0.9 * GrossAmount
go


update dbo.Salary
set
	RegularWorkAmount = 0.8 * NetAmount
go


update dbo.Salary
set 
	BonusAmount = case when Month%2=1
					then NetAmount - RegularWorkAmount
					else 0
				end
go

--select BonusAmount from dbo.Salary where Month%2 = 0


update dbo.Salary
set
	OvertimeAmount = case when Month%2=0
						then NetAmount - RegularWorkAmount
						else 0
					end
go

--select OvertimeAmount from dbo.Salary where month%2 = 1


update dbo.Salary
set VacationDays = case when
						Month in (7,12) then 10
						else 0
					end


--select VacationDays from dbo.Salary as s where s.Month = 7


update dbo.Salary
set
	VacationDays = VacationDays + (EmployeeId % 2)
where
	(EmployeeId + MONTH + YEAR)%5 = 1
GO

--select VacationDays from dbo.Salary	as s where s.Month = 7


update dbo.Salary
set
	SickLeaveDays = EmployeeId%8, VacationDays = VacationDays + (EmployeeId % 3)
where 
	(EmployeeId + MONTH + YEAR)%5 = 2
GO



select * from dbo.Salary
where 
	NetAmount <> (RegularWorkAmount + BonusAmount + OvertimeAmount)


-- additionally, vacation days between 20 and 30
update dbo.Salary
set VacationDays = case 
						when Month in (7) then 15
						when Month in (12) then 10
					else 0
					end


select
concat(e.FirstName, ' ' , e.LastName) as FullName, s.Year, s.VacationDays, s.SickLeaveDays, s.BonusAmount
from dbo.Salary as s
inner join dbo.Employee as e on e.ID = s.EmployeeId
where year = 2020 and Month%2 = 1
group by FirstName, LastName, Year, VacationDays, SickLeaveDays, BonusAmount
order by BonusAmount desc

