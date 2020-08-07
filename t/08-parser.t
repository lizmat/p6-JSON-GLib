use v6.c;

use Test;

#use NativeCall;

use JSON::GLib::Raw::Types;

use JSON::GLib::Node;
use JSON::GLib::Object;
use JSON::GLib::Parser;

my $empty-string = '';
my $empty-array  = '[ ]';
my $empty-object = '{ }';

my @base-values = (
  { val => 'null', type => JSON_NODE_NULL, gtype => G_TYPE_INVALID },
  do {
    my %h = ( val => 42, type => JSON_NODE_VALUE, gtype => G_TYPE_INT64 );
    %h<verify> = -> $n { $n.get-int == %h<val> };
    %h
  },
  do {
    my %h = ( val => True, type => JSON_NODE_VALUE, gtype => G_TYPE_BOOLEAN );
    %h<verify> = -> $n { $n.get-bool == %h<val> };
    %h
  },
  do {
    my %h = ( val => '"string"', type => JSON_NODE_VALUE, gtype => G_TYPE_STRING );
    %h<verify> = -> $n { $n.get-string eq %h<val>.substr(1, %h<val>.chars - 2) };
    %h
  },
  do {
    my %h = ( val => 10.2e3, type => JSON_NODE_VALUE, gtype => G_TYPE_DOUBLE );
    %h<verify> = -> $n { $n.get-double =~= %h<val> };
    %h
  },
  do {
    my %h = ( val => -1, type => JSON_NODE_VALUE, gtype => G_TYPE_INT64 );
    %h<verify> = -> $n { $n.get-int == %h<val> };
    %h
  },
  do {
    my %h = ( val => -3.14, type => JSON_NODE_VALUE, gtype => G_TYPE_DOUBLE );
    %h<verify> = -> $n { $n.get-double =~= %h<val> };
    %h
  }
);

my @simple-arrays = (
  { str => '[ true ]',               len => 1, element => 0, type => JSON_NODE_VALUE, gtype => G_TYPE_BOOLEAN.Int },
  { str => '[ true, false, null ]',  len => 3, element => 2, type => JSON_NODE_NULL,  gtype => G_TYPE_INVALID.Int },
  { str => '[ 1, 2, 3.14, "test" ]', len => 4, element => 3, type => JSON_NODE_VALUE, gtype =>  G_TYPE_STRING.Int }
);

my @nested-arrays = «
  '[ 42, [ ], null ]'
  '[ [ ], [ true, [ true ] ] ]'
  '[ [ false, true, 42 ], [ true, false, 3.14 ], "test" ]'
  '[ true, { } ]'
  '[ false, { "test" : 42 } ]'
  '[ { "test" : 42 }, null ]'
  '[ true, { "test" : 42 }, null ]'
  '[ { "channel" : "/meta/connect" } ]'
»;

my @simple-objects = (
  { str => '{ "test" : 42 }',                 size => 1, member => 'test',    type => JSON_NODE_VALUE, gtype =>  G_TYPE_INT64.Int },
  { str => '{ "foo" : "bar", "baz" : null }', size => 2, member => 'baz',     type => JSON_NODE_NULL,  gtype =>  G_TYPE_INVALID.Int },
  { str => '{ "name" : "", "state" : 1 }',    size => 2, member => 'name',    type => JSON_NODE_VALUE, gtype =>  G_TYPE_STRING.Int },
  { str => '{ "channel" : "/meta/connect" }', size => 1, member => 'channel', type => JSON_NODE_VALUE, gtype =>  G_TYPE_STRING.Int },
  { str => '{ "halign":0.5, "valign":0.5 }',  size => 2, member => 'valign',  type => JSON_NODE_VALUE, gtype =>  G_TYPE_DOUBLE.Int },
  { str => '{ "" : "emptiness" }',            size => 1, member => '',        type => JSON_NODE_VALUE, gtype =>  G_TYPE_STRING.Int }
);

my @nested-objects;
@nested-objects.push: q:to/NESTED-OBJECT/.chomp;
  { "array" : [ false, "foo" ], "object" : { "foo" : true } }
  NESTED-OBJECT

@nested-objects.push: q:to/NESTED-OBJECT/.chomp;
  {
    "type" : "ClutterGroup",
    "width" : 1,
    "children" : [
      {
        "type" : "ClutterRectangle",
        "children" : [
          { "type" : "ClutterText", "text" : "hello there" }
        ]
      },
      {
        "type" : "ClutterGroup",
        "width" : 1,
        "children" : [
          { "type" : "ClutterText", "text" : "hello" }
        ]
      }
    ]
  }
  NESTED-OBJECT

my @assignments = (
  { str => 'var foo = [ false, false, true ]', var => 'foo' },
  { str => 'var bar = [ true, 42 ];',          var => 'bar' },
  { str => 'var baz = { "foo" : false }',      var => 'baz' }
);

my @unicode = (
  { str => '{ "test" : "foo ' ~ chr(0x00e8) ~ '" }', member => "test", match => 'foo è' }
);

subtest 'Empty with Parser', {
  sub test-empty-with-parser ($p) {
    unless $p.load-from-data($empty-string) {
      say "Error: { $ERROR.message }";
      exit 1;
    }

    nok $p.get-root, 'Parser returned a NULL value for empty-string';
  }

  my $p = JSON::GLib::Parser.new;
  isa-ok $p, JSON::GLib::Parser, 'Parser created successfully';
  test-empty-with-parser($p);

  $p = JSON::GLib::Parser.new( :immutable );
  isa-ok $p, JSON::GLib::Parser, 'Immutable Parser created successfully';
  test-empty-with-parser($p);
}

