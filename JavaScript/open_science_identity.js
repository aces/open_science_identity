"use strict";
/** This class implements a strict hashing function for identifying
 *   a patient or subject in a study such that the resulting signature
 *   cannot be mapped back to the patient's private information.
 *
 *   Based on the Ruby implementation by Pierre Rioux.
 *
 *   John Saigle <john.saigle@mcgill.ca>
 */
function OpenScienceIdentity(attributes = []){
    this.IDENTITY_ATTRIBUTES = [
        'gender',
        'first_name',
        'last_name',
        'birth_day',
        'city_of_birth',
    ];
    this.PBKDF2_ITERATIONS = 10000;
    this.PBKDF2_SALT_FUNCTION = ''//'strrev' #TODO Figure this out
    this.PBKDF2_HASH_FUNCTION = 'sha256';

    this.GENDER_VALUES = [
        'male',
        'female',
        'unknown',
        'other'
    ];
    this.DOB_REGEX = '/^(19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12]\d|3[01])$/';
    this.bad_attributes = [];

    this.gender        = attributes['gender']        || '';
    this.first_name    = attributes['first_name']    || '';
    this.middle_name   = attributes['middle_name']   || '';
    this.last_name     = attributes['last_name']     || '';
    this.birth_day     = attributes['birth_day']     || '';
    this.city_of_birth = attributes['city_of_birth'] || '';
}

OpenScienceIdentity.prototype.cleanGender = function() {
    return this.plainAlpha(this.gender);
};
OpenScienceIdentity.prototype.cleanFirstName = function() {
    return this.plainAlpha(this.first_name);
};
OpenScienceIdentity.prototype.cleanMiddleName = function() {
    return this.plainAlpha(this.middle_name);
};
OpenScienceIdentity.prototype.cleanLastName = function() {
    return this.plainAlpha(this.last_name);
};
OpenScienceIdentity.prototype.cleanBirthDay = function() {
    return this.plainAlpha(this.birth_day);
};
OpenScienceIdentity.prototype.cleanCityOfBirth = function() {
    return this.plainAlpha(this.city_of_birth);
};

OpenScienceIdentity.prototype.valid = function() {
    this.bad_attributes = [];
    if (this.cleanFirstName().length < 0) {
        this.bad_attributes.push('first name');
    }
    if (this.cleanMiddleName().length < 0) {
        this.bad_attributes.push('middle name');
    }
    if (this.cleanLastName().length < 0) {
        this.bad_attributes.push('last name');
    }
    if (this.cleanGender().length < 0 ||
        ! this.GENDER_VALUES.includes(this.cleanGender)
       ) 
   {
       this.bad_attributes.push('gender');
   }
   // TODO: ! birthday preg match...
   if (this.birth_day.length < 0)
   {
       this.bad_attributes.push('birthday');
   }
   if (this.cleanCityOfBirth().length < 0) {
       this.bad_attributes.push('city of birth');
   }
   return this.bad_attributes.length === 0;
};

OpenScienceIdentity.prototype.validate = function() {
    if (! this.valid) {
        console.log("An exception! Fill me in");
        // throw an exception
    }
};

OpenScienceIdentity.prototype.signatureKey = function() {
    let components = [
        this.cleanGender(),
        this.cleanFirstName(),
        this.cleanMiddleName(),
        this.cleanLastName(),
        this.cleanBirthDay(),
        this.cleanCityOfBirth()
    ];
    // e.g. "male|pierre|tiberius|rioux|19211231|newyorkcity"
    return components.join('|');
};

OpenScienceIdentity.prototype.plainAlpha = function(string) {
    // do transliterate
    // to lower case
    // preg replace non alphanum
    return string;
};

OpenScienceIdentity.prototype.toSignature = function() {
    this.validate;
    let sig_key = this.signatureKey;
    // do hashing
    return "hash";
};

// BEGIN test code
const fs = require('fs'),
    readline = require('readline');

let rd = readline.createInterface({
    input: fs.createReadStream('../Ruby/names_db.csv'), //TODO: don't store this file in Ruby dir
    console: false
});

let report  = "";
let num_sig = 0;
let num_exp_sig = 0;
let num_mis = 0;
let num_exc = 0;
let num_exp_exc = 0;
let num_inv = 0;
let num_exp_inv = 0;

// For every line, create a new identity and check that the result is valid.
rd.on('line', function(line) {
    console.log(line);
    let parts = line.split(',');
    let id = new OpenScienceIdentity(
        {
            "gender": parts[0],
            "first_name": parts[1],
            "middle_name": parts[2],
            "last_name": parts[3],
            "birth_day": parts[4],
            "city_of_birth": parts[5]
        }
    );
    let sig = parts[6];
    // Keep track of totals
    if (sig === 'invalid') {
        num_exp_inv += 1;
    } else if (sig === 'exception') {
        num_exp_exc += 1;
    } else {
        num_exp_sig += 1;
    }

    console.log("KEY={" + id.signatureKey() + "}");

    if (! id.valid()) {
        console.log(" => INVALID. expected " + sig);
        num_inv += 1;
        if (sig !== 'invalid') {
            report += "Unexpected invalid: ";
            report += id.bad_attributes.join(',');
            report += " Entry=" + line + "\n";
        }
        return;
    }
});
