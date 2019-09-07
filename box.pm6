use Terminal::Print;
use Terminal::Print::BoxDrawing;
use Terminal::Print::Animated;

use ui;

class Screen is Widget { };

class Inner is Widget
  does Terminal::Print::Animated {
  has @.lines;
  has Int $.first-visible = 0;

  method draw-frame {
    self.composite(:!print,:to($.grid));
  }
  multi method add-line($text where *.lines==0) {
    self.add-line(" ");
  }
  multi method add-line($text where *.lines==1) {
    @.lines.push: $text;
    $!first-visible++ if @.lines > $.h;
    self.render;
  }
  method up {
    $!first-visible-- if $!first-visible > 0;
    self.render;
  }
  method down {
    $!first-visible++ if $!first-visible < @.lines - $.h;
    self.render;
  }
  method render {
      for 0 ..^ $.h {
        my $i = $.first-visible + $_;
        my $row = @.lines[$i] // '';
        $.grid.set-span(1, $_, $row ~ ' ' x ($.w - 1 - $row.chars), 'white');
      }
      self.do-frame(Terminal::Print::FrameInfo.new);
  }
}

class Box is Widget does Terminal::Print::BoxDrawing
  does Terminal::Print::Animated {
  has $.inner;
  has $.style = 'double';
  method TWEAK {
    self.draw-box(0,0, $.w - 2, $.h - 2, style => $!style );
    self.composite(:to(self.parent.grid),:print);
    $!inner = Inner.new(
      :x($.x + 1), :y($.y + 1), :w($.w - 3), :h($.h - 3), :parent(self));
  }
  method at-bottom(Int :$h!, :$root!) {
    Box.new: :x(0), :y($root.grid.rows - $h), :w($root.grid.columns), :$h, :parent($root);
  }
  method at-right(Int :$w!, :$h, :$root!, :$style) {
    Box.new: :x($root.grid.columns - $w), :y(0), :$w, :$h, :$style, :parent($root);
  }
  method draw-frame {
    self.inner.composite(:to(self.parent.grid),:print);
  }
  method add-line($line) {
    $.inner.add-line($line);
    self.render;
  }
  method up {
    $.inner.up;
    self.render;
  }
  method down {
    $.inner.down;
    self.render;
  }
  method render {
    self.do-frame(Terminal::Print::FrameInfo.new);
  }
}
