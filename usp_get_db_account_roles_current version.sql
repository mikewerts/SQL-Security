CREATE  procedure [dbo].[usp_get_db_account_roles]
                              as
                              begin
                              declare @sql nvarchar(max)
                              --declare @return_code int
                              --declare @last_backup_date datetime
                              declare @server_name sysname

                              
							  
							  declare servers_cursor cursor for
                              select srvname from master.dbo.sysservers
							  where isremote = 0
                              order by srvname

							  -- select * from [ME-CRMSQLDEV01].[master].[dbo].[_db_security_table]
							 


							  open servers_cursor

                              fetch servers_cursor into @server_name


                              while @@fetch_status = 0
                              begin
				
						
									set @sql = 'insert into [master].[dbo].Get_DB_Account_Roles
									SELECT server_name = '''+ @server_name +'''
									 , [dbname]
									 , [UserName]
									 , [UserType]
									 , [Role]
									 , GETDATE()

									from ['+ @server_name +'].[master].[dbo].[_db_security_table] '
									begin try
                                   --print @sql
									exec sp_executesql @sql
									end try
									BEGIN CATCH  
										--print @server_name; 
										print 
										'Error:' 
										+ char(10) 
										+ 'Server ' + @server_name 
										+ char(10)
										+ 'Error Number ' + cast(ERROR_NUMBER() as nvarchar) 
										+ char(10)
										+ 'Error Message ' + ERROR_MESSAGE();	
										--+	'ErrorSeverity ' + cast(ERROR_SEVERITY() as nvarchar)    
										--+	'ErrorState ' + cast(ERROR_STATE() as nvarchar)   
 									--	+	'ErrorProcedure ' + cast(ERROR_PROCEDURE() as nvarchar)   
										--+	'ErrorLine ' + cast(ERROR_LINE() as nvarchar)    
																			 

										--SELECT  
										--@server_name,
											--ERROR_NUMBER() AS ErrorNumber  
											--,ERROR_SEVERITY() AS ErrorSeverity  
											--,ERROR_STATE() AS ErrorState  
											--,ERROR_PROCEDURE() AS ErrorProcedure  
											--,ERROR_LINE() AS ErrorLine  
											--,ERROR_MESSAGE() AS ErrorMessage;  
									END CATCH;  


									 --print @sql

                                      fetch servers_cursor into @server_name

									  --print @server_name

                              end

                              close servers_cursor


                              deallocate servers_cursor

                         end



 --SELECT  * from [ME-BEACNSQL1].[master].[dbo].[_db_security_table] 

-- select * from [master].[dbo].Get_DB_Account_Roles


