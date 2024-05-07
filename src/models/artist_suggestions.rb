module Artist_suggestions 

    def self.all 
        db.execute('SELECT * FROM artist_suggestions')
    end

    def self.find(id) 
        db.execute('SELECT * FROM artist_suggestions WHERE id = ?', id).first
    end

    def self.insert(name, bio, country, city, logo_file, username)
        # Check if there is an image in the form
         if !(logo_file == nil)

            # Save the uploaded file to the server
            File.open('public/artwork/' + logo_file[:filename], "w") do |f|
                f.write(logo_file[:tempfile].read)
            end

            # Get the image path
            image_path = "/artwork/" + logo_file[:filename]
        else
            image_path = nil
        end

        query = 'INSERT INTO artist_suggestions (name, bio, country, city, image_path, username) VALUES (?, ?, ?, ?, ?, ?) RETURNING id'        
        result = db.execute(query, name, bio, country, city, image_path, username).first 

    end

    def self.remove(id)
        db.execute('DELETE FROM artist_suggestions WHERE id = ?', id)
    end

    def self.db 
        if @db == nil
            @db = SQLite3::Database.new('./db/music.sqlite')
            @db.results_as_hash = true
        end
        return @db
    end

end