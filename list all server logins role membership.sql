--EXEC xp_logininfo 

/* Get all the server roles */
declare @db_name nvarchar(max);
declare @windows_user nvarchar(max);
declare @SQL_user nvarchar(max); 
declare @sqlstr as nvarchar(max); 


/* all server roles table */
If(OBJECT_ID('tempdb..#serverroles') Is Not Null)
Begin
    Drop Table #serverroles

End

create table #serverroles 
(
  
  [DatabaseUserName] nvarchar(max),   
    [login type] nvarchar(max), 
	[Role] nvarchar(max)

)
;

If(OBJECT_ID('tempdb..#group_user_info') Is Not Null)
Begin
    Drop Table #group_user_info

End

create table #group_user_info
(
  [Database User] nvarchar(max),   
    [Windows Group] nvarchar(max), 
	[Role] nvarchar(max)
)

--drop table #serverroles
/* get info from xp_loginfo */
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
[permission path]	sysname	--Group membership that allowed the account access.
)






insert into #serverroles
SELECT  

 -- [DatabaseUserName] = memberprinc.[name] ,   
 --   [login type] = memberprinc.type_desc, 
	--[Role] = roleprinc.[name] --,

/* a better way */
 [DatabaseUserName] = memberprinc.[name] ,   
    [login type] = memberprinc.type_desc, 
	[Role] = roleprinc.[name] 

--from sys.syslogins sys_logins




FROM    
    --Role/member associations
    sys.server_role_members members
	--sys.syslogins sys_login
JOIN
    --Roles
    sys.server_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
right JOIN
    --Role members (server logins)
    sys.server_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]

/*
	select * from sys.server_role_members
select * from sys.server_principals

*/

/* Get all the Windows Groups that have roles assigned on the server */

--select * from #serverroles

declare get_windows_group_cursor cursor
for 
	select   [DatabaseUserName]
	--,[Role] 
	 from  #serverroles
	where [login type] = 'WINDOWS_GROUP'

	open get_windows_group_cursor
	
	fetch next from get_windows_group_cursor into @windows_user

	while @@fetch_status = 0

	begin

	set @sqlstr = 'EXEC xp_logininfo '''+@windows_user+''', ''members'''

	print @sqlstr

	insert into #xp_logininfo exec sp_executesql @sqlstr
	fetch get_windows_group_cursor into @windows_user
	end

	close get_windows_group_cursor
deallocate get_windows_group_cursor


--select * from #xp_logininfo

/* first, insert the 

create table #group_user_info
(
  [DatabaseUser] nvarchar(max),   
    [Windows Group Member] nvarchar(max), 
	[Role] nvarchar(max)
)

 */

--select s.DatabaseUserName as 'Database User', xp.[account name] as 'Windows Group Member',  s.role from #serverroles s
--left join #xp_logininfo xp on xp.[permission path] = s.DatabaseUserName
--where xp.[account name] = 'MEMIC1\svc_devivans'

/* first insert the users and groups */

insert into #group_user_info

select s.DatabaseUserName as 'Database User', null as 'Windows Group', --xp.[account name] as 'Windows Group Member'
  s.role from #serverroles s
go

/* now get the users derived from xp_logininfo */
insert into #group_user_info

select xp.[account name] as 'Database User', s.DatabaseUserName as 'Windows Group', 
s.role from #serverroles s
join #xp_logininfo xp on xp.[permission path] = s.DatabaseUserName

select * from #group_user_info
--where  [Database User] = 'memic1\whs'
--or [Windows Group] = 'MEMIC1\A7S'
--
order by [Database User], [Windows Group]

-- get the members from the AD Group

--EXEC xp_logininfo 'MEMIC1\zudy admins', 'members'


