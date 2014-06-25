package SHARYANTO::Module::Path;

use 5.010001;
use strict;
use warnings;

use Function::Fallback::CoreOrPP qw(clone);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(module_path pod_path);

our $VERSION = '0.19'; # VERSION
our $DATE = '2014-06-25'; # DATE

my $SEPARATOR;

our %SPEC;

BEGIN {
    if ($^O =~ /^(dos|os2)/i) {
        $SEPARATOR = '\\';
    } elsif ($^O =~ /^MacOS/i) {
        $SEPARATOR = ':';
    } else {
        $SEPARATOR = '/';
    }
}

$SPEC{module_path} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl module',
    description => <<'_',

Search `@INC` (reference entries are skipped) and return path(s) to Perl module
files with the requested name.

This function is like the one from `Module::Path`, except with a different
interface and more options (finding all matches instead of the first, the option
of not absolutizing paths, finding `.pmc` & `.pod` files, finding module
prefixes).

_
    args => {
        module => {
            summary => 'Module name to search',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
            completion => sub {
                require Complete::Module;
                require Complete::Util;
                my %args = @_;
                #use DD; dd \%args;
                Complete::Util::mimic_shell_dir_completion(
                    completion => Complete::Module::complete_module(
                        word => $args{word},
                        separator => '/',
                        find_pm  => $args{args}{find_pm},
                        find_pmc => $args{args}{find_pmc},
                        find_pod => $args{args}{find_pod},
                        ci => 1,
                    ),
                );
            },
        },
        find_pm => {
            summary => 'Whether to find .pm files',
            schema  => 'bool',
            default => 1,
        },
        find_pmc => {
            summary => 'Whether to find .pmc files',
            schema  => 'bool',
            default => 1,
        },
        find_pod => {
            summary => 'Whether to find .pod files',
            schema  => 'bool',
            default => 0,
        },
        find_prefix => {
            summary => 'Whether to find module prefixes',
            schema  => 'bool',
            default => 1,
            cmdline_aliases => { p=>{} },
        },
        all => {
            summary => 'Return all results instead of just the first',
            schema  => 'bool',
            default => 0,
            cmdline_aliases => { a=>{} },
        },
        abs => {
            summary => 'Whether to return absolute paths',
            schema  => 'bool',
            default => 0,
            cmdline_aliases => { P=>{} },
        },
    },
    result => {
        schema => ['any' => of => ['str*', ['array*' => of => 'str*']]],
    },
    result_naked => 1,
};
sub module_path {
    my %args = @_;

    my $module = $args{module} or die "Please specify module";

    $args{abs}         //= 0;
    $args{all}         //= 0;
    $args{find_pm}     //= 1;
    $args{find_pmc}    //= 1;
    $args{find_pod}    //= 0;
    $args{find_prefix} //= 0;

    require Cwd if $args{abs};

    my @res;
    my $add = sub { push @res, $args{abs} ? Cwd::abs_path($_[0]) : $_[0] };

    my $relpath;

    ($relpath = $module) =~ s/::/$SEPARATOR/g;
    $relpath =~ s/\.(pm|pmc|pod)\z//i;

    foreach my $dir (@INC) {
        next if not defined($dir);
        next if ref($dir);

        my $prefix = $dir . $SEPARATOR . $relpath;
        if ($args{find_pmc}) {
            my $file = $prefix . ".pmc";
            if (-f $file) {
                $add->($file);
                last unless $args{all};
            }
        }
        if ($args{find_pm}) {
            my $file = $prefix . ".pm";
            if (-f $file) {
                $add->($file);
                last unless $args{all};
            }
        }
        if ($args{find_pod}) {
            my $file = $prefix . ".pod";
            if (-f $file) {
                $add->($file);
                last unless $args{all};
            }
        }
        if ($args{find_prefix}) {
            if (-d $prefix) {
                $add->($prefix);
                last unless $args{all};
            }
        }
    }

    if ($args{all}) {
        return \@res;
    } else {
        return @res ? $res[0] : undef;
    }
}

