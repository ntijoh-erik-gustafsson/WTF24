module Reviews 

    def self.all 
        db.execute('SELECT * FROM reviews')
    end

    def self.find_reviews_by_release_id(release_id)
        db.execute('SELECT * FROM reviews WHERE release_id = ?', release_id)
    end
      
    def self.insert(release_id, review_rating, review_text, username)
        query = 'INSERT INTO reviews (release_id, username, review_rating, review_text) VALUES (?, ?, ?, ?) RETURNING id'
        result = db.execute(query, release_id, username, review_rating, review_text)
    end

    def self.check_if_exist(username, release_id)
        result = db.execute("SELECT review.id FROM reviews AS review 
        JOIN releases AS release ON review.release_id = release.id 
        WHERE review.username = ? AND release.id = ?", username, release_id).first
        !result.nil? 
    end

    def self.calculate_total_rating(review_info)
        # Calculate the total rating of the release
        total_rating = 0
        count = 0
        unless review_info.nil? || review_info.empty?
            review_info.each do |review|
            total_rating += review['review_rating']
            count += 1
            end
        end
        
        return count == 0 ? "None" : (total_rating / count).round(2)
        
    end

    def self.db 
        if @db == nil
            @db = SQLite3::Database.new('./db/music.sqlite')
            @db.results_as_hash = true
        end
        return @db
    end


end