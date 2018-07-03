Feature: Master

  Scenario: Master
    When I'm on the homepage
    And I accept cookies
    Then I should be on the homepage with an account button
    When I open the account page
    Then I should see the account screen
      And I choose "inloggen"
      And I enter account details
    Then I should be logged in
    When I press Start
    Then I should extract ticket data for music
