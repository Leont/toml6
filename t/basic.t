use Test;

use TOML;

my $grammar = TOML::Grammar.new;
my $actions = TOML::Actions.new;
my $toml = q:heredoc/END/;
foo = [ 1, 2, 3 ]
f = 1
fail = 'Who?\'
other = '''What'?'''
date = 1979-05-27T07:32:00Z
[bar]
buz = 1
[fizz.buzz]
baz = 42
[fizz.bizz]
noz = 24
nok = "Hey"
ok = """
Hello\t
World"""
END

my $foo = $grammar.parse($toml, :$actions);
ok($foo, 'First parse was successful');
diag($foo.ast.perl) if $foo;
