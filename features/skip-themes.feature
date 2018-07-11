Feature: Skipping themes

  Scenario: Skipping themes via global flag
    Given a WP installation
    And I run `wp theme install classic`
    And I run `wp theme install default --activate`

    When I run `wp eval 'var_export( function_exists( "kubrick_head" ) );'`
    Then STDOUT should be:
      """
      true
      """
    And STDERR should be empty

    # The specified theme should be skipped
    When I run `wp --skip-themes=default eval 'var_export( function_exists( "kubrick_head" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty
    
    # All themes should be skipped
    When I run `wp --skip-themes eval 'var_export( function_exists( "kubrick_head" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty
    
    # Skip another theme
    When I run `wp --skip-themes=classic eval 'var_export( function_exists( "kubrick_head" ) );'`
    Then STDOUT should be:
      """
      true
      """
    And STDERR should be empty
    
    # The specified theme should still show up as an active theme
    When I run `wp --skip-themes theme status default`
    Then STDOUT should contain:
      """
      Active
      """
    And STDERR should be empty

    # Skip several themes
    When I run `wp --skip-themes=classic,default eval 'var_export( function_exists( "kubrick_head" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

  @require-wp-4.4
  Scenario: Skip parent and child themes
    Given a WP installation
    And I run `wp theme install primer stout`

    When I run `wp theme activate primer`
    When I run `wp eval 'var_export( function_exists( "primer_setup" ) );'`
    Then STDOUT should be:
      """
      true
      """
    And STDERR should be empty

    When I run `wp --skip-themes=primer eval 'var_export( function_exists( "primer_setup" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    When I run `wp theme activate stout`
    When I run `wp eval 'var_export( function_exists( "primer_setup" ) );'`
    Then STDOUT should be:
      """
      true
      """
    And STDERR should be empty

    When I run `wp eval 'var_export( function_exists( "stout_move_elements" ) );'`
    Then STDOUT should be:
      """
      true
      """
    And STDERR should be empty

    When I run `wp --skip-themes=stout eval 'var_export( function_exists( "primer_setup" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    When I run `wp --skip-themes=stout eval 'var_export( function_exists( "stout_move_elements" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty

    When I run `wp --skip-themes=stout eval 'echo get_template_directory();'`
    Then STDOUT should contain:
      """
      wp-content/themes/primer
      """
    And STDERR should be empty

    When I run `wp --skip-themes=biker eval 'echo get_stylesheet_directory();'`
    Then STDOUT should contain:
      """
      wp-content/themes/stout
      """
    And STDERR should be empty

  Scenario: Skipping multiple themes via config file
    Given a WP installation
    And a wp-cli.yml file:
      """
      skip-themes:
        - classic
        - default
      """
    And I run `wp theme install classic --activate`
    And I run `wp theme install default`
    
    # The classic theme should show up as an active theme
    When I run `wp theme status`
    Then STDOUT should contain:
      """
      A classic
      """
    And STDERR should be empty

    # The default theme should show up as an installed theme
    When I run `wp theme status`
    Then STDOUT should contain:
      """
      I default
      """
    And STDERR should be empty
    
    And I run `wp theme activate default`

    # The default theme should be skipped
    When I run `wp eval 'var_export( function_exists( "kubrick_head" ) );'`
    Then STDOUT should be:
      """
      false
      """
    And STDERR should be empty
