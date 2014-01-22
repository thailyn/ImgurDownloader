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
my ($title, $author);

#my $title_element = $dom->at('title');
my $title_element = $dom->at('html head title');
if ($title_element) {
  $title = $title_element->all_text;
  print "Title: " . $title . "\n";
}
else {
  die "Failed to find title.\n";
}

my $author_element = $dom->at('html head meta[name="author"]');
if ($author_element) {
  $author = $author_element->attr('content');
  print "Author: " . $author . ".\n";
}
else {
  die "Failed to find author.\n";
}

my $num = 0;
my @image_links = $dom->find('div[id="content"] a[href] img')->each;
foreach my $img_element (@image_links) {
  $num = $num + 1;
  my $link = $img_element->attr('src');
  $link =~ s|//|/|g;
  print "$num: 'http:$link'\n";
}

print "Final count: $num\n";

print "Done.";
