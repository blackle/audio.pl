use POSIX;
$tau = 2 * 3.1415;
sub fmmod {
  my ($t, $fm, $fc, $fd) = @_;
  return sin($tau * $fc * $t + $fd * cos($t * $tau * $fm)/$fm);
}
sub p1 {
  my ($t) = @_;
  return (1 - $t)**2;
}
sub p2 {
  my ($t) = @_;
  return (2 - 2**$t);
}
my @c = ();
srand(666);
for(my $i = 0; $i < 16; $i++){
  push @c, (261, 293, 329, 349, 392, 440, 493)[int(rand(7))];
}
my $r = 0;
sub dsp {
  my $t = 2*(pop)/22050.0;
    my $blen = 3;
  my $prog = fmod($t * $blen, 1);
  my $bar = int($t * $blen);
  my $decay = (1-(1-$prog)**16) * p1($prog);
  my $decay2 = (1-(1-$prog)**16) * p2($prog);
    my $codes = $c[$bar % 16]*2;
    my $kick = 0;
  my $melody = 0;
    if($bar < 80) {
    $melody += fmmod($t, 5, $codes, $bar*4);
  }
    if($bar == 81) {
    return chr 4;
  }
  if($bar < 64) {
    if($bar % 4 == 0 && $bar >= 16){
      $kick += fmmod($t, 50, 60, 10);
      if(rand() < 0.05 ) {
        $r = rand()-0.5;
      }
      $kick += $r/2;
    }
    if($bar % 4 == 2 && $bar >= 32){
      if(rand() < (0.2 + ($bar % 8 == 0)/3 ) ) {
        $r = rand()-0.5;
      }
      $kick += $r/2;
    }
    if($bar % 2 == 1 && $bar >= 48){
      if(rand() < (0.8 + ($bar % 8 == 0) ) ) {
        $r = rand()-0.5;
      }
      $kick += $r/3;
    }
  }
  return $melody/4*$decay + $kick/2*$decay2;
}

print "Now Playing: Crashing Ducks\n";

my ($read, $write) = POSIX::pipe();
my $pid=fork();
if($pid != 0){
  POSIX::close( $write );
  dup2($read, STDIN);
  exec("/usr/bin/aplay -q -c 1 -r 22050 -f S16_LE");
} else {
  POSIX::close($read);

  my @buf = map{0}(1..1024);
  for(my$t=0;;$t++){
    $g = $t % 1024;
    if($t % 1024 == 0){
      my $r = pack 's<[1024]', @buf;
      POSIX::write($write, $r, 1024*2);
    }
    $dsp_g = dsp($t);
    if($dsp_g eq chr 4){
      exit 0;
    }
    $buf[$g] = $dsp_g * 32768;
  }
}
