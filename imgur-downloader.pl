use strict;
use WWW::Mechanize;
use Mojo::DOM;

my $temp_html_file = "temp.html";

# 'http://imgur.com/a/3mGHa/noscript'
my $url = shift;
die "$0: Must provide an input url" unless $url;
print "URL: $url\n";

my $mech = WWW::Mechanize->new( stack_depth => 0 );
my $response = $mech->get($url);  # , ":content_file" => "temp.html"
die "$0: Request failed" unless $response->is_success;
open(my $fout, ">", $temp_html_file) or die "Can not open file '$temp_html_file': $!";
print $fout $response->decoded_content;
close($fout);

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
#my @image_links = $dom->find('div[id="content"] a[href] img')->each;  # Using the a[href] element here only finds images that can be zoomed in.
my @image_links = $dom->find('div[id="content"] div[class="image"] div[class="wrapper"] img')->each;
foreach my $img_element (@image_links) {
  $num = $num + 1;
  my $link = $img_element->attr('src');
  $link =~ s|//|/|g;
  #print "$num: 'http:$link'\n";
}
print "Parsed album page.  Album images: $num\n";

my $directory_name = "$title - $author";
$directory_name =~ s/[\:\\\/\*\?\"<>\|]/_/g;
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

$num = 0;
for my $link (@image_links) {
  $num = $num + 1;

  my $image_url = $link->attr('src');
  my $file_name = $image_url;

  # regex would not handle files without extensions
  if ($file_name =~ m|i\.imgur\.com\/(.*\.[a-zA-Z0-9]+)|) {
    $file_name = $1;
  }
    
  my $file_path = $directory_name . "/" . sprintf("%03d", $num) . "-" . $file_name;
  print sprintf("%03d", $num) . ": $link -> $file_path...";
  $response = $mech->get($image_url,
                        ':content_file' => $file_path);
  die "$0: Request failed" unless $response->is_success;
  print " done.\n";
}

print "Done.";
