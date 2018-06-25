#!/bin/perl

use warnings;
use strict;
use utf8;
use Text::Unidecode;

package OpenScienceIdentity;

our @IDENTITY_ATTRIBUTES = qw( gender first_name middle_name last_name birth_day city_of_birth );

our $PBKDF2_ITERATIONS          = 10000;
our $PBKDF2_SALT_FUNCTION       = 'todo';
our $PBKDF2_HASH_FUNCTION_CLASS = 'todo';

# Validations
our @GENDER_VALUES = qw( male female other unknown ); # TODO, adjust based on convention
our $DOB_REGEX     = '^(19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12]\d|3[01])$'; # TODO, check month lengths?

#####################################
# Constructor
#####################################

sub new {
  my $self  = shift;
  my $class = ref($self) || $self;

  my $attr_hash = shift || {};

  my $new   = {};
  bless($new,$class);

  $new->set_gender(        $attr_hash->{'gender'}        ) if defined($attr_hash->{'gender'}       );
  $new->set_first_name(    $attr_hash->{'first_name'}    ) if defined($attr_hash->{'first_name'}   );
  $new->set_middle_name(   $attr_hash->{'middle_name'}   ) if defined($attr_hash->{'middle_name'}  );
  $new->set_last_name(     $attr_hash->{'last_name'}     ) if defined($attr_hash->{'last_name'}    );
  $new->set_birth_day(     $attr_hash->{'birth_day'}     ) if defined($attr_hash->{'birth_day'}    );
  $new->set_city_of_birth( $attr_hash->{'city_of_birth'} ) if defined($attr_hash->{'city_of_birth'});

  return $new;
}

#####################################
# Attribute setter and getter methods
#####################################

sub gender {
  my $self  = shift;
  my $val   = shift;
  $self->{'gender'} = $val if defined($val);
  $self->{'gender'};
}

sub first_name {
  my $self  = shift;
  my $val   = shift;
  $self->{'first_name'} = $val if defined($val);
  $self->{'first_name'};
}

sub middle_name {
  my $self  = shift;
  my $val   = shift;
  $self->{'middle_name'} = $val if defined($val);
  $self->{'middle_name'};
}

sub last_name {
  my $self  = shift;
  my $val   = shift;
  $self->{'last_name'} = $val if defined($val);
  $self->{'last_name'};
}

sub birth_day {
  my $self  = shift;
  my $val   = shift;
  $self->{'birth_day'} = $val if defined($val);
  $self->{'birth_day'};
}

sub city_of_birth {
  my $self  = shift;
  my $val   = shift;
  $self->{'city_of_birth'} = $val if defined($val);
  $self->{'city_of_birth'};
}

#####################################
# Getter methods for clean attributes
#####################################

sub clean_gender {
  my $self  = shift;
  &plain_alpha($self->{'gender'});
}

sub clean_first_name {
  my $self  = shift;
  &plain_alpha($self->{'first_name'});
}

sub clean_middle_name {
  my $self  = shift;
  &plain_alpha($self->{'middle_name'});
}

sub clean_last_name {
  my $self  = shift;
  &plain_alpha($self->{'last_name'});
}

sub clean_birth_day {
  my $self  = shift;
  &plain_alpha($self->{'birth_day'});
}

sub clean_city_of_birth {
  my $self  = shift;
  &plain_alpha($self->{'city_of_birth'});
}

sub is_valid {
  my $self  = shift;

  my $bad = $self->{'_bad_attributes'} = [];

  push(@$bad, 'gender')        if &is_blank($self->clean_gender());
  push(@$bad, 'first_name')    if &is_blank($self->clean_first_name());
  push(@$bad, 'middle_name')   if &is_blank($self->clean_middle_name());
  push(@$bad, 'last_name')     if &is_blank($self->clean_last_name());
  push(@$bad, 'birth_day')     if &is_blank($self->clean_birth_day());
  push(@$bad, 'city_of_birth') if &is_blank($self->clean_city_of_birth());

  return (scalar(@$bad) == 0);
}

sub validate {
  my $self  = shift;
  my $valid = $self->is_valid();
  return if $valid;
  my $bad = join(", ",@{$self->{'_bad_attributes'}});
  die "Not all identity components have valid initial values: $bad\n";
}

sub signature_key {
  my $self  = shift;
  my @components = (
    $self->clean_gender(),
    $self->clean_first_name(),
    $self->clean_middle_name(),
    $self->clean_last_name(),
    $self->clean_birth_day(),
    $self->clean_city_of_birth(),
  );
  my $key = join("|",@components); # e.g. "male|pierre|tiberius|rioux|19211231|newyorkcity"
  return $key;
}

sub to_signature {
  my $self  = shift;
  # TODO
}

#####################################
# Internal subroutines and methods
#####################################

sub plain_alpha {
  my $string = shift;
  # TODO
  # Likely to use:
  #   $transliterated = unidecode("String with accents here")
}

sub is_blank {
  my $string = shift;
  return 1 if ! defined($string);
  return 1 if $string =~ /^\s*$/;
  return undef;
}

1; # End of package OpenScienceIdentity
