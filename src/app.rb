class App < Sinatra::Base

    enable :sessions

    def db
        return @db if @db
        @db = SQLite3::Database.new('./db/music.sqlite')
        @db.results_as_hash = true
        return @db
    end

    get '/' do
        session[:user_id] = 1 
        @releases = db.execute("SELECT * FROM releases")
        erb :index
       # puts("test")
    end

    get '/add' do
        erb :add
    end

    post '/release/add' do
        name = params["name"]
        artist = params["artist"]
        length = params["length"]
        rating = params["rating"]
        type = params["type"]
        rating = params["rating"]
        genre = params["genre"]
        release_date = params["release_date"]

        query = 'INSERT INTO releases (name, artist, length, rating, type, genre, release_date) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id'
        result = db.execute(query, name, artist, length, rating, type, genre, release_date).first 

        redirect "/"
    end


    post '/release/remove/:id' do |id| 
        db.execute('DELETE FROM releases WHERE id = ?', id)
        redirect "/"
    end

    get '/edit/:id' do |id|
        @release_info = db.execute("SELECT * FROM releases WHERE id = ?", id)
        @release_info = @release_info[0]
        erb :edit
    end

    post '/release/edit/:id' do |id|
        name = params["name"]
        artist = params["artist"]
        length = params["length"]
        rating = params["rating"]
        type = params["type"]
        genre = params["genre"]
        release_date = params["release_date"]

        query = "UPDATE releases SET name = ?, artist = ?, length = ?, rating = ?, type = ?, genre = ?, release_date = ? WHERE id = ?"
        result = db.execute(query, name, artist, length, rating, type, genre, release_date, id)
        
        redirect "/"
    end

    # Credentials handling
    get '/login' do 
        erb :login
    end


    post '/login/validate' do 
        # Retrieve the username and password from the form
        username = params["username"]
        password = params["password"]

        # Retrieve the password hash for that username from the database
        correct_password_hash = db.execute("SELECT password_hash FROM credentials WHERE username = ?", username).first

        # Hash the retrieved form password
        password_hash = BCrypt::Password.create(password)

        puts(correct_password_hash)
        puts(password_hash)


        # Compare the hashes
        if correct_password_hash && BCrypt::Password.new(correct_password_hash["password_hash"]) == password
            puts("correct password")
            erb :login

        else 
            puts("you put in incorrect password")
            redirect "/"
        end
    end

    # Credentials handling
    get '/register' do 
        erb :register
    end    

     post '/register' do 
        # Retrieve the username and password from the form
        username = params["username"]
        password = params["password"]

        # Hash the retrieved form password
        password_hash = BCrypt::Password.create(password)

        # Set the status
        status = "admin"

        query = 'INSERT INTO credentials (status, username, password_hash) VALUES (?, ?, ?) RETURNING id'
        result = db.execute(query, status, username, password_hash).first
        

        
    end


    


end