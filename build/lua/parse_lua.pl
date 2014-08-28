#!/usr/bin/perl -w


use strict;
use Getopt::Long;
use File::Basename;
use FileHandle;
use File::Compare;
use File::Copy;

$!=1;

my $program = basename($0);
my $prefix = undef;
my $infile = undef;

sub Error($) {
        my $error = shift;
        print "ERROR: $error\n";
}


sub Usage()
{
        print "\nUsage:\n";
        print "\t$program\n";
        print "\t\t--prefix='ITAXI_'\n";
        print "\t\t--infile='ITAXI.LUA'\n";
		print "\teg. perl $program --prefix=ITAXI_ --infile=ITAXI.LUA\n";
        print "\n";
}

sub ParseCommandLine()
{
        my $ok=1;
        my $result = GetOptions(
                "prefix=s"     => \$prefix,
                "infile=s"    => \$infile,
                );

        if (!$result|| !defined $prefix || !defined $infile )
        {
                Error( "Invalid command line parameters" );
				Usage();
                $ok=0;
        }

		if(!$ok) {
			exit(1);
		}

}

sub ParseFile($)
{
	my $luadir = "./lua";
	my ($filename) =  @_;
    my $fh = undef;
    my $fw = undef;
    my $fmain = undef;
	my $begin = 1;
	my $start = 0;
	my $end = 0;
	my $oldfile=undef;
	my $wfile = "$luadir/luatmp";
	my $main_tmp = "$luadir/LUA_MAIN_$infile.tmp";
	my $wfile_end = "$luadir/luatmp_end";


    open $fh, "< $filename";
	if(!$fh) {
        Error( "Invalid file " );
		exit(1);
	}
	#open $fmain, "> $luadir/LUA_MAIN_$infile";
    open $fmain, "> $main_tmp";

    while (<$fh>) { 
		my ($line) = $_;

		if ($line =~ /^function\s*(\S*)\s*\(/) {
			$start = 1;
			$begin=0;
			my $funcname = uc($1);
			$oldfile = "$luadir/$prefix$funcname.lua";
    		open $fw, "> $wfile";
			if(!$fw) {
				Error( "open file failed " );
				exit(1);
			}
			print $fmain "require(\"$prefix$funcname\"\)\n";
		}

		if ($start == 1 ) {
				print $fw $line;
				if( $line =~ /^end/) {
					$start = 0;
					close $fw;
					if(compare($oldfile,$wfile)==0) {
					} else {
							copy( $wfile,$oldfile);
					}
				}
		} else {
				if( $line =~ /^\s*$/) {
						$begin=1;
				}
		}

		if($begin) {
			if(0 and $line =~ /^--/) { #disabled
			}elsif($line =~ /^\s*$/) {
			}else {
				print $fmain $line;
			}	
		}
	}
	if($start==1) {
        Error( "Invalid file format ...END not found" );
		if($fw) {close $fw;}
	}
    close $fh;
    close $fmain;
	if(compare("$luadir/LUA_MAIN_$infile",$main_tmp)==0) {
	}else{
		copy( $main_tmp,"$luadir/LUA_MAIN_$infile");
	}
	unlink($wfile);
	unlink($main_tmp);

}

ParseCommandLine();
ParseFile($infile);
exit(0);
