module Release_suggestions 

    def self.all 
        db.execute('SELECT * FROM release_suggestions')
    end

    def self.find(id) 
        db.execute('SELECT * FROM release_suggestions WHERE id = ?', id).first
    end

    def self.insert(title, artist_id, length, type, genres, release_date, artwork_file, username)
        # Check if there is a file uploaded
        if !(artwork_file == nil)

            # Save the uploaded file to the server
            File.open('public/artwork/' + artwork_file[:filename], "w") do |f|
                f.write(artwork_file[:tempfile].read)
            end

            # Save the image path for saving in the database
            image_path = "/artwork/" + artwork_file[:filename]
        end

        genre_arr = JSON.parse(genres)  # Parse the JSON string into an array
        genre_str = genre_arr.join(',')  # Convert array of genres to a comma-separated string
        query = 'INSERT INTO release_suggestions (title, artist_id, length, type, genre, release_date, image_path, username) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        db.execute(query, title, artist_id, length, type, genre_str, release_date, image_path, username)
    end
    
    def self.remove(id)
        db.execute('DELETE FROM release_suggestions WHERE id = ?', id)
    end

    def self.db 
        if @db == nil
            @db = SQLite3::Database.new('./db/music.sqlite')
            @db.results_as_hash = true
        end
        return @db
    end

end