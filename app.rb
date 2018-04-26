class App < Sinatra::Base

	require 'sinatra'
	require 'sqlite3'
	require 'erb'
	
	get('/') do
		erb(:index)
	end
	
	get('/login') do
		erb(:create_user)
	end
	
	post('/login') do
		user_name = params['username']
		password  = params['password']
	
		db = SQLite3::Database.new('db/login.sqlite')
		db.execute("INSERT INTO users('Name') VALUES(?)", [user_name])
		db_password = db.execute('select password FROM Users where username=?',[user_name])[0][0]
		result = db.execute("SELECT UserId FROM users WHERE Name=?", [user_name])
		user_id = result[0][0]
		
		redirect "/users/#{user_id}"
	end
end           
