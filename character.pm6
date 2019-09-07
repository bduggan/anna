use Terminal::Print;
use Terminal::Print::Animated;
use ui;

unit class character is Widget does Terminal::Print::Animated;

has Channel $.moves handles <send>;
has $.root;
has $.icon;
has $!done;
has $.color = 'white';
has $!new-x;
has $!new-y;

method TWEAK {
  $!moves = Channel.new;
}

method max-x { $.root.grid.columns - $.w - 1 }
method max-y { $.root.grid.rows - 1 }

method somewhere(:$root,:$color,:$icon = 'анна') {
  my $w = $icon.chars;
  my $h = 1;
  my $x = (0..^($root.grid.columns)).pick;
  my $y = (0..^($root.grid.rows)).pick;
  character.new(:$root,:$color,:$x,:$y,:$w,:$h,:$icon);
}

method draw-frame {
  $.grid.set-span(0,0,' ' x $.w,'black');
  self.composite(:print,:to($.root.grid));
  self.move-to($!new-x // $.x,$!new-y // $.y);
  $.grid.set-span(0,0,$.icon,$.color);
  self.composite(:print,:to($.root.grid));
}

method play {
  self.do-frame(Terminal::Print::FrameInfo.new);
  start loop {
    my $move = $.moves.receive;
    $!new-x = $.x;
    $!new-y = $.y;
    given $move {
      when 'left'  { $!new-x = $.x - 1 if $.x > 0       }
      when 'right' { $!new-x = $.x + 1 if $.x < $.max-x }
      when 'up'    { $!new-y = $.y - 1 if $.y > 0       }
      when 'down'  { $!new-y = $.y + 1 if $.y < $.max-y }
      when 'bye'   { $!done = 1; last       }
      default {
        die "unknown message $move";
      }
    }
    self.do-frame(Terminal::Print::FrameInfo.new);
  }
}

method move-around {
  start loop {
    sleep 1.rand;
    last if $!done;
    self.send: <up down left right>.pick;
  }
}

