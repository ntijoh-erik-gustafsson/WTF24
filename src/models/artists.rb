module Artists 

    def self.all 
        db.execute('SELECT * FROM artists')
    end

    def self.find(id) 
        db.execute('SELECT * FROM artists WHERE id = ?', id).first
    end

    def self.most_popular(amount) 
        db.execute('SELECT * FROM artists ORDER BY popularity DESC LIMIT ?', amount)
    end

    def self.insert(name, bio, country, city, logo_file, suggestion)
        if suggestion
            query = 'INSERT INTO artists (name, bio, country, city, image_path) VALUES (?, ?, ?, ?, ?)'
            result = db.execute(query, name, bio, country, city, logo_file)
        else
            if (logo_file == nil)
                # Upload the artist to the database without image path
                query = 'INSERT INTO artists (name, bio, country, city, image_path) VALUES (?, ?, ?, ?, ?)'
                result = db.execute(query, name, bio, country, city, nil)
            else  
                filename = logo_file[:filename]
                filepath = 'public/artwork/' + filename
        
                # Check if the file doesn't exist
                unless File.exist?(filepath)
                    # Save the uploaded file to the server
                    File.open(filepath, "w") do |f|
                        f.write(logo_file[:tempfile].read)
                    end
                end
        
                # Get the image path
                image_path = "/artwork/" + filename
        
                # Upload the artist to the database
                query = 'INSERT INTO artists (name, bio, country, city, image_path) VALUES (?, ?, ?, ?, ?)'
                result = db.execute(query, name, bio, country, city, image_path)
            end
        end
    
        db.last_insert_row_id # Return the last inserted row ID
    end
        
    def self.remove(id)
        # Remove releases associated with the artist
        db.execute('DELETE FROM releases WHERE artist_id = ?', id)
        
        # Remove reviews associated with the releases deleted
        db.execute('DELETE FROM reviews WHERE release_id NOT IN (SELECT id FROM releases)')
    
        # Remove the artist
        db.execute('DELETE FROM artists WHERE id = ?', id)

    end

    def self.update(id, name, bio, country, city, logo_file)

        # First check if an artist logo exists or not
        if (logo_file == nil)
            query = "UPDATE artists SET name = ?, bio = ?, country = ?, city = ? WHERE id = ?"
            result = db.execute(query, name, bio, country, city, id)
        else
            # Save the uploaded file to the server
            image_path = "/logos/" + logo_file[:filename]

            File.open('public/' + image_path, "w") do |f|
                f.write(logo_file[:tempfile].read)
            end

            query = "UPDATE artists SET name = ?, bio = ?, country = ?, city = ?, image_path = ? WHERE id = ?"
            result = db.execute(query, name, bio, country, city, image_path, id)
        end
    end

    def self.search(keyword)
        db.execute("SELECT * FROM artists WHERE name LIKE ?", "%#{keyword}%")
    end

    def self.get_artist_name_from_artist_id(artist_id)
        artist = db.execute("SELECT name FROM artists WHERE id = ?", artist_id).first
        artist ? artist["name"] : "Unknown"
    end


    def self.db 
        if @db == nil
            @db = SQLite3::Database.new('./db/music.sqlite')
            @db.results_as_hash = true
        end
        return @db
    end

    

end