<?php

/** This class implements a strict hashing function for identifying
 *   a patient or subject in a study such that the resulting signature
 *   cannot be mapped back to the patient's private information.
 *
 *   Based on the Ruby implementation by Pierre Rioux.
 *
 *   @author John Saigle <john.saigle@mcgill.ca>
 */

error_reporting(E_ALL);

class OpenScienceIdentity {
    const IDENTITY_ATTRIBUTES = array(
        'gender',
        'first_name',
        'last_name',
        'birth_day',
        'city_of_birth',
    );
    const PBKDF2_ITERATIONS = 10000;
    const PBKDF2_SALT_FUNCTION = 'strrev';
    const PBKDF2_HASH_FUNCTION = 'sha256';

    // Validations
    const GENDER_VALUES = array(
        'male',
        'female',
        'unknown',
        'other'
    );
    const DOB_REGEX = '/^(19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12]\d|3[01])$/';
    public $bad_attributes = array();


    public function __construct(Array $attributes = []) {
        $this->gender = $attributes['gender'] ?? '';
        $this->first_name = $attributes['first_name'] ?? '';
        $this->middle_name = $attributes['middle_name'] ?? '';
        $this->last_name = $attributes['last_name'] ?? '';
        $this->birth_day = $attributes['birth_day'] ?? '';
        $this->city_of_birth = $attributes['city_of_birth'] ?? '';
    }

    private function cleanGender(): String {
        return $this->plainAlpha($this->gender);
    }

    private function cleanFirstName(): String {
        return $this->plainAlpha($this->first_name);
    }

    private function cleanMiddleName(): String {
        return $this->plainAlpha($this->middle_name);
    }

    private function cleanLastName(): String {
        return $this->plainAlpha($this->last_name);
    }
    private function cleanBirthDay(): String {
        return $this->plainAlpha($this->birth_day);
    }
    private function cleanCityOfBirth(): String {
        return $this->plainAlpha($this->city_of_birth);
    }

    public function valid(): Bool {
        $this->bad_attributes = array();
        if (empty($this->cleanFirstName())) {
            $this->bad_attributes[] = 'first name';
        }
        // No check for middle name because it is an optional field.
        if (empty($this->cleanLastName())) {
            $this->bad_attributes[] = 'last name';
        }
        if (empty($this->cleanGender()) ||
            !in_array($this->cleanGender(), $this::GENDER_VALUES)) 
        {
            $this->bad_attributes[] = 'gender';
        }
        if (empty($this->birth_day) ||
            ! preg_match($this::DOB_REGEX, $this->birth_day))
        {
            $this->bad_attributes[] = 'birthday';
        }
        if (empty($this->cleanCityOfBirth())) {
            $this->bad_attributes[] = 'city of birth';
        }
        return count($this->bad_attributes) === 0;
    }

    function validate() : Void {
        if (!$this->valid()) {
            throw new Exception(
                "Not all identity components have valid initial values: " 
                . implode(', ', $this->bad_attributes)
            );
        }
    }

    public function signatureKey(): String {
        $components = array(
            $this->cleanGender(),
            $this->cleanFirstName(),
            $this->cleanMiddleName(),
            $this->cleanLastName(),
            $this->cleanBirthDay(),
            $this->cleanCityOfBirth(),
        );
        # e.g. "male|pierre|tiberius|rioux|19211231|newyorkcity"
        return implode('|', $components);
    }

    private function plainAlpha($string): String {
        // If given a "blank" value, return the empty string.
        if (is_null($string) || strlen(trim($string)) < 1) {
            return "";
        }
        // Convert $string to a lower-case, anglicized ASCII version of itself
        setlocale(LC_CTYPE, 'en_US.UTF8');
        // iconv is here used to change accented characters to unaccented ones
        $string = iconv('UTF-8', 'us-ascii//TRANSLIT', $string);
        $cleaned_up = mb_strtolower($string);
        $cleaned_up = preg_replace('/[^a-z0-9]+/', '', $cleaned_up);

        # TODO: Transliteration check.
        #if (strlen($string) !== strlen($cleaned_up)) {
        #    throw(
        #        new Exception(
        #            "Unhandled multibyte characters in string: before '$string' after: '$cleaned_up'"
        #        )
        #    );
        #}
        return $cleaned_up;
    }

    public function toSignature(): String {
        $this->validate();
        $sig_key = $this->signatureKey();
        $salt = call_user_func($this::PBKDF2_SALT_FUNCTION, $sig_key);
        return hash_pbkdf2(
            $this::PBKDF2_HASH_FUNCTION,
            $sig_key, 
            $salt, 
            $this::PBKDF2_ITERATIONS
        );
    }
}
