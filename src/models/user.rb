module User 

    def self.get_user_info(username)
        db.execute('SELECT * FROM users WHERE username = ?', username).first
    end

    def self.insert(username, password_hash, role)
        query = 'INSERT INTO users (role, username, password) VALUES (?, ?, ?)'
        result = db.execute(query, role, username, password_hash).first
        db.last_insert_row_id # Return the last inserted row ID

    end


    def self.db 
        if @db == nil
            @db = SQLite3::Database.new('./db/music.sqlite')
            @db.results_as_hash = true
        end
        return @db
    end


end
   