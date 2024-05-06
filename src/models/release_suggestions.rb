module Release_suggestions 

    def self.all 
        db.execute('SELECT * FROM release_suggestions')
    end

    def self.find(id) 
        db.execute('SELECT * FROM release_suggestions WHERE id = ?', id).first
    end

    def self.insert(title, artist_id, length, type, genre, release_date, artwork_file, username)
        # Check if there is a file uploaded
        if !(artwork_file == nil)

            # Save the uploaded file to the server
            File.open('public/artwork/' + artwork_file[:filename], "w") do |f|
                f.write(artwork_file[:tempfile].read)
            end

            # Save the image path for saving in the database
            image_path = "/artwork/" + artwork_file[:filename]
        end

        # Insert the release into the database
        query = 'INSERT INTO release_suggestions (title, artist_id, length, type, genre, release_date, image_path, username) VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING id'
        result = db.execute(query, title, artist_id, length, type, genre, release_date, image_path, username).first         
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