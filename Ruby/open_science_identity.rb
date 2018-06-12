
require 'i18n'
require 'active_support/all'
require 'pbkdf2'

class OpenScienceIdentity

  IDENTITY_ATTRIBUTES        = %i( gender first_name middle_name last_name birth_day city_of_birth )
  PBKDF2_ITERATIONS          = 10000
  PBKDF2_SALT_FUNCTION       = Proc.new { |s| s.reverse }
  PBKDF2_HASH_FUNCTION_CLASS = OpenSSL::Digest::SHA256

  # Validations
  GENDER_VALUES = %w( male female other unknown ) # TODO, adjust based on convention
  DOB_REGEX     = /^(19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12]\d|3[01])$/ # TODO, check month lengths?

  attr_accessor *IDENTITY_ATTRIBUTES
  attr_reader   :bad_attributes

  def initialize(attr_hash={})
    attr_hash.slice(*IDENTITY_ATTRIBUTES).each do |attr_name,value|
      self.send "#{attr_name}=", value
    end
  end

  IDENTITY_ATTRIBUTES.each do |attr_name|
    define_method "clean_#{attr_name}" do
      plain_alpha(self.send attr_name)
    end
  end

  def valid?
    @bad_attributes = []
    IDENTITY_ATTRIBUTES.each do |attr_name|
      @bad_attributes << attr_name if self.send(attr_name).nil?
    end
    @bad_attributes << :gender    if self.gender.present? &&
                                     (! GENDER_VALUES.include? self.clean_gender)
    @bad_attributes << :birth_day if self.birth_day.present? &&
                                     (! DOB_REGEX.match?       self.birth_day)
    @bad_attributes.size == 0
  end

  def validate!
    raise "Not all identity components have valid initial values: #{@bad_attributes.join(", ")}" unless self.valid?
  end

  def hash_key
    components = IDENTITY_ATTRIBUTES
      .map { |attr_name| self.send "clean_#{attr_name}" }
    components.join('|') # e.g. "male|pierre|tiberius|rioux|1901-01-01|newyorkcity"
  end

  def to_signature

    self.validate!

    bar_key  = self.hash_key
    salt     = PBKDF2_SALT_FUNCTION.call(bar_key)

    pbkdf2               = PBKDF2.new(
                             :password   => bar_key,
                             :salt       => salt,
                             :iterations => PBKDF2_ITERATIONS
                           )
    pbkdf2.hash_function = PBKDF2_HASH_FUNCTION_CLASS.new
    pbkdf2.hex_string
  end

  private

  def plain_alpha(string)
    cleaned_up = I18n
      .transliterate(string, :locale => :en)  # tranforms accented characters to unaccented ones
      .downcase
      .gsub(/[^a-z0-9]+/,"")

    if cleaned_up.each_byte.to_a.size != cleaned_up.each_char.to_a.size
      raise "Unhandled multibyte characters in string: before: '#{string}' after: '#{cleaned_up}'"
    end

    raise "Empty string produced after cleaning '#{string}'" if cleaned_up.blank?

    cleaned_up
  end

end
