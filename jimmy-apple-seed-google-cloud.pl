#!/usr/bin/perl -w

use strict;
use warnings;

use File::Path qw(make_path);

sub seed_cloud_with_images {
    my @images = @_;
    my $image;
    my $breadcrumb;

    foreach $image (@images) {
        $breadcrumb = create_breadcrumb_path($image);
        if (-e $breadcrumb) {
            printf "image %s already seeded, passing\n", $image;
        } else {
            execute_google_copy($image, create_google_path($image));
            touch_breadcrumb($breadcrumb);
        }
    }
}

sub create_breadcrumb_path {
    my $image = shift;
    (my $jim_path = $image) =~ s/.*(\/JIM\/)/$1/;
    return $main::breadcrumb_dir . $jim_path
}

sub create_google_path {
    my $image = shift;
    (my $jim_path = $image) =~ s/.*(\/JIM\/)/$1/;
    return $main::google_bucket . $jim_path
}

sub execute_google_copy {
    my ($image, $google_path) = @_;
    my $command = "gsutil";
    my @arguments = ("cp", $image, $google_path);

    printf "executing %s %s\n", $command, join(' ', @arguments);
    system($command, @arguments) == 0 or die "system $command @arguments failed: $?";
}

sub touch_breadcrumb {
    my $filename = shift;
    my $filepath = substr $filename, 0, rindex($filename, "/");
    make_path($filepath);
    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh "Written to Google!!\n";
    close $fh or die "Could not close file '$filename' $!";
}

# accepts one argument: full path to a directory
# returns: list of images that end in jpg (case
# insensitive) recursing all subdirectories
sub list_all_jpg_images {
    my $path = shift;

    opendir (DIR, $path)
        or die "Unable to open $path: $!";

    # append full path and ignore '.' and '..' directories!!
    my @images =
        map { $path . '/' . $_ }
        grep { !/^\.{1,2}$/ }
        readdir (DIR);

    # return a directly filtered list
    return
        grep { (/\.jpg$/i) &&
               (! -l $_) }
        map { -d $_ ? list_all_jpg_images ($_) : $_ }
        @images;
}

$main::google_bucket = "gs://jim-storage-cold-us-east1";
$main::breadcrumb_dir = "/Users/jcunning/Pictures/jim-to-google-breadcrumb";

print "Running it!!\n";
my $target_dir = $ARGV[0];
$target_dir =~ m/.*\/JIM\/.*/ or die "Must be a JIM directory!!";
seed_cloud_with_images(list_all_jpg_images($target_dir));
