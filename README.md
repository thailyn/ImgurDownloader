ImgurDownloader
===============

This is a very simple script to download an album of images from imgur.com.  Pass the URL of an album as an argument to the script to use it.  The script downloads that page, parses out the names of and links to the images in that album, and then downloads those images.  They are saved to a subdirectory which is named after the title and author of the album.

The script right now is very narrow in scope.  I engineered it so it could download the most common type of albums I use, and, for example, at least does not work perfectly for other layouts.

The script also prints out a bunch of debugging information, which could be cleaned up.  Additionally, I would like to improve the UI, such as adding progress bars and collecting and displaying information about file sizes.

Requirements
============

This script requires Perl to run.  It also requires the following modules:
* WWW::Mechanize, to download web pages.
* Mojo::DOM, to parse HTML pages.
