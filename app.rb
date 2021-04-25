require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
  slim(:welcome)
end

get('/showlogin') do
  slim(:login)
end

get('/register') do
  slim(:register)
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.open('db/todo2021.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    p "Inloggning med användare med id #{id}"
    p "Inloggning med användare med sessionsid #{session[:id]}"
    db.close if db
    redirect('/todos/sida1')
  else
    "fel"
  end
  db.close if db
end 

get('/todos/sida1') do
  id = -1
  if session and session[:id] then
    id = session[:id].to_i
  else
    redirect('/showlogin')  
  end
  db = SQLite3::Database.open('db/todo2021.db')
  db.results_as_hash = true
  
  dbstring = "SELECT * FROM todos WHERE user_id = #{id}"
  p "SQL sats #{dbstring}" 
  result = db.execute(dbstring)
  p "Lngd av result #{result.length}"
  p "alla todos #{result}"
  
  db.close if db

  slim(:"todos/index",locals:{todos:result,user_id:id})
end


post("/users") do
username = params[:username]
password = params[:password]
password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest=BCrypt::Password.create(password)
    db = SQLite3::Database.new("db/todo2021.db")
    db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",username,password_digest)
    result = db.execute("SELECT id FROM users WHERE username = ?",username).first
    p "Lngd av result #{result.length}" 
    p "Result #{result[0]}"  
    session[:id] = result[0]
    p "sparar sessionen nytt id #{session[:id]}"
    redirect("/todos/sida1")
  else
    "Lösenorden matchade inte"
  end

  
end

post('/todos/:id/delete') do
  id = params[:id].to_i 
  db = SQLite3::Database.new("db/todo2021.db")
  db.execute("DELETE FROM todos WHERE id = ?",id)
  redirect('/todos/sida1')
end

post('/todos/newtodo') do
  dag = params[:day]
  övning = params[:content]
  id = -1
  if session and session[:id] then
    id = session[:id].to_i
  else
    redirect('/showlogin')  
  end

  p "Vi fick in datan #{dag} och #{övning}"
  db = SQLite3::Database.new("db/todo2021.db")
  db.execute("INSERT INTO todos (day, content, user_id) VALUES (?,?,?)",dag, övning, id)
  redirect('/todos/sida1')
end