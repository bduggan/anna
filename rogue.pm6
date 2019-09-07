unit class rogue;

use Terminal::Print;
use Terminal::Print::DecodedInput;

use box;
use character;

my $DEBUG = 0;

has $.t;
has $.root;
has $.in = decoded-input-supply;
has $.book;
has $.people-list;
has character $.player;
has %.people;
has $.w;
has $.h;

method TWEAK {
 $!t = Terminal::Print.new;
 $!t.initialize-screen;
 $!root = Screen.new-from-grid($!t.current-grid);
 $!player = character.somewhere(:$!root,:color<cyan>);
 $!w = $!root.grid.columns;
 $!h = $!root.grid.rows;
}

method start-input {
  start react whenever $.in {
    given $_ {
      when 'e' { $!book.up; }
      when 'd' { $!book.down; }
      when 'q' {
        $!t.shutdown-screen;
        shell 'stty sane';
        exit;
      }
      when 'h' | CursorLeft  { $!player.moves.send: 'left'; }
      when 'j' | CursorDown  { $!player.moves.send: 'down'; }
      when 'k' | CursorUp    { $!player.moves.send: 'up'; }
      when 'l' | CursorRight { $!player.moves.send: 'right'; }
      default {
        self.debug("[$_]");
      }
    }
    self.prune-people;
  }
}

method debug($str) {
  return unless $DEBUG;
  $.root.grid.print-string(0,0,"[$str]" ~ " " x 20);
}

method prune-people {
  return unless $!people-list;
  for %!people -> (:key($k), :value($p)) {
    next unless $p.x==$!player.x && $p.y==$!player.y;
    next unless $p;
    $!people-list.add-line("removing " ~ $p.icon);
    %!people{$k}.send: 'bye';
    %!people{$k}:delete;
  }
}

method start-player {
  $!player.play;
}

my regex person {
  | Oblonsky
  | Stepan
  | Alabin
  | Grisha
  | Tanya
  | 'Darya Alexandrovna'
  | Matvey
  | Philimonovna
  | Levin
  | Vronsky
  | Sergey
  | Dolly
  | Rolland
}

method find-people($line) {
  $line.comb(/ <person> /).unique
}

method add-person($p) {
  $!people-list //= Box.at-right(:30w, :15h, :$.root, :style<light1>);
  $!people-list.add-line($p);
  my $new = character.somewhere(:$!root, icon => "$p", :color<yellow> );
  %!people{ $new.WHICH } = $new;
  $new.play;
  $new.move-around;
}

method run(Bool :$fast) {
 self.debug: $.w ~ ' x ' ~ $.h;
 $!book = Box.at-bottom(:15h, :$.root);
 self.start-input;
 self.start-player;
 my $started;
 for '1399-0.txt'.IO.lines {
   $started //= ($_ ~~ / 'Chapter 1' /);
   next unless $started;
   $!book.add-line($_);
   for self.find-people($_) {
     self.add-person($_) 
   }
   sleep $fast ?? 0.08 !! 1.5;
 }
}

method quit {
 sleep 2;
 $!t.shutdown-screen;
 shell "stty sane";
 exit;
}
