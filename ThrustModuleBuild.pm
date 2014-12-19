package ThrustModuleBuild;

use strict;

use parent 'Module::Build';


my $thrust_version = '0.7.6';
my $thrust_archive = 'thrust.zip';


sub ACTION_build {
  my $self = shift;

  $self->download_zip_file();

  $self->extract_zip_file();

  $self->SUPER::ACTION_build;
}



sub ACTION_install {
  my $self = shift;

  if ($^O =~ /darwin/i) {
    ## ExtUtils::Install appears to break ThrustShell.App - maybe doesn't copy some meta-data or something?

    $self->depends_on('build'); ## So that the parent class ACTION_install won't invoke it again

    print "WARNING: Due to Mac OS X lameness, we are removing the thrust shell binaries from the blib directory before install. You will have to to re-build if you want to use this local blib.\n";

    system("rm -rf blib/lib/auto/share/dist/Alien-Thrust/");

    $self->SUPER::ACTION_install;

    my $share_install_dir = $self->install_map->{'blib/lib'} . "/auto/share/dist/Alien-Thrust/";

    system('mkdir', '-p', $share_install_dir);
    system('unzip', '-uqq', $thrust_archive, '-d', $share_install_dir);
  } else {
    $self->SUPER::ACTION_install;
  }
}



sub download_zip_file {
  my $self = shift;

  my ($os, $arch);

  require LWP::UserAgent;

  if ($^O =~ /linux/i) {
    $os = 'linux';
    $arch = length(pack("P", 0)) == 8 ? 'x64' : 'ia32';
  } elsif ($^O =~ /darwin/i) {
    $os = 'darwin';
    $arch = 'x64';
  } elsif ($^O =~ /mswin/i) {
    $os = 'win32';
    $arch = 'ia32';
  } else {
    die "Your platform is currently not supported by Thrust";
  }

  my $thrust_zipfile_url = "https://github.com/breach/thrust/releases/download/v$thrust_version/thrust-v$thrust_version-$os-$arch.zip";

  if (-e $thrust_archive) {
    print "$thrust_archive already exists, skipping download\n";
  } else {
    unlink("$thrust_archive.partial");

    print "Downloading $thrust_zipfile_url (be patient)\n";

    my $ua = new LWP::UserAgent;
    my $res = $ua->get($thrust_zipfile_url, ':content_file' => "$thrust_archive.partial");

    if (!$res->is_success) {
      die "Failed to download $thrust_zipfile_url : " . $res->status_line;
    }

    rename("$thrust_archive.partial", $thrust_archive) || die "unable to rename $thrust_archive.partial to $thrust_archive ($!)";
  }
}



sub extract_zip_file {
  my $self = shift;

  system("mkdir -p blib/lib/auto/share/dist/Alien-Thrust/"); ## FIXME: portability

  if ($^O =~ /darwin/i) {
    ## Archive::Extract appears to break ThrustShell.App - maybe doesn't extract some meta-data or something?
    system("unzip -uqq $thrust_archive -d blib/lib/auto/share/dist/Alien-Thrust/");
  } else {
    require Archive::Extract;

    my $ae = Archive::Extract->new(archive => $thrust_archive);
    $ae->extract(to => 'blib/lib/auto/share/dist/Alien-Thrust/') || die "unable to extract archive: " . $ae->error;
  }
}


1;
