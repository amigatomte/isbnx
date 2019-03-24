#! /usr/bin/perl
#
# isbnx.pl <filename> [filename2 [...]] 
# This program tries to extract a ISBN number from each PDF file. Then it downloads metadata 
# associated with the ISBN number and tags the pdf file with it. 
#
# Needs to be in path: 
#                      pdftotext (Xpdf command line tools, https://www.xpdfreader.com/download.html)
#                      pdfinfo, fetch-ebook-metadata, ebook-meta (Included with Calibre, https://calibre-ebook.com/download)
#
# Tested with:  ActivePerl v5.26.3 on MS Windows 8.1.
#


use warnings;
use strict;
use v5.10;
use File::Glob ':glob';
use Business::ISBN;
use File::Copy;
	
die "Filenames cannot contain any of the following characters: \\ \/ \: \< \> \| \"\nThe input filenames must reside in the current directory.\n" if ("@ARGV"=~/\\|\/|\:|\<|\>|\||\"/);


foreach my $arg(@ARGV)
{ 
	if ($arg=~/\*|\?/)
	{	#If the shell didn't take care of the globbing, we'll have to do it manually.
		my @star_files= bsd_glob("$arg");
		foreach my $list(@star_files)
		{	# Push each matching file back in the argument list.
			push @ARGV, $list;
		}
	} else
	{
		my $dir="_ISBNX_complete";
		mkdir $dir;
		my $file=$arg;
		my $isbn;
#			say "\$isbn=extractisbn($file)";
		$isbn=extractisbn($file);
		say "\$isbn = $isbn";
		if ($isbn ne "0") 
		{
			# $isbn=verifyisbn($isbn);
			say "\$isbn = $isbn";
			if ($isbn ne "0")
			{
				say "$file har ISBN: $isbn\n";
				lookupandmark($file, $isbn);
				move($file,$dir);
			}
			else
			{
				say "$file har ingen ISBN!\n";
			}
		}
		else
		{
			say "$file har ingen ISBN!\n";
		}
		
	}
}
sub extractisbn
{
	my ($f) = @_;
	my $regex1=qr/(?:ISBN|isbn).*?\n*?.*?(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/;
	my $regex2=qr/(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/;
	my $ex_isbn;
#	say "\$f= $f";

#	say "$f har $pages sidor";
	say "pdftotext -f 1 -l 30 \"$f\" -";
	my $filedump=`pdftotext -f 1 -l 30 "$f" -`;
	while ($filedump=~ m/$regex1/g)
	{	
		#say "\$+{isbn} = $+{isbn}";
		$ex_isbn = verifyisbn($+{isbn});
		if ($ex_isbn) { return $ex_isbn; }
	}
#	while ($filedump=~ m/(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/g)
	while ($filedump =~ m/$regex2/g)
	{
		#say "\$+{isbn} = $+{isbn}";
		$ex_isbn = verifyisbn($+{isbn});
		if ($ex_isbn) { return $ex_isbn; }
	}

	my $pages=`pdfinfo "$f"`;
	$pages=~ m/Pages:\s*([0-9]+)/;
	$pages=$1;
	my $first=$pages-30;
	say "pdftotext -f $first -l $pages \"$f\" -";
	$filedump=`pdftotext -f $first -l $pages "$f" -`;
	while ($filedump=~ m/$regex1/g)
	{
		$ex_isbn = verifyisbn($+{isbn});
		if ($ex_isbn) { return $ex_isbn; }
	}
	while ($filedump=~ m/$regex2/g)
	{
		$ex_isbn = verifyisbn($+{isbn});
		if ($ex_isbn) { return $ex_isbn; }
	}
	return 0;
}

	
#	say $+{isbn};
	# my $ex_isbn = $+{isbn};
	# unless ($ex_isbn)
	# {
		# $filedump=~ m/(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/g;
		# $ex_isbn = $+{isbn};
	# }
	# unless ($ex_isbn)
	# {
		# my $pages=`pdfinfo "$f"`;
		# $pages=~ m/Pages:\s*([0-9]+)/;
		# $pages=$1;
		# my $first=$pages-30;
		# say "pdftotext -f $first -l $pages \"$f\" -";
		# $filedump=`pdftotext -f $first -l $pages "$f" -`;
		# $filedump=~ m/(?:ISBN|isbn).*?\n*?.*?(?<isbn>[0-9\-\.–­―—\^ ]{9,28}[0-9xX])/g;
		# $ex_isbn = $+{isbn};
		# unless ($ex_isbn)
		# {
			# $filedump=~ m/(?<isbn>[0-9\-\.–­―—\^]{9,28}[0-9xX])/g;
			# $ex_isbn = $+{isbn};
		# }
		# unless ($ex_isbn) { return 0 };
	# }
	# $ex_isbn =~ s/[^0-9xX]//g;
	# return $ex_isbn;
# }

sub verifyisbn
{
	my ($i) = @_;
	$i =~ s/[^0-9xX]//g;
	if (length($i) < 10) 
	{ 
		return 0;
	}
	if (length($i) > 10 && length($i) < 13)
	{
		$i = substr($i, 0, 10);
	}
	elsif (length($i) > 13)
	{
		$i = substr($i, 0, 13);
	}
#	say "\$i = $i";
	my $icheck = Business::ISBN->new($i);
	unless ($icheck->is_valid) { return 0 };
 #   say "\$i is valid!";
	return $i 
}
sub lookupandmark
{
	my($f, $i) = @_;
#	say "fetch-ebook-metadata -i $i";
	if ( system("fetch-ebook-metadata -i $i -o >temp.txt") == 0 )
	{
		system("ebook-meta \"$f\" --isbn $i --from-opf temp.txt");
		unlink "temp.txt" or warn "Could not unlink temp.txt: $!";
		return 1;
	}
	else
	{
		return 0;
#		say "ingen opf";
#		system("ebook-meta \"$f\" --isbn $i");
	}
	
	
}