module Releases 

    def self.all 
        db.execute('SELECT * FROM releases')
    end

    def self.find(id) 
        db.execute('SELECT * FROM releases WHERE id = ?', id).first
    end

    def self.remove(id)
        # Remove reviews associated with the release
        db.execute('DELETE FROM reviews WHERE release_id = ?', id)

        # Remove the release
        db.execute('DELETE FROM releases WHERE id = ?', id)
    end

    def self.update_without_image(title, length, type, genre, release_date, id)
        query = "UPDATE releases SET title = ?, length = ?, type = ?, genre = ?, release_date = ? WHERE id = ?"
        result = db.execute(query, title, length, type, genre, release_date, id)
    end

    def self.update_with_image(title, length, type, genre, release_date, artwork_file, id)
        query = "UPDATE releases SET title = ?, length = ?, rating = ?, type = ?, genre = ?, release_date = ?, image_path = ? WHERE id = ?"
        result = db.execute(query, title, length, rating, type, genre, release_date, "/artwork/" + artwork_file[:filename], id)
    end

    def self.most_popular(amount) 
        result = db.execute('SELECT * FROM releases ORDER BY clicks DESC LIMIT ?', amount)
        result.empty? ? nil : result

    end

    def self.highest_reviewed(amount) 
        top_releases_query = "SELECT r.* FROM releases r
        JOIN reviews rv ON r.id = rv.release_id
        GROUP BY r.id
        ORDER BY AVG(review_rating) DESC
        LIMIT 5"    

        result = db.execute(top_releases_query)
        result.empty? ? nil : result

    end

    def self.get_genres()
        db.execute("SELECT * FROM genres")
    end

    def self.get_genre_by_id(genre_id)
        result = db.execute("SELECT name FROM genres WHERE id = ?", genre_id).first
        result["name"] if result

    end
    

    def self.insert(title, artist_id, length, type, genre, release_date, image_path)
        query = 'INSERT INTO releases (title, artist_id, length, type, genre, release_date, image_path) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id'
        result = db.execute(query, title, artist_id, length, type, genre, release_date, image_path).first 
        db.last_insert_row_id # Return the last inserted row ID

    end

    def self.increase_click(id)
        result = db.execute("UPDATE releases SET clicks = clicks + 1 WHERE id = ?", id)
    end

    def self.search(keyword)
        db.execute("SELECT * FROM releases WHERE title LIKE ?", "%#{keyword}%")

    end

    def self.db 
        if @db == nil
            @db = SQLite3::Database.new('./db/music.sqlite')
            @db.results_as_hash = true
        end
        return @db
    end

end