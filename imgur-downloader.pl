use strict;
use WWW::Mechanize;
use Mojo::DOM;
use Term::ProgressBar 2.00;

my $temp_html_file = "temp.html";

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

# Add the callbacks after the initial page request.
$mech->add_handler( response_header => \&header_callback, m_code => 2 );  #m_domain => "imgur.com"
$mech->add_handler( response_data => \&data_callback, m_code => 2 );
$mech->add_handler( response_done => \&done_callback, m_code => 2 );

my $dom = Mojo::DOM->new($html);
my ($title, $author);

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

my $num_pictures = $num;
my $next_progress_update = 0;

$num = 0;
my $progress;
my $file_num_width = length($num_pictures);
my $file_size = 0;
my $file_name;
my $downloaded_size = 0;
my $total_file_size = 0;
my $total_downloaded_size = 0;
for my $link (@image_links) {
  $num = $num + 1;

  $progress = undef;
  $file_size = 0;
  $downloaded_size = 0;
  $next_progress_update = 0;

  my $image_url = $link->attr('src');
  $file_name = $image_url;

  # regex would not handle files without extensions
  if ($file_name =~ m|i\.imgur\.com\/(.*\.[a-zA-Z0-9]+)|) {
    $file_name = $1;
  }
    
  my $file_path = $directory_name . "/" . sprintf("%03d", $num) . "-" . $file_name;
  #print sprintf("%03d", $num) . ": $link -> $file_path...";
  #$progress->message(sprintf("%03d", $num) . ": $link -> $file_path...");

  #$progress = Term::ProgressBar->new({ name => "($num/$num_pictures): $file_name - ???? B",
  #                                     count => 100,
  #                                     remove => 1});
  #$progress->minor(0);

  $response = $mech->get($image_url,
                        ':content_file' => $file_path);
  die "$0: Request failed" unless $response->is_success;

  unless ($progress) {
    initialize_progress_bar($progress, $response) unless $progress;
    $progress->message("Initialized progress bar in main loop.");
  }

  unless ($file_size) {
    #$progress->message("Setting file size info after downloading.");
    $file_size = $downloaded_size;
    $total_file_size = $total_file_size + $file_size;
  }

  $progress->message(sprintf("Completed (%${file_num_width}s/%s): %s (%s B) (%s)",
                             $num, $num_pictures, $file_name, $file_size, $response->code));

  #print " done.\n";
}

print "Done.  Total size downloaded: $total_downloaded_size B";

sub initialize_progress_bar {
  my ($progress, $response) = @_;

  $file_size = $response->header('content_length');

  $total_file_size = $total_file_size + $file_size if $file_size;

  $progress = Term::ProgressBar->new({ name => "($num/$num_pictures): $file_name - $file_size B",
                                       count => ($file_size or 100),
                                       remove => 1});
  $progress->minor(0);
  #$progress->message("No content length!") unless $file_size;

  return $progress;
}

sub header_callback {
  my ($response, $ua, $h) = @_;
  #print "Header callback. h = $h\n";
  #print "Response code: " . $response->code . "\n";
  #print "Content type: " . $response->header('content_type') . "\n";
  #print "Content length: " . $response->header('content_length') . "\n";

  $progress = initialize_progress_bar($progress, $response);

  #$progress->name("($num/$num_pictures): $file_name - $file_size B");
  #$progress->target($file_size);
  #$progress->minor(0);
}

sub data_callback {
  my ($response, $ua, $h, $data) = @_;

  #print ".";
  #print "Length: " . length($data) . "\n";

  unless ($progress) {
    initialize_progress_bar($progress, $response) unless $progress;
    $progress = $progress->message("Initialized progress bar in data callback.");
  }

  $downloaded_size = $downloaded_size + length($data);
  $total_downloaded_size = $total_downloaded_size + length($data);
  #$progress->name("($num/$num_pictures): $file_name - $downloaded_size / $file_size B");
  $next_progress_update = $progress->update($downloaded_size)
    if $downloaded_size >= $next_progress_update and $file_size;

  return 1;
}

sub done_callback {
  my ($response, $ua, $h) = @_;

  #print "!";

  unless ($progress) {
    $progress = initialize_progress_bar($progress, $response);
    $progress->message("Initialized progress bar in done callback.");
  }

  $progress->update($file_size or 100)
    if $downloaded_size >= $next_progress_update;
}
