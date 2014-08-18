# purpose: command line interface for databases

# TODO
# * varied output: Dumper, long, wide
# * command abbrev, ex: help
# * more than one database
# * "rr"
#
# DONE
# * command dispatch
# * prompt runs sqls instead of calc

use Modern::Perl '2013';
use warnings FATAL => 'all';
our$TEMPLATE_VERSION='v0.1.12';

package DBSH
{

use Carp;
use Data::Dumper;
use DBI;
use File::HomeDir;
use Hash::Util qw(lock_keys);
use IO::File;
our $VAR1;

my $home = File::HomeDir->my_home;

my $persist_file="$home/.dbsh";
my $do_persist=0;
my $DEBUG=0;

use Term::ReadLine;

our $VERSION = 'v0.0.1';
my @keys = qw(
    argv
    commands
    dbsh_switch1
    dbsh_switch2
    history_file
    password_file
    input_file
    switches
    term
);

sub run {
    my ( $self, @argv ) = @_;
    $self->{argv} = \@argv;

    $self->check_inputs();

    $self->main_dbsh_run();
    $self->freeze_me();
    return 0;    # return for entire script template
}

sub main_dbsh_run {
    my ($self) = @_;

    $self->init();

    $self->load_history();

    $self->command_loop();

    return;
}

sub init {
    my ($self) = @_;
    $self->{history_file} = "$home/.dbsh_history";
    $self->{password_file} = "$home/.dbsh_password";
    $self->{term} = Term::ReadLine->new('squeeeeps');

    $self->{commands} = {
        help => {
            method => 'get_help',
            help => 'Get help on something',
        },
        e => {
            method => 'do_edit',
            help => 'Edit a previous command',
        },
        q => {
            method => 'do_quit',
            help => 'Quit',
        },
    };
    return;
}

sub command_loop {
    my ($self) = @_;
    my $term = $self->{term};
    my $OUT = $term->OUT || \*STDOUT;
    my $prompt = "dbsh > ";

    my $ofh = IO::File->new($self->{history_file}, '>>');
    die if (!defined $ofh);

    my ($database,$hostname,$port) = ('menagerie','localhost',3306);
    my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";

    my $user = 'dmb';
    my $password = $self->get_password();

    my $dbh = DBI->connect($dsn, $user, $password);

    my $sth;
    while ( defined ($_ = $term->readline($prompt)) ) {
        chomp;
        exit if $_ eq 'q';

        my ($first_word) = /(\w+)/;
        if ( $self->{commands}->{$first_word} ) {
            my $method = $self->{commands}->{$first_word}->{method};
            print $self->$method(), "\n";
        }
        else {
            $sth = $dbh->prepare($_);
            $sth->execute;
            while (my $ref = $sth->fetchrow_hashref()) {
                print Dumper($ref);
            }
            $sth->finish();

            warn $@ if $@;
        }

        $term->addhistory($_) if /\S/;
        print $ofh "$_\n";
    }
    $dbh->disconnect();
    $ofh->close;
}

sub do_edit {
    my ($self) = @_;
    my $retval = 'edit stub';
    return;
}

sub do_quit {
    my ($self) = @_;
    exit;
}

sub get_password {
    my ($self) = @_;
    my $password = slurp_file($self->{password_file});
    for ( $password ) {
        s/^\s*//;
        s/\s*$//;
    }
    return $password;
}

sub slurp_file {
    my $filename = shift;

    die "Not an object method" if ref $filename;

    my $ifh = IO::File->new($filename, '<');
    die if (!defined $ifh);

    my $contents = do { local $/; <$ifh> };

    $ifh->close;

    return $contents;
}

sub get_help {
    my ($self) = @_;

    my $retval;
    for ( keys %{$self->{commands}} ) {
        $retval .= sprintf("%-6s$self->{commands}->{$_}->{help}\n", $_);
    }
    return $retval;
}

sub load_history {
    my ($self) = @_;
    my $term = $self->{term};

    my $ifh = IO::File->new($self->{history_file}, '<');
    return if (!defined $ifh);

    while(<$ifh>) {
        chomp;
        $term->addhistory($_) if /\S/;
    }
    $ifh->close;
    return;
}

sub usage {
    croak "This is a function, not a method" if ( ref $_[0] );

    return <<EOF;
Usage: dbsh [OPTION]...
Command line interface for databases
Example: dbsh

-s, --some-something     Cause something to happen sometime

EOF
}

sub check_inputs {
    my ( $self ) = @_;
    my %valid_switch = (
        '-a' => 'dbsh_switch1',
        '-b' => 'dbsh_switch2',
    );
    while ( my $arg = shift( @{ $self->{argv} } ) ) {
        if ( $arg =~ /^(-.*)/ ) {
            my $switch = $1;
            if ( $switch eq '-?' or $switch eq '-h' or $switch eq '--help' )
            {
                print STDERR usage();
                exit 2;
            }
            if ( !$valid_switch{$switch} ) {
                errout("bad switch $switch");
            }
            $self->{ $valid_switch{$switch} }++;
        }
        else {    # template start non-switch args
            if ( @{ $self->{argv} } > 0 )
            {     # template how many input files allowed
                errout(
                    message  => "too many input files",
                    no_usage => 1
                );
            }
            if ( !-r $arg ) {
                errout(
                    message  => "can't read file \"$arg\"",
                    no_usage => 1
                );
            }
            $self->{input_file} = $arg;
            last;
        }
    }
    # template remove "0 &&" to turn on
    if ( 0 && !$self->{input_file} ) {
        errout(
            message  => "no valid input files provided",
            no_usage => 1
        );
    }
    # template remove "0 &&" to turn on
    if ( 0 && ( !$self->{dbsh_switch1} and !$self->{dbsh_switch2} )
           or ( $self->{dbsh_switch1} and $self->{dbsh_switch2} ) )
    {
        errout("must use either -a or -b");
    }
}

 # ================== END MAIN =================================================

    sub new {
        my ($class) = @_;

        my $self = {};
        bless $self, $class;
        thaw_me( \$self );
        lock_keys( %$self, @keys );

        return $self;
    }

    sub errout {
        croak "This is a function, not a method" if ( ref $_[0] );

        my %params;
        if ( @_ == 1 ) {
            $params{message} = $_[0];
        }
        else {
            %params = @_;
        }
        my $message = "error: $params{message}\n";
        if ( !$params{no_usage} ) {
            $message .= usage();
        }
        die $message;
    }

    sub thaw_me {
        return unless $do_persist;

        my ($self) = @_;

        return unless thaw($persist_file);

        ${$self} = $VAR1;

        if ($DEBUG) {
            warn "thawed!\n", Dumper($self);
        }
        if ( !defined $self ) {
            croak "failed eval of dump";
        }
    }

    sub freeze_me {
        return unless $do_persist;

        my ($self) = @_;
        $self->freeze( $persist_file, $self );
    }

    sub thaw {
        croak "This is a function, not a method" if ( ref $_[0] );

        my ($filename) = @_;

        my $ifh = IO::File->new( $filename, '<' );
        return if ( !defined $ifh );

        my $contents = do { local $/; <$ifh> };
        $ifh->close;

        return eval $contents;
    }

    sub freeze {
        croak "This is a function, not a method" if ( ref $_[0] );

        my ( $filename, $ref ) = @_;

        my $ofh = IO::File->new( $filename, '>' );
        croak "Failed to open output file: $!" if ( !defined $ofh );

        print $ofh Dumper($ref);
        $ofh->close;
    }

    sub random {
        croak "This is a function, not a method" if ( ref $_[0] );

        my ( $max, $min ) = @_;

        $min //= 1;
        if ( $min > $max ) {
            ( $min, $max ) = ( $max, $min );
        }
        my $range = $max - $min;
        return int( rand( $range + 1 ) ) + $min;
    }

    # example
    # my @dot_files = grep { /^\./ && -f "$some_dir/$_" } get_directory($target);
    sub get_directory {
        croak "This is a function, not a method" if ( ref $_[0] );

        my ($dir) = @_;
        $dir ||= '.';

        opendir(my $dh, $dir) || die "can't opendir $dir: $!";
        my @files = readdir($dh);
        closedir $dh;

        return @files;
    }
}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MyDocumentation - Perl extension for blah blah blah

=head1 SYNOPSIS

  use MyDocumentation;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for MyDocumentation, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut






























