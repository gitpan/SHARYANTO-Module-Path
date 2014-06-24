#!perl

use 5.010001;
use strict;
use warnings;

use SHARYANTO::Module::Path qw(module_path pod_path);
use Test::More 0.98;

subtest module_path => sub {
    ok(module_path(module=>'strict'));
    ok(module_path(module=>'strict.pm'));
    ok(module_path(module=>'SHARYANTO::Module::Path'));
    ok(module_path(module=>'SHARYANTO/Module/Path.pm'));

    # XXX opt: all
    # XXX opt: abs
    # XXX opt: find_pm
    # XXX opt: find_pmc
    # XXX opt: find_pod

    subtest "opt: find_prefix" => sub {
        ok(!module_path(module=>'Module'));
        ok(module_path(module=>'Module', find_prefix=>1));
    };
};

#subtest pod_path => sub {
#};

DONE_TESTING:
done_testing;
