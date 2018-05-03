class App < Sinatra::Base
	require 'sinatra'
	require 'slim'
	require 'sqlite3'
	require 'bcrypt'
	
	enable :sessions
	
	TIME_STEP = Rational(1, 1440) # 0,25 1440-delar av dygnet, alltså 0,25 minuter
	
	get("/") do
		if !is_logged_in()
			redirect("/login")
		end
	
		db = db_connect()
		topics = db.execute("SELECT * FROM topics")
		chatrooms = db.execute("SELECT * FROM chatrooms")
	
		for chatroom in chatrooms
			for topic in topics
				if chatroom["topic_id"] == topic["id"]
					chatroom["topic"] = topic["name"]
					break
				end
			end
		end
	
		slim(:index, locals:{"chatrooms": chatrooms})
	end
	
	get("/chatroom/:id/?") do
		if !is_logged_in()
			redirect("/login")
		end
	
		db = db_connect()
		chatroom_id = params[:id].to_i
		chatrooms = db.execute("SELECT * FROM chatrooms WHERE id = ?", [chatroom_id])
		if chatrooms.length == 0
			return "Chatroom not found"
		end
	
		now = DateTime::now
		chatroom = chatrooms[0]
		end_time = DateTime::strptime(chatroom["end_time"])
		seconds_left = ((end_time - now) * 24 * 60 * 60).to_i
	
		if seconds_left <= 0
			topics = db.execute("SELECT * FROM topics")
			new_topic = nil
			while new_topic == nil || new_topic["id"] == chatroom["topic_id"]
				new_topic = topics[Random.rand(topics.length)]
			end
			while end_time <= now + TIME_STEP
				end_time += TIME_STEP
			end
			db.execute("UPDATE chatrooms SET topic_id = ?, end_time = ? WHERE id = ?", [new_topic["id"], end_time.to_s, chatroom_id])
			db.execute("DELETE FROM chat_messages WHERE chatroom_id = ?", [chatroom_id])
			redirect("/chatroom/#{chatroom_id}")
		end
	
		users = db.execute("SELECT * FROM users")
		topic = db.execute("SELECT * FROM topics WHERE id = ?", [chatroom["topic_id"].to_i])[0]
		messages = db.execute("SELECT * FROM chat_messages WHERE chatroom_id = ?", [chatroom_id])
	
		for message in messages
			for user in users
				if message["user_id"] == user["id"]
					message["user"] = user
					break
				end
			end
			message["time_posted"] = message["time_posted"][11, message.length - 6]
		end
	
		slim(:chatroom, locals:{"chatroom": chatroom, "topic": topic["name"], "messages": messages, "seconds_left": seconds_left})
	end
	
	post("/chatroom/:id/?") do
		if !is_logged_in()
			redirect("/login")
		end
	
		db = db_connect()
		chatroom_id = params[:id].to_i
		chatrooms = db.execute("SELECT * FROM chatrooms WHERE id = ?", [chatroom_id])
		if chatrooms.length == 0
			return "Chatroom not found"
		end
	
		message = params[:message]
		if message.empty?
			redirect("/chatroom/#{chatroom_id}")
		end
	
		time_posted = DateTime::now
		db.execute("INSERT INTO chat_messages(chatroom_id, user_id, message, time_posted) VALUES(?,?,?,?)", [chatroom_id, session[:user_id], message, time_posted.to_s])
	
		redirect("/chatroom/#{chatroom_id}")
	end
	
	get("/login/?") do
		slim(:login)
	end
	
	get("/register/?") do
		slim(:register)
	end
	
	get("/logout") do
		session[:user_id] = nil
		redirect("/")
	end
	
	post("/login/?") do
		username = params[:username]
		password = params[:password]
	
		db = SQLite3::Database.new("db.sqlite3")
		db.results_as_hash = true
		x = db.execute("SELECT * FROM users WHERE username = ?", [username])
		if x.length() == 0
			redirect("/login")
		end
	
		users = db.execute("SELECT * FROM users WHERE username = ?", [username])
		if users.length() == 0
			redirect("/login")
		end
	
		user = users[0]
	
		if BCrypt::Password.new(user["password"]) != password
			redirect("/login")
		end
	
		session[:user_id] = user["id"]
	
		redirect("/")
	end
	
	post("/register/?") do
		username = params[:username]
		password = params[:password]
		password_confirm = params[:password_confirm]
	
		if password != password_confirm
			redirect("/register")
		end
	
		if username == "" or password == "" or password_confirm == ""
			redirect("/register")
		end
	
		db = SQLite3::Database.new("db.sqlite3")
		db.results_as_hash = true
		x = db.execute("SELECT * FROM users WHERE username = ?", [username])
		if x.length() > 0
			redirect("/")
		end
	
		password = BCrypt::Password.create(password)
		db.execute("INSERT INTO users(username, password) VALUES(?,?)", [username, password])
	
		session[:user_id] = db.execute("SELECT id FROM users WHERE username = ?", [username]).first["id"]
	
		redirect("/")
	end
	
	
	def db_connect()
		db = SQLite3::Database.new("db.sqlite3")
		db.results_as_hash = true
		return db
	end
	
	def is_logged_in()
		user_id = session[:user_id]
		if user_id == nil
			return false
		else
			return true
		end
	end
end