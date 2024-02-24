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

    # --- ADD A RELEASE ---
    get '/add' do
        erb :add
    end

    post '/release/add' do
        id = params["id"]
        name = params["name"]
        artist = params["artist"]
        length = params["length"]
        type = params["type"]
        genre = params["genre"]
        release_date = params["release_date"]
        artwork_file = params["release_artwork"]
        
        # Save the uploaded file to the server
        File.open('public/artwork/' + artwork_file[:filename], "w") do |f|
            f.write(artwork_file[:tempfile].read)
        end

        puts(artwork_file[:filename])

        query = 'INSERT INTO releases (name, artist, length, type, genre, release_date, image_path) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id'
        result = db.execute(query, name, artist, length, type, genre, release_date, "/artwork/" + artwork_file[:filename]).first 

        redirect "/"
    end
    # ------


    # --- REMOVE A RELEASE ---
    post '/release/remove/:id' do |id| 
        db.execute('DELETE FROM releases WHERE id = ?', id)
        redirect "/"
    end
    # ------

    # --- EDIT A RELEASE ---
    get '/edit/:id' do |id|
        @release_info = db.execute("SELECT * FROM releases WHERE id = ?", id)
        @release_info = @release_info[0]
        erb :edit
    end

    post '/release/edit/:id' do |id|
        name = params["name"]
        artist = params["artist"]
        length = params["length"]
        type = params["type"]
        genre = params["genre"]
        release_date = params["release_date"]
        artwork_file = params["release_artwork"]

        # First check if artwork file is empty since its not neccesarry for the user to update, if it is --> then just update the rest of the information
        if artwork_file == nil
            query = "UPDATE releases SET name = ?, artist = ?, length = ?, rating = ?, type = ?, genre = ?, release_date = ? WHERE id = ?"
            result = db.execute(query, name, artist, length, rating, type, genre, release_date, id)

        else 

            # [to-do] Remove the old image

            # Save the uploaded file to the server
            File.open('public/artwork/' + artwork_file[:filename], "w") do |f|
                f.write(artwork_file[:tempfile].read)
            end

            # Update the database        
            query = "UPDATE releases SET name = ?, artist = ?, length = ?, rating = ?, type = ?, genre = ?, release_date = ?, image_path = ? WHERE id = ?"
            result = db.execute(query, name, artist, length, rating, type, genre, release_date, "/artwork/" + artwork_file[:filename], id)

         end
            
        redirect "/"
    end
    # ------

    # --- VIEW A RELEASE ---
    get '/view/:id' do |id|
        @release_info = db.execute("SELECT * FROM releases WHERE id = ?", id)
        @release_info = @release_info[0]

        @review_info = db.execute("SELECT * FROM reviews WHERE release_id = ?", id)

        erb :view
    end

    # --- REVIEW A RELEASE ---
    post '/release/review/:id' do |release_id| 
        review_rating = params["rating"]
        review_text = params["review_text"]
        username = "bob"
        
        query = 'INSERT INTO reviews (release_id, username, review_rating, review_text) VALUES (?, ?, ?, ?) RETURNING id'
        result = db.execute(query, release_id, username, review_rating, review_text)
    
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