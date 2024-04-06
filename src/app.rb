class App < Sinatra::Base
    enable :sessions

    # Anti-bruteforce login configuration
    maximum_login_attempts = 5
    login_cooldown = 60
    @@login_attempts = Hash.new { |hash, key|hash[key] = {attempts: 0, last_attempt: Time.now - login_cooldown - 1}}

    def db
        return @db if @db
        @db = SQLite3::Database.new('./db/music.sqlite')
        @db.results_as_hash = true
        return @db
    end

    # Function to protect against html attacks (to prevent users from typing in javascript to be executed when i print out stuff)
    def html_escape(text)
        Rack::Utils.escape_html(text)
    end
    
    get '/' do
        @hot_releases = db.execute("SELECT * FROM releases ORDER BY clicks DESC LIMIT 10")

        top_releases_query = "SELECT r.* FROM releases r
        JOIN reviews rv ON r.id = rv.release_id
        GROUP BY r.id
        ORDER BY AVG(review_rating) DESC
        LIMIT 5"
        @top_releases = db.execute(top_releases_query)

        erb :index
    end

    # --- VIEW ALL LISTINGS ---
    get "/listings" do
        @releases = db.execute("SELECT * FROM releases")
        @artists = db.execute("SELECT * FROM artists")

        erb :listings
    end
    # --- 
   
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
        # First check if the user is logged in
        if session[:username]
            @artists = db.execute("SELECT * FROM artists")
            erb :release_add
        else
            redirect '/'
        end
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
            puts("No bloody image path")
        end


        # Check if the user is an admin or an user
        if (session[:role] == "admin")
            # Insert the release data into the release database
            query = 'INSERT INTO releases (title, artist_id, length, type, genre, release_date, image_path) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id'
            result = db.execute(query, title, artist_id, length, type, genre, release_date, image_path).first 
            redirect "/release/view/#{db.last_insert_row_id}"

        elsif (session[:role] == "user")
            # Insert the release data into the suggestion database
            query = 'INSERT INTO release_suggestions (title, artist_id, length, type, genre, release_date, image_path, username) VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING id'
            result = db.execute(query, title, artist_id, length, type, genre, release_date, image_path, session[:username]).first 
            redirect "/suggestions"
        end
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

        # Increase a click for the release in the database
        result = db.execute("UPDATE releases SET clicks = clicks + 1 WHERE id = ?", id)
        
        # Handle the error message for reviews
        error_message = session.delete(:error_message)

        erb :release_view, locals: { error_message: error_message }
    end

    # --- REVIEW A RELEASE ---
    post '/release/review/:id' do |release_id| 
        review_rating = params["rating"]
        review_text = params["review_text"]

        # First check if a user has posted a review, if so, prevent user from posting again
        existing_review = db.execute("SELECT review.id FROM reviews AS review 
        JOIN releases AS release ON review.release_id = release.id 
        WHERE review.username = ? AND release.id = ?", [session[:username], release_id]).first

        if existing_review
            session[:error_message] = "You can only post one review per release"
            redirect "/release/view/#{release_id}"
        end
        
        query = 'INSERT INTO reviews (release_id, username, review_rating, review_text) VALUES (?, ?, ?, ?) RETURNING id'
        result = db.execute(query, release_id, session[:username], review_rating, review_text)
    
        redirect "/release/view/#{release_id}"
    end

    # --- APPROVE A RELEASE ---
    post '/release/suggestion/approve/:id' do |id|
        
        # Retrieve data from the suggestions table with the specified ID
        suggestion = db.execute("SELECT * FROM release_suggestions WHERE id = ?", id).first

        # Insert the extracted data into the releases table
        query = 'INSERT INTO releases (title, artist_id, length, type, genre, release_date, image_path) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id'
        result = db.execute(query, suggestion['title'], suggestion['artist_id'], suggestion['length'], suggestion['type'], suggestion['genre'], suggestion['release_date'], suggestion['image_path']).first 
        
        # Remove the release from the suggestions table
        query_delete = 'DELETE FROM release_suggestions WHERE id = ?'
        db.execute(query_delete, id)

        # Redirect
        redirect "/suggestions"

    end

    # --- REJECT A RELEASE ---
    post '/release/suggestion/reject/:id' do |id|

        # Remove the release from the suggestions table
        query_delete = 'DELETE FROM release_suggestions WHERE id = ?'
        db.execute(query_delete, id)

        # Redirect
        redirect "/suggestions"

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

        # Check if the user is an admin or an user
        if (session[:role] == "admin")
            # Insert the release data into the release database
            query = 'INSERT INTO artists (name, bio, country, city, image_path) VALUES (?, ?, ?, ?, ?)'
            result = db.execute(query, name, bio, country, city, image_path)
            redirect "/artist/view/#{db.last_insert_row_id}"

        elsif (session[:role] == "user")
            # Insert the release data into the suggestion database
            query = 'INSERT INTO artist_suggestions (name, bio, country, city, image_path, username) VALUES (?, ?, ?, ?, ?, ?)'
            result = db.execute(query, name, bio, country, city, image_path, session[:username])
            redirect "/suggestions"
        end
        

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

        @releases = db.execute("SELECT * FROM releases WHERE artist_id = ?", id)

        erb :artist_view
    end

    # --- APPROVE AN ARTIST ---
    post '/artist/suggestion/approve/:id' do |id|
        
        # Retrieve data from the suggestions table with the specified ID
        artist = db.execute("SELECT * FROM artist_suggestions WHERE id = ?", id).first

        # Insert the extracted data into the releases table
        query = 'INSERT INTO artists (name, bio, country, city, image_path) VALUES (?, ?, ?, ?, ?)'
        result = db.execute(query, artist['name'], artist['bio'], artist['country'], artist['city'], artist['image_path'])
        
        # Remove the release from the suggestions table
        query_delete = 'DELETE FROM artist_suggestions WHERE id = ?'
        db.execute(query_delete, id)

        # Redirect
        redirect "/suggestions"

    end

    # --- REJECT AN ARTIST ---
    post '/artist/suggestion/reject/:id' do |id|

        # Remove the release from the suggestions table
        query_delete = 'DELETE FROM artist_suggestions WHERE id = ?'
        db.execute(query_delete, id)

        # Redirect
        redirect "/suggestions"

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

    # --- HANDLE SUGGESTION GET REQUEST ---
    get '/suggestions' do
        @artist_suggestions = db.execute("SELECT * FROM artist_suggestions")
        @release_suggestions = db.execute("SELECT * FROM release_suggestions")

        erb :suggestions
    end

    # Login handling
    get '/login' do 
        # Retrieve the error message and delete it
        error_message = session.delete(:error_message)

        # Redirect
        erb :login, locals: { error_message: error_message }
    end

    post '/login' do 
        # Retrieve the username and password from the form
        username = params["username"]
        password = params["password"]

        # Check if the cooldown time has passed
        if (Time.now - @@login_attempts[username][:last_attempt] > login_cooldown)
            @@login_attempts[username][:attempts] = 0
        end

        # Check the amount of login attempts
        if (@@login_attempts[username][:attempts] >= maximum_login_attempts)
            session[:error_message] = "Too many login attempts. Please try again later."
            redirect "/login"
        end

        # Retrieve the user info for the username from the database
        user = db.execute('SELECT * FROM users WHERE username = ?', username).first
    
        # Ensure the user exists
        if user.nil?
            session[:error_message] = "User is not found"

            @@login_attempts[username][:attempts] += 1
            @@login_attempts[username][:last_attempt] = Time.now

            redirect "/login"
        end
    
        # Retrieve the hashed password from the database
        stored_password_hash = user['password']
    
        # Compare the entered password with the hashed password from the database
        if BCrypt::Password.new(stored_password_hash) == password
            session[:user_id] = user['id'] 
            session[:username] = username
            session[:role] = user['role']

            puts(session[:user_id])
            puts(session[:username])
            puts(session[:role])

            @@login_attempts[username][:attempts] = 0
            @@login_attempts[username][:last_attempt] = Time.now

            redirect "/"

        else 
            session[:error_message] = "Password is incorrect"

            @@login_attempts[username][:attempts] += 1
            @@login_attempts[username][:last_attempt] = Time.now

            redirect '/login'        
        end

        
    end
    
    # Register handling
    get '/register' do 
        error_message = session.delete(:error_message)

        erb :register, locals: { error_message: error_message }
    end    

     post '/register' do 
        # Retrieve the username and password from the form
        username = params["username"]
        password = params["password"]
        password_confirm = params["confirm_password"]
        role = params["role"]

        # Check if passwords match
        if password != password_confirm
            session[:error_message] = "Passwords do not match"
            redirect '/register'
        end

        # Hash the retrieved form password
        password_hash = BCrypt::Password.create(password)

        # Try to insert into the database
        begin
            query = 'INSERT INTO users (role, username, password) VALUES (?, ?, ?)'
            result = db.execute(query, role, username, password_hash).first

        rescue SQLite3::ConstraintException => e
            session[:error_message] = "Username is already taken"
            redirect '/register'

        rescue => e
            session[:error_message] = "An error occurred while processing your request"
            redirect '/register'
        end
    
        session[:user_id] = db.last_insert_row_id 
        session[:username] = username
        session[:role] = role

        redirect "/"
        
    end

    # Handle the logout request
    get '/logout' do
        if (session[:username])
            session.clear
            redirect '/'
        end
    end


    


end