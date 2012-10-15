<?php

/**
 * Wrapper class for WP-CLI
 *
 * @package wp-cli
 */
class WP_CLI {

	private static $commands = array();

	/**
	 * Add a command to the wp-cli list of commands
	 *
	 * @param string $name The name of the command that will be used in the cli
	 * @param string $class The class to manage the command
	 */
	public function add_command( $name, $class ) {
		if ( is_string( $class ) )
			$command = new \WP_CLI\Dispatcher\CompositeCommand( $name, $class );
		else
			$command = new \WP_CLI\Dispatcher\SingleCommand( $name, $class );

		self::$commands[ $name ] = $command;
	}

	/**
	 * Display a message in the cli
	 *
	 * @param string $message
	 */
	static function out( $message ) {
		if ( WP_CLI_QUIET ) return;
		\cli\out($message);
	}

	/**
	 * Display a message in the CLI and end with a newline
	 *
	 * @param string $message
	 */
	static function line( $message = '' ) {
		if ( WP_CLI_QUIET ) return;
		\cli\line($message);
	}

	/**
	 * Display an error in the CLI and end with a newline
	 *
	 * @param string $message
	 * @param string $label
	 */
	static function error( $message, $label = 'Error' ) {
		if ( !WP_CLI_AUTOCOMPLETE ) {
			\cli\err( '%R' . $label . ': %n' . self::error_to_string( $message ) );
		}

		exit(1);
	}

	/**
	 * Display a success in the CLI and end with a newline
	 *
	 * @param string $message
	 * @param string $label
	 */
	static function success( $message, $label = 'Success' ) {
		if ( WP_CLI_QUIET ) return;
		\cli\line( '%G' . $label . ': %n' . $message );
	}

	/**
	 * Display a warning in the CLI and end with a newline
	 *
	 * @param string $message
	 * @param string $label
	 */
	static function warning( $message, $label = 'Warning' ) {
		if ( WP_CLI_QUIET ) return;
		\cli\err( '%C' . $label . ': %n' . self::error_to_string( $message ) );
	}

	/**
	 * Read a value, from various formats
	 *
	 * @param mixed $value
	 * @param array $assoc_args
	 */
	static function read_value( $value, $assoc_args = array() ) {
		if ( isset( $assoc_args['json'] ) ) {
			$value = json_decode( $value, true );
		}

		return $value;
	}

	/**
	 * Display a value, in various formats
	 *
	 * @param mixed $value
	 * @param array $assoc_args
	 */
	static function print_value( $value, $assoc_args = array() ) {
		if ( isset( $assoc_args['json'] ) ) {
			$value = json_encode( $value );
		} elseif ( is_array( $value ) || is_object( $value ) ) {
			$value = var_export( $value );
		}

		echo $value . "\n";
	}

	/**
	 * Convert a wp_error into a string
	 *
	 * @param mixed $errors
	 * @return string
	 */
	static function error_to_string( $errors ) {
		if( is_string( $errors ) ) {
			return $errors;
		} elseif( is_wp_error( $errors ) && $errors->get_error_code() ) {
			foreach( $errors->get_error_messages() as $message ) {
				if( $errors->get_error_data() )
					return $message . ' ' . $errors->get_error_data();
				else
					return $message;
			}
		}
	}

	/**
	 * Composes positional and associative arguments into a string.
	 *
	 * @param array
	 * @return string
	 */
	static function compose_args( $args, $assoc_args = array() ) {
		$str = ' ' . implode( ' ', array_map( 'escapeshellarg', $args ) );

		foreach ( $assoc_args as $key => $value ) {
			if ( true === $value )
				$str .= " --$key";
			else
				$str .= " --$key=" . escapeshellarg( $value );
		}

		return $str;
	}

	static function get_numeric_arg( $args, $index, $name ) {
		if ( ! isset( $args[$index] ) ) {
			WP_CLI::error( "$name required" );
		}

		if ( ! is_numeric( $args[$index] ) ) {
			WP_CLI::error( "$name must be numeric" );
		}

		return $args[$index];
	}

	/**
	 * Launch an external process, closing the current one
	 *
	 * @param string Command to call
	 * @param bool Whether to exit if the command returns an error status
	 *
	 * @return int The command exit status
	 */
	static function launch( $command, $exit_on_error = true ) {
		$r = proc_close( proc_open( $command, array( STDIN, STDOUT, STDERR ), $pipes ) );

		if ( $r && $exit_on_error )
			exit($r);

		return $r;
	}

	static function load_all_commands() {
		foreach ( array( 'internals', 'community' ) as $dir ) {
			foreach ( glob( WP_CLI_ROOT . "/commands/$dir/*.php" ) as $filename ) {
				$command = substr( basename( $filename ), 0, -4 );

				if ( isset( self::$commands[ $command ] ) )
					continue;

				include $filename;
			}
		}

		return self::$commands;
	}

	static function run_command( $arguments, $assoc_args ) {
		if ( empty( $arguments ) ) {
			$command = 'help';
		} else {
			$command = array_shift( $arguments );

			$aliases = array(
				'sql' => 'db'
			);

			if ( isset( $aliases[ $command ] ) )
				$command = $aliases[ $command ];
		}

		define( 'WP_CLI_COMMAND', $command );

		$command = self::load_command( $command );

		$command->invoke( $arguments, $assoc_args );
	}

	static function load_command( $command ) {
		if ( !isset( WP_CLI::$commands[$command] ) ) {
			foreach ( array( 'internals', 'community' ) as $dir ) {
				$path = WP_CLI_ROOT . "/commands/$dir/$command.php";

				if ( is_readable( $path ) ) {
					include $path;
					break;
				}
			}
		}

		if ( !isset( WP_CLI::$commands[$command] ) ) {
			WP_CLI::error( "'$command' is not a registered wp command. See 'wp help'." );
			exit;
		}

		return WP_CLI::$commands[$command];
	}

	// back-compat
	static function addCommand( $name, $class ) {
		self::add_command( $name, $class );
	}
}

