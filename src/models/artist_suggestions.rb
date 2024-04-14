module Artist_suggestions 

    def self.all 
        @db.execute('SELECT * FROM artist_suggestions')
    end

    def self.find(id) 
        @db.execute('SELECT * FROM artist_suggestions WHERE id = ?', id).first
    end

    def self.insert(title, artist_id, length, type, genre, release_date, image_path)
        query = 'INSERT INTO artist_suggestions (title, artist_id, length, type, genre, release_date, image_path, username) VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING id'        
        result = db.execute(query, title, artist_id, length, type, genre, release_date, image_path, session[:username]).first 

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