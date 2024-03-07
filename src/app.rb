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
        @artists = db.execute("SELECT * FROM artists")

        erb :index
       # puts("test")
    end

    # -- GENERAL FUNCTIONS ---
    def get_artist_name_from_id(artist_id)
        puts(artist_id.to_s)
        artist = db.execute("SELECT name FROM artists WHERE id = ?", artist_id).first
        artist ? artist["name"] : "Unknown"
    end

    #---

    # -- RELEASES --
    # --- ADD A RELEASE ---
    get '/release/add' do
        @artists = db.execute("SELECT * FROM artists")

        erb :release_add
    end

    post '/release/add' do
        id = params["id"]
        title = params["title"]
        artist_id = params["artist_id"]
        length = params["length"]
        type = params["type"]
        genre = params["genre"]
        release_date = params["release_date"]
        artwork_file = params["release_artwork"]

        puts(artist_id.to_s)
        puts("----")

        # Check if there is a file uploaded
        if !(artwork_file == nil)
            # Save the uploaded file to the server
            File.open('public/artwork/' + artwork_file[:filename], "w") do |f|
                f.write(artwork_file[:tempfile].read)
            end
            image_path = "/artwork/" + artwork_file[:filename]
            puts(image_path)
        else
            image_path = nil
            puts("No blody image path")
        end



        # Insert the release data into the database
        query = 'INSERT INTO releases (title, artist_id, length, type, genre, release_date, image_path) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id'
        result = db.execute(query, title, artist_id, length, type, genre, release_date, image_path).first 
        redirect "/"
    end
    # ------
    # --- REMOVE A RELEASE ---
    post '/release/remove/:id' do |id| 

        # Remove reviews associated with the release
        db.execute('DELETE FROM reviews WHERE release_id = ?', id)

        # Remove the release
        db.execute('DELETE FROM releases WHERE id = ?', id)
        
        redirect "/"
    end

    # ------
    # --- EDIT A RELEASE ---
    get '/release/edit/:id' do |id|
        @release_info = db.execute("SELECT * FROM releases WHERE id = ?", id)
        @release_info = @release_info[0]

        @artists = db.execute("SELECT * FROM artists")

        erb :release_edit
    end

    post '/release/edit/:id' do |id|
        title = params["title"]
        artist_id = params["artist_id"]
        length = params["length"]
        type = params["type"]
        genre = params["genre"]
        release_date = params["release_date"]
        artwork_file = params["release_artwork"]

        # First check if artwork file is empty since its not neccesarry for the user to update, if it is --> then just update the rest of the information
        if artwork_file == nil
            query = "UPDATE releases SET title = ?, artist_id = ?, length = ?, type = ?, genre = ?, release_date = ? WHERE id = ?"
            result = db.execute(query, title, artist_id, length, type, genre, release_date, id)

        else 

            # [to-do] Remove the old image

            # Save the uploaded file to the server
            File.open('public/artwork/' + artwork_file[:filename], "w") do |f|
                f.write(artwork_file[:tempfile].read)
            end

            # Update the database        
            query = "UPDATE releases SET title = ?, artist_id = ?, length = ?, rating = ?, type = ?, genre = ?, release_date = ?, image_path = ? WHERE id = ?"
            result = db.execute(query, title, artist_id, length, rating, type, genre, release_date, "/artwork/" + artwork_file[:filename], id)

         end
            
        redirect "/"
    end
    # ------
    # --- VIEW A RELEASE ---
    get '/release/view/:id' do |id|
        @release_info = db.execute("SELECT * FROM releases WHERE id = ?", id)
        @release_info = @release_info[0]

        @review_info = db.execute("SELECT * FROM reviews WHERE release_id = ?", id)
       
        # Calculate the total rating of the release
        total_rating = 0
        count = 0
        unless @review_info.empty?
            @review_info.each do |review|
                total_rating += review['review_rating']
                count += 1
            end
        end
    
        @total_rating = count == 0 ? "None" : (total_rating / count).round(2)    

        erb :release_view
    end

    # --- REVIEW A RELEASE ---
    post '/release/review/:id' do |release_id| 
        review_rating = params["rating"]
        review_text = params["review_text"]
        username = "bob"
        
        query = 'INSERT INTO reviews (release_id, username, review_rating, review_text) VALUES (?, ?, ?, ?) RETURNING id'
        result = db.execute(query, release_id, username, review_rating, review_text)
    
        redirect "/view/#{release_id}"
    end

    # -- ARTIST --
    # --- ADD AN ARTIST ---
    get '/artist/add' do
        erb :artist_add
    end

    post '/artist/add' do
        id = params["id"]
        name = params["name"]
        bio = params["bio"]
        country = params["country"]
        city = params["city"]
        logo_file = params["logo"]

        # Check if there is a file uploaded
        if !(logo_file == nil)
            # Save the uploaded file to the server
            File.open('public/artwork/' + logo_file[:filename], "w") do |f|
                f.write(logo_file[:tempfile].read)
            end
            image_path = "/artwork/" + logo_file[:filename]
         else
        image_path = nil
    end

        query = 'INSERT INTO artists (name, bio, country, city, image_path) VALUES (?, ?, ?, ?, ?) RETURNING id'
        result = db.execute(query, name, bio, country, city, image_path)

        redirect "/"
    end
    # ------
    # --- REMOVE AN ARTIST ---
    post '/artist/remove/:id' do |id| 
        # Remove releases associated with the artist
        db.execute('DELETE FROM releases WHERE artist_id = ?', id)
        
        # Remove reviews associated with the releases deleted
        db.execute('DELETE FROM reviews WHERE release_id NOT IN (SELECT id FROM releases)')
    
        # Remove the artist
        db.execute('DELETE FROM artists WHERE id = ?', id)
        
        redirect "/"
    end
        

     # --- EDIT AN ARTIST ---
     get '/artist/edit/:id' do |id|
        @artist_info = db.execute("SELECT * FROM artists WHERE id = ?", id)
        @artist_info = @artist_info[0]
        erb :artist_edit
    end

    post '/artist/edit/:id' do |id|
        id = params["id"]
        name = params["name"]
        bio = params["bio"]
        country = params["country"]
        city = params["city"]
        logo_file = params["logo"]

        # First check if artwork file is empty since its not neccesarry for the user to update, if it is --> then just update the rest of the information
        if logo_file == nil
            query = "UPDATE artists SET name = ?, bio = ?, country = ?, city = ? WHERE id = ?"
            result = db.execute(query, name, bio, country, city, id)

        else 

            # [to-do] Remove the old image

            # Save the uploaded file to the server
            image_path = "/logos/" + logo_file[:filename]

            File.open('public/' + image_path, "w") do |f|
                f.write(logo_file[:tempfile].read)
            end

            # Update the database        
            query = "UPDATE artists SET name = ?, bio = ?, country = ?, city = ?, image_path = ? WHERE id = ?"
            result = db.execute(query, name, bio, country, city, image_path, id)

         end
            
        redirect "/"
    end
    # ------
    # --- VIEW AN ARTISTS ---
    get '/artist/view/:id' do |id|
        @artist_info = db.execute("SELECT * FROM artists WHERE id = ?", id)
        @artist_info = @artist_info[0]

        erb :artist_view
    end
   

    # --- SEARCH FOR A RELEASE OR ARTIST --- (As of right now one can only search for releases, this may be uodated in the future so also artists can be searched)
    get "/release/search/" do
        # Get the search query from params
        @query = params[:query]

        # Perform the search based on the query 
        @release_results = db.execute("SELECT * FROM releases WHERE title LIKE ?", "%#{@query}%")
        @artist_results = db.execute("SELECT * FROM artists WHERE name LIKE ?", "%#{@query}%")

        erb :search_result


    end


    # Credentials handling
    get '/login' do 
        erb :login
    end

    post '/login' do 
        # Retrieve the username and password from the form
        username = params["username"]
        password = params["password"]
    
        # Retrieve the user info for the username from the database
        user = db.execute('SELECT * FROM users WHERE username = ?', username).first
    
        # Ensure the user exists
        if user.nil?
            puts("User not found")
            redirect "/"
        end
    
        # Retrieve the hashed password from the database
        stored_password_hash = user['password']
    
        # Compare the entered password with the hashed password from the database
        if BCrypt::Password.new(stored_password_hash) == password
            session[:user_id] = user['id'] 
            puts("Correct password")
        else 
            puts("Incorrect password")
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
        role = "admin"

        query = 'INSERT INTO users (role, username, password) VALUES (?, ?, ?) RETURNING id'
        result = db.execute(query, role, username, password_hash).first

        redirect "/login"
        

        
    end


    


end