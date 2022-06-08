/* create the table on all master databases */

use DBA

go


				create table get_xp_logininfo
				(
				[account name]	sysname,	--Fully qualified Windows account name.
				[type]	char(8),	--Type of Windows account. Valid values are user or group.
				[privilege]	char(9),	--Access privilege for SQL Server. Valid values are admin, user, or null.
				[mapped login name]	sysname,	--For user accounts that have user privilege, mapped login name shows the mapped login name that SQL Server tries to use when logging in with this account by using the mapped rules with the domain name added before it.
				[permission path]	sysname null --Group membership that allowed the account access.
				)
use DBA

go

/* create the proc which gets all login info, the extracts all members of the AD group */

create procedure [dbo].[sp_get_xp_logininfo]
        as
                declare @db_name nvarchar(max);
declare @AD_Group nvarchar(max);
declare @sqlstr2 as nvarchar(max); 

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


insert into #xp_logininfo exec xp_logininfo 


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

	begin try

	insert into --#xp_logininfo2 
	[DBA].dbo.get_xp_logininfo exec sp_executesql @sqlstr2


	end try
	BEGIN CATCH  
		--print @server_name; 
		print 
		'Error:' 
		+ char(10) 
		+ 'Server ' + @@servername
		+ char(10)
		+ 'Error Number ' + cast													(ERROR_NUMBER() as nvarchar) 
		+ char(10)
		+ 'Error Message ' + ERROR_MESSAGE();	
	
	END CATCH;


	

	fetch get_windows_group_cursor into @AD_Group
	end

	close get_windows_group_cursor
deallocate get_windows_group_cursor

/*

exec sp_get_xp_logininfo

select * from get_xp_logininfo

*/

/* grant exec rights to pritops, the job owner */

               