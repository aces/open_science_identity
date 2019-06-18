"use strict";
/** This class implements a strict hashing function for identifying
 *   a patient or subject in a study such that the resulting signature
 *   cannot be mapped back to the patient's private information.
 *
 *   Based on the Ruby implementation by Pierre Rioux.
 *
 *   John Saigle <john.saigle@mcgill.ca>
 */

let pbkdf2 = require('pbkdf2');
let transliterate = require('transliteration');

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
    this.PBKDF2_KEY_LENGTH = 32;

    this.GENDER_VALUES = [
        'male',
        'female',
        'unknown',
        'other'
    ];
    this.DOB_REGEX = /^(19|20)\d\d-(0[1-9]|1[012])-(0[1-9]|[12]\d|3[01])$/;
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
    if (! this.cleanFirstName()) {
        this.bad_attributes.push('first name');
    }
    // No check for middle name because it's optional
    if (! this.cleanLastName()) {
        this.bad_attributes.push('last name');
    }
    if (! this.cleanGender() || ! this.GENDER_VALUES.includes(this.cleanGender())
       ) 
   {
       this.bad_attributes.push('gender');
   }
   if (! this.birth_day || ! this.birth_day.match(this.DOB_REGEX))
   {
       this.bad_attributes.push('birthday');
   }
   if (! this.cleanCityOfBirth()) {
       this.bad_attributes.push('city of birth');
   }
   return this.bad_attributes.length === 0;
};

OpenScienceIdentity.prototype.validate = function() {
    if (! this.valid) {
        throw "Not all identity components have valid initial values: " 
        + this.bad_attributes.join(',');
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
    if (string === null || string.trim().length < 1) {
        return '';
    }
    let cleaned = transliterate.transliterate(string);
    cleaned = cleaned.toLowerCase();
    cleaned = cleaned.replace(/[^a-z0-9]+/g, '');
    return cleaned;
};

OpenScienceIdentity.prototype.toSignature = function() {
    this.validate;
    let sig_key = this.signatureKey();
    let salt = this.reverseString(sig_key);
    // Calculate hash. See below links for details.
    //      <https://nodejs.org/api/crypto.html#crypto_crypto_pbkdf2sync_password_salt_iterations_keylen_digest>
    //      <https://github.com/crypto-browserify/pbkdf2>
    let hash = pbkdf2.pbkdf2Sync(
        sig_key,
        salt,
        this.PBKDF2_ITERATIONS,
        this.PBKDF2_KEY_LENGTH,
        this.PBKDF2_HASH_FUNCTION
    );
    return hash.toString('hex');
};

// The below is an implementation of naive (i.e. not Unicode-aware) string
// reversal implemented in JavaScript and taken from StackOverflow
// <https://stackoverflow.com/a/959004/6189922>.
// It should work for our purposes since this will be only be called on the
// variable `sig_key` which represents a concatenation of "clean" input fields
// which have been transliterated into plain ASCII.
OpenScienceIdentity.prototype.reverseString = function(s) {
    return s.split('').reverse().join('');
};

// ======== BEGIN test code TODO put this in a separate file
const fs = require('fs'),
    readline = require('readline');

let rd = readline.createInterface({
    input: fs.createReadStream('../test/names_db.csv'),
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
    if (!line || line.startsWith('#')) {
        return;
    }
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

    console.log("KEY=" + id.signatureKey() + "");

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
    let realsig = '';
    try {
        realsig = id.toSignature();
    } catch (exception) {
        console.log("  => EXCEPTION, expected: " + sig);
        num_exc += 1;
        if (sig !== 'exception') {
            report += "Unexpected exception: " + exception + "\n";
        }
        return;
    }

    if (realsig !== sig) {
        console.log("  => SIGNATURE MISMATCH, got " + realsig + ", expected: " + sig);
        num_mis += 1;
        report += "Signature mismatch: Entry=" + line + "\n";
    } else {
        console.log( " => SIGNATURE OK, got " + realsig);
        num_sig += 1;
    }
});
rd.on('close', function() {
    if (report) { 
        console.log();
        console.log("Report of errors:");
        console.log(" => " + num_mis + " signatures FAILED TO MATCH");
        console.log(" => " + num_sig + "/" + num_exp_sig + " signatures verified");
        console.log(" => " + num_exc + "/ " + num_exp_exc + " exceptions");
        console.log(" => " + num_inv + "/" + num_exp_inv + " invalid entries");
        console.log(report);
    } else {
        console.log("All entries behaved **like expected**:");
        console.log(" => " + num_sig + "/" + num_exp_sig + " signatures verified");
        console.log(" => " + num_exc + "/" + num_exp_exc + " exceptions that were expected");
        console.log(" => " + num_inv + "/" + num_exp_inv + " invalid entries that were expected");
    }

});
