class App < Sinatra::Base

	require 'sinatra'
	require 'sqlite3'
	
	get('/') do
		erb(:index)
	end
	
	get('/login') do
		erb(:create_user)
	end
	
	post('/login') do
		user_name = params['user-name']
	
		db = SQLite3::Database.new('db/login.sqlite')
		db.execute("INSERT INTO users('Name') VALUES(?)", [user_name])
		result = db.execute("SELECT UserId FROM artists WHERE Name=?", [user_name])
		user_id = result[0][0]
		
		redirect "/artists/#{user_id}"
	end
end           
