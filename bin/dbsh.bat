@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!perl
#line 15
use strict;
use warnings;
use DBSH;
my $application = DBSH->new();
$application->run();

=head1 SEE ALSO

L<CPANPLUS::Dist>, L<CPANPLUS::Module>, L<CPANPLUS::Shell::Default>,
C<cpanp>

=head1 BUG REPORTS

Please report bugs or other issues to E<lt>bug-cpanplus@rt.cpan.org<gt>.

=head1 AUTHOR

This module by Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

The CPAN++ interface (of which this module is a part of) is copyright (c)
2001 - 2007, Jos Boumans E<lt>kane@cpan.orgE<gt>. All rights reserved.

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=cut


__END__
:endofperl
