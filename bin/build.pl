use strict;
use warnings;
use Path::Tiny;

my $input_path = path (shift);
my $script = $input_path->slurp;

$script =~ s{use\s+([^\s;]+);\s*#!!EXPAND}{
  my $module = $1;
  eval qq{ use $module; 1 } or die $@;
  my $file = $module;
  $file =~ s{::}{/}g;
  $file .= ".pm";
  my $path = path ($INC{$file});
  my $pm = $path->slurp;
  $pm =~ s{\n__END__\r?\n.*}{}s;
  "\n\n{\n\n" . $pm . "\n\n}\n$module->import;\n\n";
}ge;

print $script;

## License: Public Domain.
