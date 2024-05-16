// Generate a random number to ensure a unique username
const randomNum = Math.floor(Math.random() * 10000);
const username = `reviewuser${randomNum}`;

describe('Registration Test', () => {
  it('should register a new user with correct details', () => {    
    
    // Visit the home page
    cy.visit('http://localhost:9292/');

    // Click the "Register" link
    cy.contains('a', 'Register').click();

    // Type in the username
    cy.get('input#username').type(username); 

    // Type in the password
    cy.get('input#password').type('password'); 

    // Confirm the password
    cy.get('input#confirm_password').type('password'); 

    // Select the role user from the radio button
    cy.get('input#user').check(); 
    cy.get('input#user').should('be.checked');

    // Press the register button
    cy.get('#submit_form').click();

    // Verify successful registration
    cy.url().should('include', '/'); 
    cy.contains(`Logged in as ${username}`).should('be.visible');

  });

});


describe('Review Test', () => {
  it('should test the users ability to add a review', () => {

    // Go to the login page
    cy.visit('http://localhost:9292/login');

    // Type in the username
    cy.get('input#username').type(username); 

    // Type in the password
    cy.get('input#password').type('password'); 

    // Press the login button
    cy.get('#submit_form').click();

    // Select the most top-rated release on the page
    cy.contains('h2', 'Top Rated Releases').parent()
    .find('button[type="submit"]:contains("VIEW")').first().click();

    // Fill out review text
    cy.get('textarea#review_text').type('This is a test review.');

    // Fill out rating
    cy.get('input#rating').type('8');

    // Submit the review
    cy.get('button[type="submit"]').contains('Submit review').click();

    // Verify that the review was added successfully
    cy.contains('This is a test review.').should('be.visible');
    cy.contains('Rating: 8/10').should('be.visible');

    // Go back to landing page
    cy.visit('http://localhost:9292/');
  });
});