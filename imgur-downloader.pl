use strict;
use LWP::Simple;
use Mojo::DOM;

my $temp_html_file = "temp.html";

# 'http://imgur.com/a/3mGHa/noscript'
my $url = shift;
die "$0: Must provide an input url" unless $url;
print "URL: $url\n";

my $return_code = getstore($url, $temp_html_file);
die "$0: Failed to get page: $return_code" unless defined is_success($return_code);
print "Return code: $return_code\n";

my $inputFile = $temp_html_file;
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

my $directory_name = "$title - $author";
if (-d $directory_name) {
  print "Directory '$directory_name' already exists; skipping step.\n";
}
elsif (-e $directory_name) {
  die "$0: File with name '$directory_name' exists and is not a directory.\n";
}
else {
  mkdir $directory_name or die "Failed to create directory '$directory_name': $!";
  print "Created directory '$directory_name'.\n";
}

print "Final count: $num\n";

print "Done.";
