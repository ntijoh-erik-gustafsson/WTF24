require_relative 'models/releases'
require_relative 'models/release_suggestions'
require_relative 'models/artists'
require_relative 'models/artist_suggestions'
require_relative 'models/user'
require_relative 'models/reviews'

class App < Sinatra::Base
    enable :sessions

    # Function to protect against html attacks (to prevent users from typing in javascript to be executed when i print out stuff)
    def html_escape(text)
        Rack::Utils.escape_html(text)
    end

    get '/' do  
        @hot_releases = Releases.most_popular(5)
        @top_releases = Releases.highest_reviewed(5)

        erb :index
    end

    # --- VIEW ALL LISTINGS ---
    get "/listings" do
        @releases = Releases.all
        @artists = Artists.all

        erb :listings
    end
    # --- 
   
    # -- GENERAL FUNCTIONS ---
    #---

    # -- RELEASES --
    # --- ADD A RELEASE ---
    get '/release/add' do
        # First check if the user is logged in
        if session[:username]

            # Retrieve all the artists and genres
            @artists = Artists.all
            @genres = Releases.get_genres

            # Redirect to the erb file for adding a release
            erb :release_add
            
        else
            # Otherwise redirect back to the index page
            redirect '/'
        end
    end

    post '/release/add' do
        # Check if the user is an admin or an user
        if (session[:role] == "admin")
            # Insert the release data into the release database
            release_id = Releases.insert(params["title"], params["artist_id"], params["length"], params["type"], params["genres"], params["release_date"], params["release_artwork"])
            redirect "/release/view/#{release_id}"

        elsif (session[:role] == "user")
            # Insert the release data into the suggestion database
            Release_suggestions.insert(params["title"], params["artist_id"], params["length"], params["type"], params["genres"], params["release_date"], params["release_artwork"], session[:username])
            redirect "/"
        end
    end
    # ------
    # --- REMOVE A RELEASE ---
    post '/release/remove/:id' do |id| 
        Releases.remove(id)
        redirect back
    end

    # ------
    # --- EDIT A RELEASE ---
    get '/release/edit/:id' do |id|
        @release_info = Releases.find(id) 
        @artists = Artists.all
        @genres = Releases.get_genres()

        erb :release_edit
    end

    post '/release/edit/:id' do |id|
        Releases.update(params["title"], params["length"], params["type"], params["genres"], params["release_date"], params["release_artwork"], id)    
        
        redirect "/release/view/" + id
    end
    # ------
    # --- VIEW A RELEASE ---
    get '/release/view/:id' do |id|
        @release_info = Releases.find(id)
        @review_info = Reviews.find_reviews_by_release_id(id)
        @total_rating = Reviews.calculate_total_rating(@review_info) 
      
        # Increase a click for the release in the database
        Releases.increase_click(id)
      
        # Handle the error message for reviews
        error_message = session.delete(:error_message)
      
        erb :release_view, locals: { error_message: error_message }
      end
      
    # --- REVIEW A RELEASE ---
    post '/release/review/:id' do |release_id| 
        # First check if a user has posted a review, if so, prevent user from posting again
        existing_review = Reviews.check_if_exist(session[:username], release_id)

        if existing_review
            session[:error_message] = "You can only post one review per release"
            redirect "/release/view/#{release_id}"
        end
        
        Reviews.insert(release_id, params["rating"], params["review_text"], session[:username])
        redirect "/release/view/#{release_id}"
    end

    # --- APPROVE A RELEASE ---
    post '/release/suggestion/approve/:id' do |id|
        
        # Retrieve data from the suggestions table with the specified ID
        suggestion = Release_suggestions.find(id)

        # Insert the extracted data into the releases table
        Releases.insert(suggestion['title'], suggestion['artist_id'], suggestion['length'], suggestion['type'], suggestion['genre'], suggestion['release_date'], suggestion['image_path'])
        
        # Remove the release from the suggestions table
        Release_suggestions.remove(id)

        # Redirect
        redirect "/suggestions"

    end

    # --- REJECT A RELEASE ---
    post '/release/suggestion/reject/:id' do |id|

        # Remove the release from the suggestions table
        Release_suggestions.remove(id)

        # Redirect
        redirect "/suggestions"

    end

    # -- ARTIST --
    # --- ADD AN ARTIST ---
    get '/artist/add' do
        erb :artist_add
    end

    post '/artist/add' do
        # Check if the user is an admin or an user
        if (session[:role] == "admin")
            # Insert the artist data into the release database
            artist_id = Artists.insert(params["name"], params["bio"], params["country"], params["city"], params["logo"], false)
            redirect "/artist/view/#{artist_id}"

        elsif (session[:role] == "user")
            # Insert the release data into the suggestion database
            Artist_suggestions.insert(params["name"], params["bio"], params["country"], params["city"], params["logo"], session[:username])
        end        

        redirect "/"
    end
    # ------
    # --- REMOVE AN ARTIST ---
    post '/artist/remove/:id' do |id| 
        Artists.remove(id)
        redirect back
    end
        
     # --- EDIT AN ARTIST ---
    get '/artist/edit/:id' do |id|
        @artist_info = Artists.find(id)
        erb :artist_edit
    end

    post '/artist/edit/:id' do |id|
        Artists.update(params["id"], params["name"], params["bio"], params["country"], params["city"], params["logo"])
        redirect "/artist/view/" + id
    end
    # ------
    # --- VIEW AN ARTISTS ---
    get '/artist/view/:id' do |id|
        @artist_info = Artists.find(id)
        @releases = Releases.find(id)

        erb :artist_view
    end

    # --- APPROVE AN ARTIST ---
    post '/artist/suggestion/approve/:id' do |id|

        # First retreive the data from the artist id
        artist = Artist_suggestions.find(id)

        # Insert the extracted data into the artists table
        Artists.insert(artist['name'], artist['bio'], artist['country'], artist['city'], artist['image_path'], true)
        
        # Retrieve data from the suggestions table with the specified ID
        Artist_suggestions.find(id)
        
        # Remove the release from the suggestions table
        Artist_suggestions.remove(id)

        # Redirect
        redirect "/suggestions"

    end

    # --- REJECT AN ARTIST ---
    post '/artist/suggestion/reject/:id' do |id|

        # Remove the release from the suggestions table
        Artist_suggestions.remove(id)

        # Redirect
        redirect "/suggestions"

    end

    # --- SEARCH FOR A RELEASE OR ARTIST --- (As of right now one can only search for releases, this may be uodated in the future so also artists can be searched)
    get "/release/search/" do
        # Get the search query from params
        @query = params[:query]

        # Perform the search based on the query 
        @release_results = Releases.search(@query)
        @artist_results = Artists.search(@query)

        erb :search_result


    end

    # --- HANDLE SUGGESTION GET REQUEST ---
    get '/suggestions' do
        @artist_suggestions = Artist_suggestions.all()
        @release_suggestions = Release_suggestions.all()

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

        if !(User.check_login())
            session[:error_message] = "Too many login attempts. Please try again later."
            redirect "/login"
        end

        # Retrieve the user info for the username from the database
        user = User.get_user_info(username)
    
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
            user_id = User.insert(username, password_hash, role)

        rescue SQLite3::ConstraintException => e
            session[:error_message] = "Username is already taken"
            redirect '/register'

        rescue => e
            puts(e.to_s)
            session[:error_message] = "An error occurred while processing your request"
            redirect '/register'
        end
    
        session[:user_id] = user_id 
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