module TOML {
	grammar Grammar {
		token TOP {
			\s*
			<entries>
			\s*
			<sub-entries>
			\s*
		}
		token sp {
			' ' | "\t"
		}
		token ws {
			<!ww> <.sp>* | '#' \N* \n
		}

		token key {
			<.alnum>+
		}
		token entry {
			<.ws> <key> <.ws> '=' <.ws> <value>
		}
		token entries {
			<entry>* % \n+
		}
		token sub-entries {
			[ <table> | <array-of-tables> ]+ % \n+
		}
		token table {
			<sp>* '[' <key>+ % '.' ']' \n+
			<entries>
		}
		token array-of-tables {
			<!>
		}

		token array {
			'[' <.ws> <arraylist> <.ws> ']' 
		}
		rule arraylist {
			<value> * %% [ \, ]
		}

		proto regex value {*};
		token value:sym<number> {
			'-'?
			[ 0 | <[1..9]> <[0..9]>* ]
			[ \. <[0..9]>+ ]?
			[ <[eE]> [\+|\-]? <[0..9]>+ ]?
			<!before '-'>
		}
		token value:sym<true> {<sym> }
		token value:sym<false> { <sym> }
		token value:sym<null> { <sym> }
		token value:sym<array> { <array> }
		token value:sym<string> { <string> }
		token value:sym<datetime> { <datetime> }

		token string {
			<basic-string> | <multi-string> | <literal-string> | <multi-literal-string>
		}
		token basic-string {
			\" <!before '""'> [ <str> | \\ <str=.str-escape> ]* \"
		}
		token str {
			<-["\\\t\n]>+
		}
		token str-escape {
			<["\\/bfnrt]> | u <xdigit>**4 | U <xdigit>**8
		}

		token multi-string {
			'"""' [ \n | <.multi-escaped> ]? <multi-line>* % <.multi-escaped> '"""'
		}
		token multi-line {
			[ <element=multi-element> | \\ <element=str-escape> ]+
		}
		token multi-element {
			<-["\\\n]>+ | <!after '\\'> \n | '"' <!before '""'>
		}
		token multi-escaped {
			"\\\n" <:Space>*
		}

		token literal-string {
			"'" <!before "''"> $<content>=<-[']>* "'"
		}

		token multi-literal-string {
			"'''" \n? $<content>=[ [ <-[']>+ | "'" <!before "''"> ]+ ] "'''"
		}

		token num {
			<[0..9]>
		}
		token datetime {
			<num> ** 4 '-' <num>**2 '-' <num>**2 'T' <num>**2 ':' <num>**2 ':' <num>**2 'Z'
		}
	}

	class Actions {
		sub merge-entries(@entries) {
			my %ret;
			for @entries -> $entry {
				my @key = $entry.key.list;
				my $value = $entry.value;
				my $last = @key.pop;
				my $current = %ret;
				for @key -> $keypart {
					$current := $current{$keypart};
				}
				$current{$last} = $value;
			}
			return %ret;
		}
		method TOP($/) {
			my %entries = $<entries>.ast;
			my %sub-entries = $<sub-entries>.ast;
			make (%entries, %sub-entries).hash;
		}
		method entry($/) {
			make ~$<key> => $<value>.ast;
		}
		method entries($/) {
			make @<entry>».ast.hash;
		}
		method sub-entries($/) {
			make merge-entries($/.values[0]».ast);
		}
		method table($/) {
			make [~«@<key>] => $<entries>.ast;
		}
		method array($/) {
			make $<arraylist>.ast.item;
		}
		method arraylist($/) {
			make [ $<value>».ast ];
		}
		method string($/) {
			make $/.values[0].ast;
		}
		method basic-string($/) {
			make +@$<str> == 1 ?? $<str>[0].ast !! $<str>>>.ast.join;
		}
		method multi-string($/) {
			make @<multi-line>».ast.join('');
		}
		method multi-line($/) {
			make @<element>».ast.join('');
		}
		method multi-element($/) {
			make ~$/;
		}
		method literal-string($/) {
			make ~$<content>;
		}
		method multi-literal-string($/) {
			make ~$<content>;
		}
		method value:sym<number>($/) { make +$/.Str }
		method value:sym<string>($/) { make $<string>.ast }
		method value:sym<true>($/) { make Bool::True }
		method value:sym<false>($/) { make Bool::False }
		method value:sym<null>($/) { make Any }
		method value:sym<array>($/) { make $<array>.ast }
		method value:sym<datetime>($/) { make $<datetime>.ast }

		method str($/) {
			make ~$/
		}

		my %h = '\\' => "\\",
		'/' => "/",
		'b' => "\b",
		'n' => "\n",
		't' => "\t",
		'f' => "\f",
		'r' => "\r",
		'"' => "\"";
		method str-escape($/) {
			if $<xdigit> {
				make chr(:16($<xdigit>.join));
			} else {
				make %h{~$/};
			}
		}

		method datetime($/) {
			make DateTime.new(~$/);
		}
	}
}
