
require 'active_support/all'
require 'i18n'
require 'pbkdf2'

#
# This class implements a strict hashing function for identifying
# a patient or subject in a study such that the resulting signature
# cannot be mapped back to the patient's private information.
#
# Usage:
#
#   id_obj = OpenScienceIdentity.new(
#              :gender        => "Male",
#              :first_name    => "Pierre",
#              :middle_name   => "Severus",
#              :last_name     => "Rioux",
#              :birth_day     => "1902-04-30",
#              :city_of_birth => "Istanbul, not constantinople",
#            )
#   id_obj.validate! # will raise exception if any of the values are not allowed
#   signature = id_ob.to_signature # PBKDF2 over SHA256
#
class OpenScienceIdentity

  IDENTITY_ATTRIBUTES        = %i( gender first_name middle_name last_name birth_day city_of_birth )
  PBKDF2_ITERATIONS          = 10000
  PBKDF2_SALT_FUNCTION       = Proc.new { |s| s.reverse }
  PBKDF2_HASH_FUNCTION_CLASS = OpenSSL::Digest::SHA256

  # Validations
  GENDER_VALUES = %w( male female other unknown ) # TODO, adjust based on convention
  DOB_REGEX     = /^(19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12]\d|3[01])$/ # TODO, check month lengths?

  # Attribute accessors
  #
  # Note: I explicitely avoided using 'attr_accessor' etc so that this
  # code base could be easily adapted in other OO languages.

  def gender
    @gender
  end

  def gender=(val)
    @gender=val
  end

  def clean_gender
    plain_alpha(self.gender)
  end

  def first_name
    @first_name
  end

  def first_name=(val)
    @first_name=val
  end

  def clean_first_name
    plain_alpha(self.first_name)
  end

  def middle_name
    @middle_name
  end

  def middle_name=(val)
    @middle_name=val
  end

  def clean_middle_name
    plain_alpha(self.middle_name)
  end

  def last_name
    @last_name
  end

  def last_name=(val)
    @last_name=val
  end

  def clean_last_name
    plain_alpha(self.last_name)
  end

  def birth_day
    @birth_day
  end

  def birth_day=(val)
    @birth_day=val
  end

  def clean_birth_day
    plain_alpha(self.birth_day)
  end

  def city_of_birth
    @city_of_birth
  end

  def city_of_birth=(val)
    @city_of_birth=val
  end

  def clean_city_of_birth
    plain_alpha(self.city_of_birth)
  end

  def bad_attributes
    @bad_attributes
  end

  def initialize(attr_hash={})
    self.gender        = attr_hash[:gender]        if attr_hash.has_key?(:gender)
    self.first_name    = attr_hash[:first_name]    if attr_hash.has_key?(:first_name)
    self.middle_name   = attr_hash[:middle_name]   if attr_hash.has_key?(:middle_name)
    self.last_name     = attr_hash[:last_name]     if attr_hash.has_key?(:last_name)
    self.birth_day     = attr_hash[:birth_day]     if attr_hash.has_key?(:birth_day)
    self.city_of_birth = attr_hash[:city_of_birth] if attr_hash.has_key?(:city_of_birth)
    self
  end

  def valid?
    @bad_attributes = []
    @bad_attributes << :first_name    if self.clean_first_name.blank?
    #@bad_attributes << :middle_name   if self.clean_middle_name.blank?
    @bad_attributes << :last_name     if self.clean_last_name.blank?
    @bad_attributes << :gender        if self.gender.blank? ||
                                         (! GENDER_VALUES.include? self.clean_gender)
    @bad_attributes << :birth_day     if self.birth_day.blank? ||
                                         (! DOB_REGEX.match?       self.birth_day)
    @bad_attributes << :city_of_birth if self.clean_city_of_birth.blank?
    @bad_attributes.size == 0
  end

  def validate!
    raise "Not all identity components have valid initial values: #{@bad_attributes.join(", ")}" unless self.valid?
  end

  def signature_key
    components = [
      self.clean_gender,
      self.clean_first_name,
      self.clean_middle_name,
      self.clean_last_name,
      self.clean_birth_day,
      self.clean_city_of_birth,
    ]
    components.join('|') # e.g. "male|pierre|tiberius|rioux|19211231|newyorkcity"
  end

  def to_signature
    self.validate!
    sig_key  = self.signature_key
    salt     = PBKDF2_SALT_FUNCTION.call(sig_key)
    pbkdf2   = PBKDF2.new(
                 :password   => sig_key,
                 :salt       => salt,
                 :iterations => PBKDF2_ITERATIONS
               )
    pbkdf2.hash_function = PBKDF2_HASH_FUNCTION_CLASS.new
    pbkdf2.hex_string
  end

  private

  def plain_alpha(string)

    # Blank strings or nil are allowed! (e.g. mostly for middle name),
    # and it's not the role of this method to allow or reject them.
    return "" if string.blank?

    cleaned_up = I18n
      .transliterate(string, :locale => :en)  # tranforms accented characters to unaccented ones
      .downcase
      .gsub(/[^a-z0-9]+/,"")

    # Check that we can really transform every multibyte character
    if cleaned_up.each_byte.to_a.size != cleaned_up.each_char.to_a.size
      raise "Unhandled multibyte characters in string: before: '#{string}' after: '#{cleaned_up}'"
    end

    cleaned_up
  end

end
