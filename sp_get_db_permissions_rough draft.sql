declare @db_name nvarchar(max);
declare @ad_name nvarchar(max);
declare @windows_user nvarchar(max);
declare @AD_Group nvarchar(max);
declare @endpoint_name nvarchar(max);
declare @SQL_user nvarchar(max); 
declare @sqlstr as nvarchar(max); 
declare @sqlstr2 as nvarchar(max); 
declare @sqlstr3 as nvarchar(max); 
declare @sqlstr4 as nvarchar(max);
declare @sqlstr5 as nvarchar(max);
declare @majorversion int;
declare @endpoint as nvarchar(max) 

If(OBJECT_ID('tempdb..#xp_logininfo') Is Not Null)
Begin
    Drop Table #xp_logininfo
End


create table #xp_logininfo
(
[account name]	sysname,	--Fully qualified Windows account name.
[type]	char(8),	--Type of Windows account. Valid values are user or group.
[privilege]	char(9),	--Access privilege for SQL Server. Valid values are admin, user, or null.
[mapped login name]	sysname,	--For user accounts that have user privilege, mapped login name shows the mapped login name that SQL Server tries to use when logging in with this account by using the mapped rules with the domain name added before it.
[permission path]	sysname null --Group membership that allowed the account access.
)

create table #xp_logininfo2
(
[account name]	sysname,	--Fully qualified Windows account name.
[type]	char(8),	--Type of Windows account. Valid values are user or group.
[privilege]	char(9),	--Access privilege for SQL Server. Valid values are admin, user, or null.
[mapped login name]	sysname,	--For user accounts that have user privilege, mapped login name shows the mapped login name that SQL Server tries to use when logging in with this account by using the mapped rules with the domain name added before it.
[permission path]	sysname null --Group membership that allowed the account access.
)

If(OBJECT_ID('tempdb..#endpoint') Is Not Null)
Begin
    Drop Table #endpoint
End

create table #endpoint
(
[name] nvarchar(max),
--[type] nvarchar(max),
[privilege] nvarchar(max)
)

set @sqlstr = 'EXEC xp_logininfo'

--EXEC xp_logininfo


insert into #xp_logininfo exec sp_executesql @sqlstr

select * from #xp_logininfo 


declare get_windows_group_cursor cursor
for 

/*
	select   [DatabaseUserName]
	--,[Role] 
	 from  #serverroles
	where [login type] = 'WINDOWS_GROUP'

	*/

	SELECT  

	 [account name]	
	FROM    
    #xp_logininfo

	where  type = 'group'
		
	open get_windows_group_cursor
	
	fetch next from get_windows_group_cursor into @AD_Group

	while @@fetch_status = 0

	begin

	set @sqlstr2 = 'EXEC xp_logininfo '''+@AD_Group+''', ''members'''


	--print @sqlstr

	insert into #xp_logininfo2 exec sp_executesql @sqlstr2
	

	fetch get_windows_group_cursor into @AD_Group
	end

	close get_windows_group_cursor
deallocate get_windows_group_cursor


select * from #xp_logininfo2

set @sqlstr3 =
'


--If exists(
--select xp.[account name], xp.[privilege] from 
--#xp_logininfo xp where xp.[permission path] is NULL)

Insert into #endpoint

select xp.[account name], xp.[privilege] from 
#xp_logininfo xp where xp.[permission path] is NULL 

UNION 

select xp.[permission path], xp.[privilege] from 
#xp_logininfo xp 
where xp.[permission path] is NOT NULL  

--else 

--Insert into #endpoint

--select  NULL

UNION 

select xp.[permission path], xp.[privilege] from 
#xp_logininfo xp 
where xp.[permission path] is NOT NULL '

print @sqlstr3

exec sp_executesql @sqlstr3

select * from #endpoint

select xp.[account name], xp.[privilege] from 
#xp_logininfo xp where xp.[permission path] is NULL


If exists(
select xp.[account name], xp.[privilege] from 
#xp_logininfo xp where xp.[permission path] is NULL and xp.[account name] = 'MEMIC1\ES2S')

Insert into #endpoint

select xp.[account name], xp.[privilege] from 
#xp_logininfo xp where xp.[permission path] is NULL and xp.[account name] = 'MEMIC1\ES2S'

UNION 

select xp.[permission path], xp.[privilege] from 
#xp_logininfo xp 
where xp.[permission path] is NOT NULL and  xp.[account name] = 'MEMIC1\ES2S'

else 

Insert into #endpoint

select 'MEMIC1\ES2S', NULL

UNION 

select xp.[permission path], xp.[privilege] from 
#xp_logininfo xp 
where xp.[permission path] is NOT NULL and  xp.[account name] = 'MEMIC1\ES2S'

