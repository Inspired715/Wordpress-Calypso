<?php
/**
 * List all contributors to this release.
 *
 * Usage: wp --require=utils/contrib-list.php contrib-list
 */

use WP_CLI\Utils;

class Contrib_List_Command {

	/**
	 * List all contributors to this release.
	 *
	 * Run within the main WP-CLI project repository.
	 *
	 * ## OPTIONS
	 *
	 * [--format=<format>]
	 * : Render output in a specific format.
	 * ---
	 * default: markdown
	 * options:
	 *   - markdown
	 *   - html
	 *   - count
	 * ---
	 *
	 * @when before_wp_load
	 */
	public function __invoke( $_, $assoc_args ) {

		$contributors = array();

		// Get the contributors to the current open wp-cli/wp-cli milestone
		$milestones = self::get_project_milestones( 'wp-cli/wp-cli' );
		// Cheap way to get the latest milestone
		$milestone = array_shift( $milestones );
		WP_CLI::log( 'Current open wp-cli/wp-cli milestone: ' . $milestone->title );
		$pull_requests = self::get_project_milestone_pull_requests( 'wp-cli/wp-cli', $milestone->number );
		$contributors = array_merge( $contributors, self::parse_contributors_from_pull_requests( $pull_requests ) );

		// Get the contributors to the current open wp-cli/handbook milestone
		$milestones = self::get_project_milestones( 'wp-cli/handbook' );
		// Cheap way to get the latest milestone
		$milestone = array_shift( $milestones );
		WP_CLI::log( 'Current open wp-cli/handbook milestone: ' . $milestone->title );
		$pull_requests = self::get_project_milestone_pull_requests( 'wp-cli/handbook', $milestone->number );
		$contributors = array_merge( $contributors, self::parse_contributors_from_pull_requests( $pull_requests ) );

		// Identify all command dependencies and their contributors
		$response = Utils\http_request( 'GET', 'https://raw.githubusercontent.com/wp-cli/wp-cli/master/composer.json' );
		if ( 200 !== $response->status_code ) {
			WP_CLI::error( sprintf( 'Could not fetch composer.json (HTTP code %d)', $response->status_code ) );
		}
		$composer_json = json_decode( $response->body, true );
		foreach( $composer_json['require'] as $package => $version_constraint ) {
			if ( ! preg_match( '#^wp-cli/.+-command$#', $package ) ) {
				continue;
			}
			// Normalize version constraint to something ew can compare
			$version_constraint = ltrim( $version_constraint, '^' );
			// Closed milestones denote a tagged release
			$milestones = self::get_project_milestones( $package, array( 'state' => 'closed' ) );
			$milestone_ids = array();
			$milestone_titles = array();
			foreach( $milestones as $milestone ) {
				if ( ! version_compare( $milestone->title, $version_constraint, '>' ) ) {
					continue;
				}
				$milestone_ids[] = $milestone->number;
				$milestone_titles[] = $milestone->title;
			}
			// No shipped releases for this milestone.
			if ( empty( $milestone_ids ) ) {
				continue;
			}
			WP_CLI::log( 'Closed ' . $package . ' milestone(s): ' . implode( ', ', $milestone_titles ) );
			foreach( $milestone_ids as $milestone_id ) {
				$pull_requests = self::get_project_milestone_pull_requests( $package, $milestone_id );
				$contributors = array_merge( $contributors, self::parse_contributors_from_pull_requests( $pull_requests ) );
			}
		}

		// Sort and render the contributor list
		asort( $contributors, SORT_NATURAL | SORT_FLAG_CASE );
		if ( in_array( $assoc_args['format'], array( 'markdown', 'html' ) ) ) {
			$contrib_list = '';
			foreach( $contributors as $url => $login ) {
				if ( 'markdown' === $assoc_args['format'] ) {
					$contrib_list .= '[' . $login . '](' . $url . '), ';
				} elseif ( 'html' === $assoc_args['format'] ) {
					$contrib_list .= '<a href="' . $url . '">' . $login . '</a>, ';
				}
			}
			$contrib_list = rtrim( $contrib_list, ', ' );
			WP_CLI::log( $contrib_list );
		} else if ( 'count' === $assoc_args['format'] ) {
			WP_CLI::log( count( $contributors ) );
		}
	}

	/**
	 * Get the milestones for a given project
	 *
	 * @param string $project
	 * @return array
	 */
	private static function get_project_milestones( $project, $args = array() ) {
		$request_url = sprintf( 'https://api.github.com/repos/%s/milestones', $project );
		list( $body, $headers ) = self::make_github_api_request( $request_url, $args );
		return $body;
	}

	/**
	 * Get the pull requests assigned to a milestone of a given project
	 *
	 * @param string $project
	 * @param integer $milestone_id
	 * @return array
	 */
	private static function get_project_milestone_pull_requests( $project, $milestone_id ) {
		$request_url = sprintf( 'https://api.github.com/repos/%s/issues', $project );
		$args = array(
			'milestone' => $milestone_id,
			'state'     => 'all',
		);
		$pull_requests = array();
		do {
			list( $body, $headers ) = self::make_github_api_request( $request_url, $args );
			foreach( $body as $issue ) {
				if ( ! empty( $issue->pull_request ) ) {
					$pull_requests[] = $issue;
				}
			}
			$args = array();
			$request_url = false;
			// Set $request_url to 'rel="next" if present'
			if ( ! empty( $headers['Link'] ) ) {
				$bits = explode( ',', $headers['Link'] );
				foreach( $bits as $bit ) {
					if ( false !== stripos( $bit, 'rel="next"' ) ) {
						$hrefandrel = explode( '; ', $bit );
						$request_url = trim( $hrefandrel[0], '<>' );
						break;
					}
				}
			}
		} while( $request_url );
		return $pull_requests;
	}

	/**
	 * Parse the contributors from pull request objects
	 *
	 * @param array $pull_requests
	 * @return array
	 */
	private static function parse_contributors_from_pull_requests( $pull_requests ) {
		$contributors = array();
		foreach( $pull_requests as $pull_request ) {
			if ( ! empty( $pull_request->user ) ) {
				$contributors[ $pull_request->user->html_url ] = $pull_request->user->login;
			}
		}
		return $contributors;
	}

	/**
	 * Make a request to the GitHub API
	 *
	 * @param string $url
	 * @param string $args
	 * @return array
	 */
	private static function make_github_api_request( $url, $args = array() ) {
		$headers = array(
			'Accept'     => 'application/vnd.github.v3+json',
			'User-Agent' => 'WP-CLI',
		);
		if ( $token = getenv( 'GITHUB_TOKEN' ) ) {
			$headers['Authorization'] = 'token ' . $token;
		}
		$response = Utils\http_request( 'GET', $url, $args, $headers );
		if ( 200 !== $response->status_code ) {
			WP_CLI::error( sprintf( 'GitHub API returned: %s (HTTP code %d)', $response->body, $response->status_code ) );
		}
		return array( json_decode( $response->body ), $response->headers );
	}

}

WP_CLI::add_command( 'contrib-list', 'Contrib_List_Command' );
