sub EXPORT(|) {
    my role BetterWorld {
        method do_pragma_or_load_module(Mu $/ is raw, $use, $thisname?) {
            my $name;
            my %cp;
            my $arglist;

            my $RMD := self.RAKUDO_MODULE_DEBUG;

            if $thisname {
                $name := $thisname;
            }
            else {
                my $lnd  := self.dissect_longname($/.hash<module_name>.hash<longname>);
                $name    := $lnd.name;
                %cp      := $lnd.colonpairs_hash($use ?? 'use' !! 'no');

                # That's why we do all that:
                return if %cp<if>:exists && %cp<if> == False;

                $arglist := self.arglist($/);
            }

            unless %cp {
                if self.do_pragma($/,$name,$use,$arglist) { return }
            }

            if $use {
                $RMD("Attempting to load '$name'") if $RMD;

                # old way:
                my $comp_unit := try self.load_module($/, $name, %cp, $*GLOBALish);
                # new way:
                $! and $comp_unit := self.load_module($/, $name, %cp, self.cur_lexpad);

                $RMD("Performing imports for '$name'") if $RMD;
                self.do_import($/, $comp_unit.handle, $name, $arglist);
                self.import_EXPORTHOW($/, $comp_unit.handle);
                $RMD("Imports for '$name' done") if $RMD;
            }
            else {
                die "Don't know how to 'no $name' just yet";
            }
        }
    }

    $*W.HOW.mixin($*W, BetterWorld);

    BEGIN Map.new
}

=begin pod

=head1 NAME

if - Conditionally load a distribution

=head1 SYNOPSIS

=begin code :lang<raku>

use if; # activate the :if adverb on use statements

use My::Linux::Backend:if($*KERNEL.name eq 'linux');
use My::Fallback::Backend:if($*KERNEL.name ne 'linux');

# ... do something with the backend you got

=end code

=head1 DESCRIPTION

The C<if> distribution will let you conditionally load a distribution.
Use cases (no pun intended) are about loading different implementations
of a functionality for different operating systems, compiler backends,
or compiler versions.

This means that these switches for different implementations do not
happen at runtime, but cheaply at compile time. This also means that
a custom build and install hook is not needed because all
implementations are installed. Then depending on the conditions only
the desired implementation will be used.

Even if the switch is by backends you can share one installation by
several backends using this technique.

=head1 AUTHOR

Tobias Leich

=head1 COPYRIGHT AND LICENSE

Copyright 2016-2020 Tobias Leich
Copyright 2023, 2024 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
