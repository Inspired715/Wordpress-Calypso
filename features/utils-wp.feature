Feature: Utilities that depend on WordPress code

  Scenario: Get WP table names for single site install
    Given a WP install
    And I run `wp db query "CREATE TABLE xx_wp_posts ( id int );"`
    And I run `wp db query "CREATE TABLE wp_xx_posts ( id int );"`
    And I run `wp db query "CREATE TABLE wp_posts_xx ( id int );"`
    And I run `wp db query "CREATE TABLE wp_categories ( id int );"`
    And a table_names.php file:
      """
      <?php
      /**
       * Test WP get table names.
       *
       * ## OPTIONS
       *
       * [<table>...]
       * : List tables based on wildcard search, e.g. 'wp_*_options' or 'wp_post?'.
       *
       * [--scope=<scope>]
       * : Can be all, global, ms_global, blog, or old tables. Defaults to all.
       *
       * [--network]
       * : List all the tables in a multisite install. Overrides --scope=<scope>.
       *
       * [--all-tables-with-prefix]
       * : List all tables that match the table prefix even if not registered on $wpdb. Overrides --network.
       *
       * [--all-tables]
       * : List all tables in the database, regardless of the prefix, and even if not registered on $wpdb. Overrides --all-tables-with-prefix.
       */
      function test_wp_get_table_names( $args, $assoc_args ) {
        if ( $tables = WP_CLI\Utils\wp_get_table_names( $args, $assoc_args ) ) {
            echo implode( PHP_EOL, $tables ) . PHP_EOL;
        }
      }
      WP_CLI::add_command( 'get_table_names', 'test_wp_get_table_names' );
      """

    When I run `wp --require=table_names.php get_table_names`
    Then STDOUT should contain:
      """
      wp_commentmeta
      wp_comments
      wp_links
      wp_options
      wp_postmeta
      wp_posts
      wp_term_relationships
      wp_term_taxonomy
      """
	# Leave out wp_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_terms
      wp_usermeta
      wp_users
      """
    And save STDOUT as {DEFAULT_STDOUT}

    When I run `wp --require=table_names.php get_table_names --scope=all`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `wp --require=table_names.php get_table_names --scope=blog`
    Then STDOUT should contain:
      """
      wp_commentmeta
      wp_comments
      wp_links
      wp_options
      wp_postmeta
      wp_posts
      wp_term_relationships
      wp_term_taxonomy
      """
	# Leave out wp_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_terms
      """

    When I run `wp --require=table_names.php get_table_names --scope=global`
    Then STDOUT should be:
      """
      wp_usermeta
      wp_users
      """

    When I run `wp --require=table_names.php get_table_names --scope=ms_global`
    Then STDOUT should be empty

    When I run `wp --require=table_names.php get_table_names --scope=old`
    Then STDOUT should be:
      """
      wp_categories
      """

    When I run `wp --require=table_names.php get_table_names --network`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `wp --require=table_names.php get_table_names --all-tables-with-prefix`
    Then STDOUT should contain:
      """
      wp_categories
      wp_commentmeta
      wp_comments
      wp_links
      wp_options
      wp_postmeta
      wp_posts
      wp_posts_xx
      wp_term_relationships
      wp_term_taxonomy
      """
	# Leave out wp_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_terms
      wp_usermeta
      wp_users
      wp_xx_posts
      """

    When I run `wp --require=table_names.php get_table_names --all-tables`
    Then STDOUT should contain:
      """
      wp_categories
      wp_commentmeta
      wp_comments
      wp_links
      wp_options
      wp_postmeta
      wp_posts
      wp_posts_xx
      wp_term_relationships
      wp_term_taxonomy
      """
	# Leave out wp_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_terms
      wp_usermeta
      wp_users
      wp_xx_posts
      xx_wp_posts
      """

    When I run `wp --require=table_names.php get_table_names '*_posts'`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp_post*'`
    Then STDOUT should be:
      """
      wp_postmeta
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp*osts'`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names '*_posts' --scope=blog`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I try `wp --require=table_names.php get_table_names '*_posts' --scope=global`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: *_posts
      """
    And STDOUT should be empty

    When I run `wp --require=table_names.php get_table_names '*_posts' --network`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names '*_posts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      wp_posts
      wp_xx_posts
      """

    When I run `wp --require=table_names.php get_table_names '*wp_posts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp_post*' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      wp_postmeta
      wp_posts
      wp_posts_xx
      """

    When I run `wp --require=table_names.php get_table_names 'wp*osts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      wp_posts
      wp_xx_posts
      """

    When I run `wp --require=table_names.php get_table_names '*_posts' --all-tables`
    Then STDOUT should be:
      """
      wp_posts
      wp_xx_posts
      xx_wp_posts
      """

    When I run `wp --require=table_names.php get_table_names '*wp_posts' --all-tables`
    Then STDOUT should be:
      """
      wp_posts
      xx_wp_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp_post*' --all-tables`
    Then STDOUT should be:
      """
      wp_postmeta
      wp_posts
      wp_posts_xx
      """

    When I run `wp --require=table_names.php get_table_names 'wp*osts' --all-tables`
    Then STDOUT should be:
      """
      wp_posts
      wp_xx_posts
      """

    When I try `wp --require=table_names.php get_table_names non_existent_table`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: non_existent_table
      """
    And STDOUT should be empty

    When I run `wp --require=table_names.php get_table_names wp_posts non_existent_table`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names wp_posts non_existent_table 'wp_?ption*'`
    Then STDOUT should be:
      """
      wp_options
      wp_posts
      """

  Scenario: Get WP table names for multisite install
    Given a WP multisite install
    And I run `wp db query "CREATE TABLE xx_wp_posts ( id int );"`
    And I run `wp db query "CREATE TABLE xx_wp_2_posts ( id int );"`
    And I run `wp db query "CREATE TABLE wp_xx_posts ( id int );"`
    And I run `wp db query "CREATE TABLE wp_2_xx_posts ( id int );"`
    And I run `wp db query "CREATE TABLE wp_posts_xx ( id int );"`
    And I run `wp db query "CREATE TABLE wp_2_posts_xx ( id int );"`
    And I run `wp db query "CREATE TABLE wp_categories ( id int );"`
    And I run `wp db query "CREATE TABLE wp_sitecategories ( id int );"`
    And a table_names.php file:
      """
      <?php
      /**
       * Test WP get table names.
       *
       * ## OPTIONS
       *
       * [<table>...]
       * : List tables based on wildcard search, e.g. 'wp_*_options' or 'wp_post?'.
       *
       * [--scope=<scope>]
       * : Can be all, global, ms_global, blog, or old tables. Defaults to all.
       *
       * [--network]
       * : List all the tables in a multisite install. Overrides --scope=<scope>.
       *
       * [--all-tables-with-prefix]
       * : List all tables that match the table prefix even if not registered on $wpdb. Overrides --network.
       *
       * [--all-tables]
       * : List all tables in the database, regardless of the prefix, and even if not registered on $wpdb. Overrides --all-tables-with-prefix.
       */
      function test_wp_get_table_names( $args, $assoc_args ) {
        if ( $tables = WP_CLI\Utils\wp_get_table_names( $args, $assoc_args ) ) {
            echo implode( PHP_EOL, $tables ) . PHP_EOL;
        }
      }
      WP_CLI::add_command( 'get_table_names', 'test_wp_get_table_names' );
      """

    # With no subsite.
    When I run `wp --require=table_names.php get_table_names`
    Then STDOUT should contain:
      """
      wp_blog_versions
      wp_blogs
      wp_commentmeta
      wp_comments
      wp_links
      wp_options
      wp_postmeta
      wp_posts
      wp_registration_log
      wp_signups
      wp_site
      wp_sitemeta
      wp_term_relationships
      wp_term_taxonomy
      """
	# Leave out wp_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_terms
      wp_usermeta
      wp_users
      """
    And save STDOUT as {DEFAULT_STDOUT}

    When I run `wp --require=table_names.php get_table_names --scope=all`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `wp --require=table_names.php get_table_names --scope=blog`
    Then STDOUT should contain:
      """
      wp_commentmeta
      wp_comments
      wp_links
      wp_options
      wp_postmeta
      wp_posts
      wp_term_relationships
      wp_term_taxonomy
      """
	# Leave out wp_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_terms
      """

    When I run `wp --require=table_names.php get_table_names --scope=global`
    Then STDOUT should be:
      """
      wp_blog_versions
      wp_blogs
      wp_registration_log
      wp_signups
      wp_site
      wp_sitemeta
      wp_usermeta
      wp_users
      """
    And save STDOUT as {GLOBAL_STDOUT}

    When I run `wp --require=table_names.php get_table_names --scope=ms_global`
    Then STDOUT should be:
      """
      wp_blog_versions
      wp_blogs
      wp_registration_log
      wp_signups
      wp_site
      wp_sitemeta
      """

    When I run `wp --require=table_names.php get_table_names --scope=old`
    Then STDOUT should be:
      """
      wp_categories
      """

    When I run `wp --require=table_names.php get_table_names --network`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    # With subsite.
    Given I run `wp site create --slug=foo`
    When I run `wp --require=table_names.php get_table_names`
    Then STDOUT should be:
      """
      {DEFAULT_STDOUT}
      """

    When I run `wp --require=table_names.php get_table_names --url=example.com/foo --scope=blog`
    Then STDOUT should contain:
      """
      wp_2_commentmeta
      wp_2_comments
      wp_2_links
      wp_2_options
      wp_2_postmeta
      wp_2_posts
      wp_2_term_relationships
      wp_2_term_taxonomy
      """
	# Leave out wp_2_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_2_terms
      """
    And save STDOUT as {SUBSITE_BLOG_STDOUT}

    When I run `wp --require=table_names.php get_table_names --url=example.com/foo`
    Then STDOUT should be:
      """
      {SUBSITE_BLOG_STDOUT}
      {GLOBAL_STDOUT}
      """

    When I run `wp --require=table_names.php get_table_names --network`
    Then STDOUT should be:
      """
      {SUBSITE_BLOG_STDOUT}
      {DEFAULT_STDOUT}
      """
    And save STDOUT as {NETWORK_STDOUT}

    When I run `wp --require=table_names.php get_table_names --network --url=example.com/foo`
    Then STDOUT should be:
      """
      {NETWORK_STDOUT}
      """

    When I run `wp --require=table_names.php get_table_names --all-tables-with-prefix`
    Then STDOUT should contain:
      """
      wp_2_commentmeta
      wp_2_comments
      wp_2_links
      wp_2_options
      wp_2_postmeta
      wp_2_posts
      wp_2_posts_xx
      wp_2_term_relationships
      wp_2_term_taxonomy
      """
	# Leave out wp_2_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_2_terms
      wp_2_xx_posts
      wp_blog_versions
      wp_blogs
      wp_categories
      wp_commentmeta
      wp_comments
      wp_links
      wp_options
      wp_postmeta
      wp_posts
      wp_posts_xx
      wp_registration_log
      wp_signups
      wp_site
      wp_sitecategories
      wp_sitemeta
      wp_term_relationships
      wp_term_taxonomy
      """
	# Leave out wp_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_terms
      wp_usermeta
      wp_users
      wp_xx_posts
      """
    And save STDOUT as {ALL_TABLES_WITH_PREFIX_STDOUT}

    # Network overriden by all-tables-with-prefix.
    When I run `wp --require=table_names.php get_table_names --all-tables-with-prefix --network`
    Then STDOUT should contain:
      """
      {ALL_TABLES_WITH_PREFIX_STDOUT}
      """

    When I run `wp --require=table_names.php get_table_names --all-tables`
    Then STDOUT should be:
      """
      {ALL_TABLES_WITH_PREFIX_STDOUT}
      xx_wp_2_posts
      xx_wp_posts
      """
    And save STDOUT as {ALL_TABLES_STDOUT}

    # Network overriden by all-tables.
    When I run `wp --require=table_names.php get_table_names --all-tables --network`
    Then STDOUT should be:
      """
      {ALL_TABLES_STDOUT}
      """

    When I run `wp --require=table_names.php get_table_names '*_posts'`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names '*_posts' --network`
    Then STDOUT should be:
      """
      wp_2_posts
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp_post*'`
    Then STDOUT should be:
      """
      wp_postmeta
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp_post*' --network`
    Then STDOUT should be:
      """
      wp_postmeta
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp*osts'`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp*osts' --network`
    Then STDOUT should be:
      """
      wp_2_posts
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names '*_posts' --scope=blog`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names '*_posts' --scope=blog --network`
    Then STDOUT should be:
      """
      wp_2_posts
      wp_posts
      """

    When I try `wp --require=table_names.php get_table_names '*_posts' --scope=global`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: *_posts
      """
    And STDOUT should be empty

    # Note: BC change 1.5.0, network does not override scope.
    When I try `wp --require=table_names.php get_table_names '*_posts' --scope=global --network`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: *_posts
      """
    And STDOUT should be empty

    When I run `wp --require=table_names.php get_table_names '*_posts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      wp_2_posts
      wp_2_xx_posts
      wp_posts
      wp_xx_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp_post*' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      wp_postmeta
      wp_posts
      wp_posts_xx
      """

    When I run `wp --require=table_names.php get_table_names 'wp*osts' --all-tables-with-prefix`
    Then STDOUT should be:
      """
      wp_2_posts
      wp_2_xx_posts
      wp_posts
      wp_xx_posts
      """

    When I run `wp --require=table_names.php get_table_names '*_posts' --all-tables`
    Then STDOUT should be:
      """
      wp_2_posts
      wp_2_xx_posts
      wp_posts
      wp_xx_posts
      xx_wp_2_posts
      xx_wp_posts
      """

    When I run `wp --require=table_names.php get_table_names '*wp_posts' --all-tables`
    Then STDOUT should be:
      """
      wp_posts
      xx_wp_posts
      """

    When I run `wp --require=table_names.php get_table_names 'wp_post*' --all-tables`
    Then STDOUT should be:
      """
      wp_postmeta
      wp_posts
      wp_posts_xx
      """

    When I run `wp --require=table_names.php get_table_names 'wp*osts' --all-tables`
    Then STDOUT should be:
      """
      wp_2_posts
      wp_2_xx_posts
      wp_posts
      wp_xx_posts
      """

    When I try `wp --require=table_names.php get_table_names non_existent_table`
    Then STDERR should be:
      """
      Error: Couldn't find any tables matching: non_existent_table
      """
    And STDOUT should be empty

    When I run `wp --require=table_names.php get_table_names wp_posts non_existent_table`
    Then STDOUT should be:
      """
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names wp_posts non_existent_table 'wp_?ption*'`
    Then STDOUT should be:
      """
      wp_options
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names wp_posts non_existent_table 'wp_*ption?'`
    Then STDOUT should be:
      """
      wp_options
      wp_posts
      """

    When I run `wp --require=table_names.php get_table_names wp_posts non_existent_table 'wp_*ption?' --network`
    Then STDOUT should be:
      """
      wp_2_options
      wp_options
      wp_posts
      """

    Given an enable_sitecategories.php file:
      """
      <?php 
      WP_CLI::add_hook( 'after_wp_load', function () {
        add_filter( 'global_terms_enabled', '__return_true' );
      } );
      """
    When I run `wp --require=table_names.php --require=enable_sitecategories.php get_table_names`
    Then STDOUT should contain:
      """
      wp_blog_versions
      wp_blogs
      wp_commentmeta
      wp_comments
      wp_links
      wp_options
      wp_postmeta
      wp_posts
      wp_registration_log
      wp_signups
      wp_site
      wp_sitecategories
      wp_sitemeta
      wp_term_relationships
      wp_term_taxonomy
      """
	# Leave out wp_termmeta for old WP compat.
    And STDOUT should contain:
      """
      wp_terms
      wp_usermeta
      wp_users
      """