{
    my $spec = clone($SPEC{module_path});
    $spec->{summary} = 'Find path to Perl POD files',
    $spec->{summary} = 'Shortcut for `module_path(..., find_pm=>0, find_pmc=>0, find_pod=>1, find_prefix=>1, )`.';
    delete $spec->{args}{find_pm};
    delete $spec->{args}{find_pmc};
    delete $spec->{args}{find_pod};
    delete $spec->{args}{find_prefix};
    $spec->{args}{module}{completion} = sub {
        require Complete::Module;
        require Complete::Util;
        my %args = @_;
        #use DD; dd \%args;
        Complete::Util::mimic_shell_dir_completion(
            completion=>Complete::Module::complete_module(
                word => $args{word},
                separator => '/',
                find_pm  => 0,
                find_pmc => 0,
                find_pod => 1,
            ),
        );
    };
    $SPEC{pod_path} = $spec;
}
sub pod_path {
    my %args = @_;
    module_path(%args, find_pm=>0, find_pmc=>0, find_pod=>1, find_prefix=>0);
}

1;
# ABSTRACT: Get path to locally installed Perl module

__END__

=pod

=encoding UTF-8

=head1 NAME

SHARYANTO::Module::Path - Get path to locally installed Perl module

=head1 VERSION

This document describes version 0.19 of SHARYANTO::Module::Path (from Perl distribution SHARYANTO-Module-Path), released on 2014-06-25.

=head1 SYNOPSIS

 use SHARYANTO::Module::Path 'module_path', 'pod_path';

 $path = module_path(module=>'Test::More');
 if (defined($path)) {
   print "Test::More found at $path\n";
 } else {
   print "Danger Will Robinson!\n";
 }

 # find all found modules, as well as .pmc and .pod files
 @path = module_path(module=>'Foo::Bar', all=>1, find_pmc=>1, find_pod=>1);

 # just a shortcut for module_path(module=>'Foo',
                                   find_pm=>0, find_pmc=>0, find_pod=>1);
 $path = pod_path(module=>'Foo');

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 module_path(%args) -> array|str

Get path to locally installed Perl module.

Search C<@INC> (reference entries are skipped) and return path(s) to Perl module
files with the requested name.

This function is like the one from C<Module::Path>, except with a different
interface and more options (finding all matches instead of the first, the option
of not absolutizing paths, finding C<.pmc> & C<.pod> files, finding module
prefixes).

Arguments ('*' denotes required arguments):

=over 4

=item * B<abs> => I<bool> (default: 0)

Whether to return absolute paths.

=item * B<all> => I<bool> (default: 0)

Return all results instead of just the first.

=item * B<find_pm> => I<bool> (default: 1)

Whether to find .pm files.

=item * B<find_pmc> => I<bool> (default: 1)

Whether to find .pmc files.

=item * B<find_pod> => I<bool> (default: 0)

Whether to find .pod files.

=item * B<find_prefix> => I<bool> (default: 1)

Whether to find module prefixes.

=item * B<module>* => I<str>

Module name to search.

=back

Return value:


=head2 pod_path(%args) -> array|str

Shortcut for `module_path(..., find_pm=>0, find_pmc=>0, find_pod=>1, find_prefix=>1, )`.

Search C<@INC> (reference entries are skipped) and return path(s) to Perl module
files with the requested name.

This function is like the one from C<Module::Path>, except with a different
interface and more options (finding all matches instead of the first, the option
of not absolutizing paths, finding C<.pmc> & C<.pod> files, finding module
prefixes).

Arguments ('*' denotes required arguments):

=over 4

=item * B<abs> => I<bool> (default: 0)

Whether to return absolute paths.

=item * B<all> => I<bool> (default: 0)

Return all results instead of just the first.

=item * B<module>* => I<str>

Module name to search.

=back

Return value:

=head1 SEE ALSO

L<Module::Path>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SHARYANTO-Module-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Alt-Module-Path-SHARYANTO>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SHARYANTO-Module-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