subtest 'Base Value', {
  my $p = JSON::GLib::Parser.new;
  isa-ok $p, JSON::GLib::Parser, 'Parser created successfully';

  for @base-values {
    unless $p.load-from-data( .<val>.lc.Str ) {
      diag "Error: { $ERROR.message }" if %*ENV<JSON_GLIB_VERBOSE>;
      exit 1;
    }

    my $root = $p.root;
    ok           $root,           "'{ .<val> }' - root node was obtained successfully";
    nok   $root.parent,           "'{ .<val> }' - root node has no parent";
    is $root.node-type,  .<type>, "'{ .<val> }' - root node is of the expected type";

    ok .<verify>($root),          "'{ .<val> }' - root node satisfies validation test"
      if .<verify>;
  }
}

subtest 'Empty Array', {
  my $p = JSON::GLib::Parser.new;
  isa-ok $p, JSON::GLib::Parser, 'Parser created successfully';

  unless $p.load-from-data($empty-array) {
    diag "Error: { $ERROR.message }" if %*ENV<JSON_GLIB_VERBOSE>;
    exit 1;
  }

  my $root = $p.root;
  ok $root,                            'Root node was obtained successfully';
  is $root.node-type, JSON_NODE_ARRAY, 'Root node is an ARRAY node';
  nok $root.parent,                    'Root node has no parent';

  my $a = $root.get-array;
  ok $a,                               'Array node at root is NOT Nil';
  is $a.elems,        0,               'Array node has 0 length';
}

subtest 'Simple Array', {
  my $p = JSON::GLib::Parser.new;
  isa-ok $p, JSON::GLib::Parser, 'Parser created successfully';

  for @simple-arrays {
    unless $p.load-from-data( .<str> ) {
      diag "Error: { $ERROR.message }" if %*ENV<JSON_GLIB_VERBOSE>;
      exit 1;
    }

    diag "'{ .<str> }'";
    my $root = $p.root;
    ok  $root,                                       'Root node was obtained successfully';
    nok $root.parent,                                'Root node has no parent';

    my $arr = $root.get-array;
    ok  $arr,                                        'Array node at root is NOT Nil';
    is  $arr.elems,              .<len>,             'Parsed array length agrees with expected result';

    my $n = $arr[ .<element> ];
    ok  $n,                                          "Node at Element { .<element> } is NOT Nil";
    is  +$n.parent.JsonNode.p,   +$root.JsonNode.p,  'Parent node is the root node';
    is  $n.node-type,            .<type>,            'Node type agrees with expected result';
    is  $n.value-type,           .<gtype>,           'Value type agrees with expected result';
  }
}

subtest 'Nested Array', {
  my $p = JSON::GLib::Parser.new;
  isa-ok $p, JSON::GLib::Parser, 'Parser created successfully';

  for @nested-arrays {
    unless $p.load-from-data($_) {
      diag "Error: { $ERROR.message }" if %*ENV<JSON_GLIB_VERBOSE>;
      exit 1;
    }

    diag $_;
    my $root = $p.root;
    ok  $root,                  'Root node was obtained successfully';
    nok $root.parent,           'Root node has no parent';

    my $arr = $root.get-array;
    ok $arr.elems > 0,          'Array has a non-zero length';
  }
}

{
  sub common-object-tests($p, $root is rw, $o is rw) {
    $root = $p.root;
    $o = $root.get-object;

    ok  $root,                              'Root node was obtained successfully';
    nok $root.parent,                       'Root node has no parent';
    is  $root.node-type, JSON_NODE_OBJECT,  'Root node is an OBJECT type';
    ok  $o,                                 'Object retrieved from root is NOT Nil';
  }

  subtest 'Empty Object', {
    my $p = JSON::GLib::Parser.new;
    isa-ok $p, JSON::GLib::Parser, 'Parser created successfully';

    unless $p.load-from-data($empty-object) {
      diag "Error: { $ERROR.message }" if %*ENV<JSON_GLIB_VERBOSE>;
      exit 1;
    }

    my ($root, $o);
    common-object-tests($p, $root, $o);

    is  $o.elems,        0,                 'Object has no entries';
  }

  subtest 'Simple Object', {
    my $p = JSON::GLib::Parser.new;
    isa-ok $p, JSON::GLib::Parser, 'Parser created successfully';

    for @simple-objects {
      unless $p.load-from-data( .<str> ) {
        diag "Error: { $ERROR.message }" if %*ENV<JSON_GLIB_VERBOSE>;
        exit 1;
      }

      diag .<str>;

      my ($root, $o);
      common-object-tests($p, $root, $o);

      is $o.elems,              .<size>,           'Object contains the expected number of members';

      my $n = $o.get-member( .<member> );
      ok $n,                                       "Member '{ .<member> }' retrieved successfully";
      is +$n.parent.JsonNode.p, +$root.JsonNode.p, 'Node parent is the root node';
      is $n.node-type,          .<type>,           "Node is the expected type ({ .<type> })";
      is $n.value-type,         .<gtype>,          "Node's value is the expected type ({ .<gtype> })";
    }
  }

  subtest 'Nested Objects', {
    my $p = JSON::GLib::Parser.new;
    isa-ok $p, JSON::GLib::Parser, 'Parser created successfully';

    for @nested-objects {
      unless $p.load-from-data($_) {
        diag "Error: { $ERROR.message }" if %*ENV<JSON_GLIB_VERBOSE>;
        exit 1;
      }

      diag $_;
      my ($root, $o);
      common-object-tests($p, $root, $o);

      ok $o.elems > 0,                               'Object is not empty';
    }
  }
}
