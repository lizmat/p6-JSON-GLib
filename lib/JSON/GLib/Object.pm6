use v6.c;

use NativeCall;

use JSON::GLib::Raw::Types;
use JSON::GLib::Raw::ObjectNodeArray;

use JSON::GLib::Array;
use JSON::GLib::Node;

# BOXED
class JSON::GLib::Object {
  has JsonObject $!jo;

  submethod BUILD ( :object(:$!jo) ) {  }

  multi method new (JsonObject $object) {
    $object ?? self.bless( :$object ) !! Nil;
  }
  multi method new {
    my $object = json_object_new();

    $object ?? self.bless( :$object ) !! Nil;
  }

  method JSON::GLib::Definitions::JsonObject
  { $!jo }

  method add_member (Str() $member_name, JsonNode() $node) {
    json_object_add_member($!jo, $member_name, $node);
  }

  method dup_member (Str() $member_name, :$raw = False) {
    my $n = json_object_dup_member($!jo, $member_name);

    $n ??
      ( $raw ?? $n !! JSON::GLib::Node.new($n) )
      !!
      Nil
  }

  method equal (JsonObject() $b) {
    so json_object_equal($!jo, $b);
  }

  method foreach_member (&func, gpointer $data = gpointer) {
    json_object_foreach_member($!jo, &func, $data);
  }

  method get_array_member (Str() $member_name, :$raw = False) {
    my $a = json_object_get_array_member($!jo, $member_name);

    $raw ??
      ( $raw ?? $a !! JSON::GLib::Array.new($a) )
      !!
      Nil;
  }

  method get_boolean_member (Str() $member_name) {
    so json_object_get_boolean_member($!jo, $member_name);
  }

  method get_double_member (Str $member_name) {
    json_object_get_double_member($!jo, $member_name);
  }

  method get_int_member (Str $member_name) {
    json_object_get_int_member($!jo, $member_name);
  }

  method get_member (Str() $member_name, :$raw = False) {
    my $n = json_object_get_member($!jo, $member_name);

    $n ??
      ( $raw ?? $n !! JSON::GLib::Node.new($n) )
      !!
      Nil;
  }

  method get_members (:$glist = False, :$raw = False) {
    my $ml = json_object_get_members($!jo);

    return Nil unless $ml;
    return $ml if $glist && $raw;

    $ml = GLib::GList.new($ml) but GLib::Roles::ListData[JsonNode];
    return $ml if $glist;

    $raw ?? $ml.Array
         !! $ml.Array.map({ JSON::GLib::Node.new($_) }).Array;
  }

  method get_null_member (Str() $member_name) {
    so json_object_get_null_member($!jo, $member_name);
  }

  method get_object_member (Str() $member_name, :$raw = False) {
    my $o = json_object_get_object_member($!jo, $member_name);

    $o ??
      ( $raw ?? $o !! JSON::GLib::Object.new($o) )
      !!
      Nil;
  }

  method get_size {
    json_object_get_size($!jo);
  }

  method get_string_member (Str() $member_name) {
    json_object_get_string_member($!jo, $member_name);
  }

  method get_type {
    state ($n, $t);

    unstable_get_type(self.^name, &json_object_get_type, $n, $t );
  }

  method get_values (:$glist = False, :$raw = False) {
    my $nl = json_object_get_values($!jo);

    return Nil unless $nl;
    return $nl if $glist && $raw;

    $nl = GLib::GList.new($nl) but GLib::Roles::ListData[JsonNode];
    return $nl if $glist;

    $raw ?? $nl.Array
         !! $nl.Array.map({ JSON::GLib::Node.new($_) }).Array;
  }

  method has_member (Str() $member_name) {
    so json_object_has_member($!jo, $member_name);
  }

  method hash {
    json_object_hash($!jo);
  }

  method is_immutable {
    so json_object_is_immutable($!jo);
  }

  method iter_init {
    JSON::GLib::Object::Iter.init(self);
  }

  method ref {
    json_object_ref($!jo);
  }

  method remove_member (Str() $member_name) {
    json_object_remove_member($!jo, $member_name);
  }

  method seal {
    json_object_seal($!jo);
  }

  method set_array_member (Str() $member_name, JsonArray() $value) {
    json_object_set_array_member($!jo, $member_name, $value);
  }

  method set_boolean_member (Str() $member_name, Int() $value) {
    my gboolean $v = $value.so.Int;

    json_object_set_boolean_member($!jo, $member_name, $v);
  }

  method set_double_member (Str() $member_name, Num() $value) {
    my gdouble $v = $value;

    json_object_set_double_member($!jo, $member_name, $v);
  }

  method set_int_member (Str() $member_name, Int() $value) {
    my gint64 $v = $value;

    json_object_set_int_member($!jo, $member_name, $v);
  }

  method set_member (Str() $member_name, JsonNode() $node) {
    json_object_set_member($!jo, $member_name, $node);
  }

  method set_null_member (Str() $member_name) {
    json_object_set_null_member($!jo, $member_name);
  }

  method set_object_member (Str() $member_name, JsonObject() $value) {
    json_object_set_object_member($!jo, $member_name, $value);
  }

  method set_string_member (Str() $member_name, Str() $value) {
    json_object_set_string_member($!jo, $member_name, $value);
  }

  method unref {
    json_object_unref($!jo);
  }

}

class JSON::GLib::ObjectIter {
  has JsonObjectIter $!joi;
  has                $!last_member_name;

  submethod BUILD ( :iter(:$!joi) ) { }

  method new (JsonObject() $object) {
    my $iter = self.init($object);

    $iter ?? self.bless( :$iter ) !! Nil;
  }

  method JSON::GLib::Definitions::JsonObjectIter
  { $!joi }

  multi method init (JSON::GLib::ObjectIter:U: JsonObject() $object) {
    my $joi = JsonObjectIter.new;

    samewith($joi, $object);
  }
  multi method init (
    JSON::GLib::ObjectIter:U:
    JsonObjectIter $iter,
    JsonObject() $object
  ) {
    json_object_iter_init($iter, $object);
  }

  multi method next (:$raw = False) {
    samewith(Str, :$raw);
  }
  multi method next (Str() $member_name, :$raw = False) {
    samewith($member_name, $, :$raw);
  }
  multi method next (Str() $member_name, $member_node is rw, :$raw = True) {
    my $mn = CArray[Pointer[JsonNode]].new;
    $mn[0] = Pointer[JsonNode];
    $!last_member_name = $member_name if $member_name;

    my $rv = so json_object_iter_next($!joi, $!last_member_name, $mn);
    $member_node = ppr($mn);
    $member_node = JSON::GLib::Node.new($member_node)
      if $member_node && $raw.not;
    $rv;
  }

}
