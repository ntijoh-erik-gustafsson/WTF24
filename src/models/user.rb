module User 
    # Anti-bruteforce login configuration
    MAXIMUM_LOGIN_ATTEMPTS = 5
    LOGIN_COOLDOWN = 60
    
    @@login_attempts = Hash.new { |hash, key|hash[key] = {attempts: 0, last_attempt: Time.now - LOGIN_COOLDOWN - 1}}


    def self.get_user_info(username)
        db.execute('SELECT * FROM users WHERE username = ?', username).first
    end

    def self.insert(username, password_hash, role)
        query = 'INSERT INTO users (role, username, password) VALUES (?, ?, ?)'
        result = db.execute(query, role, username, password_hash).first
        db.last_insert_row_id # Return the last inserted row ID
    end

    def self.check_cooldown(username)

      # Check if the cooldown time has passed
        if (Time.now - @@login_attempts[username][:last_attempt] > LOGIN_COOLDOWN)
            @@login_attempts[username][:attempts] = 0
        end

        # Check the amount of login attempts
        if (@@login_attempts[username][:attempts] >= MAXIMUM_LOGIN_ATTEMPTS)
            return false
        else
            return true
        end
    end

    def self.login(username, password)
        # Retreive all the user info
        user = self.get_user_info(username)

        # Compare the entered password with the hashed password from the database
        if BCrypt::Password.new(user['password']) == password
            @@login_attempts[username][:attempts] = 0
            @@login_attempts[username][:last_attempt] = Time.now

            return user['id'], user['role']

        else
            @@login_attempts[username][:attempts] += 1
            @@login_attempts[username][:last_attempt] = Time.now

            return false
        end
    end

    def self.register(username, password, role)
        # Try to insert data into the database
        begin
            return self.insert(username, password, role)
    
        rescue => e
            return e
        end
    end

    def self.db 
        if @db == nil
            @db = SQLite3::Database.new('./db/music.sqlite')
            @db.results_as_hash = true
        end
        return @db
    end


end
   