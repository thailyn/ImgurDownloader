use strict;
use Mojo::DOM;

my $inputFile = shift;
die "Error: Must provide an input file name" unless $inputFile;
die "Error: Input file must exist" unless -e $inputFile;

open(my $fh, $inputFile) or die "Can not open file $inputFile: $!";
my $html = do { local $/; <$fh> } ;
close($fh);

print "All good.  File: $inputFile.\n";
#print "Contents:\n'$html'";

my $dom = Mojo::DOM->new($html);

#my $title_element = $dom->at('title');
my $title_element = $dom->at('html head title');
if ($title_element) {
  print "Title: $title_element->text\n";
}
else {
  print "Failed to find title.\n";
}

print "Done.";
