describe('App Functionality Tests', () => {
  it('should register a new user', () => {
    cy.visit('/') // Visit the homepage
    cy.contains('Register').click() // Click on the register link
    cy.get('input[name="username"]').type('newuser') // Fill in the username
    cy.get('input[name="password"]').type('password123') // Fill in the password
    cy.get('input[name="confirm_password"]').type('password123') // Confirm password
    cy.get('input[name="role"][value="user"]').check() // Select user role
    cy.contains('Register').click() // Submit the registration form
    cy.contains('Welcome, newuser').should('be.visible') // Check if the user is welcomed
  })

  it('should register a new admin', () => {
    cy.visit('/') // Visit the homepage
    cy.contains('Register').click() // Click on the register link
    cy.get('input[name="username"]').type('newadmin') // Fill in the username
    cy.get('input[name="password"]').type('adminpassword123') // Fill in the password
    cy.get('input[name="confirm_password"]').type('adminpassword123') // Confirm password
    cy.get('input[name="role"][value="admin"]').check() // Select admin role
    cy.contains('Register').click() // Submit the registration form
    cy.contains('Welcome, newadmin').should('be.visible') // Check if the admin is welcomed
  })

  it('should display error message if passwords do not match', () => {
    cy.visit('/') // Visit the homepage
    cy.contains('Register').click() // Click on the register link
    cy.get('input[name="username"]').type('user') // Fill in the username
    cy.get('input[name="password"]').type('password123') // Fill in the password
    cy.get('input[name="confirm_password"]').type('password456') // Fill in a different confirmation password
    cy.get('input[name="role"][value="user"]').check() // Select user role
    cy.contains('Register').click() // Submit the registration form
    cy.contains('Passwords do not match').should('be.visible') // Check if error message is displayed
  })

  // Add more tests for other edge cases...
})
