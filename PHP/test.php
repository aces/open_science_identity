<?php

error_reporting(E_ALL);
// If experiencing errors with encoding, uncomment this line and verify the 
// encodings are set to UTF-8.
//var_dump(iconv_get_encoding('all'));

require('open_science_identity.php');

$report  = "";
$num_sig = $num_exp_sig = 0;
$num_mis = 0;
$num_exc = $num_exp_exc = 0;
$num_inv = $num_exp_inv = 0;

// TODO: move the test db from the Ruby folder
// Open the CSV database.  Iterate over each line and store the values in the
// array $line.  Extract these values into individual variables.
$db_filepath = "../Ruby/names_db.csv";
if (($handle = fopen($db_filepath, "r")) !== FALSE) {
    while (($line = fgetcsv($handle, 1000, ",")) !== FALSE) {
        list($gender, $first_name, $middle_name, $last_name, $birth_day, $city_of_birth, $sig) = $line;
        // Keep track of totals
        if ($sig === 'invalid') {
            $num_exp_inv += 1;
        } else if ($sig === 'exception') {
            $num_exp_exc += 1;
        } else {
            $num_exp_sig += 1;
        }

        $id = new OpenScienceIdentity(
          compact(
              "gender",
              "first_name",
              "middle_name",
              "last_name",
              "birth_day",
              "city_of_birth"
          )
        );
        echo "KEY={$id->signatureKey()}\n";

        if (! $id->valid()) {
            // TODO: add verbosity levels.
            echo " => INVALID. expected $sig\n";
            $num_inv += 1;
            if ($sig !== 'invalid') {
                $report .= "Unexpected invalid: ";
                $report .= implode(', ', $id->bad_attributes);
                $report .= " Entry=" . implode(',', $line) . "\n";
            }
            continue;
        }

        try {
            $realsig = $id->toSignature();
        } catch (Exception $e) {
            echo "  => EXCEPTION, expected: {$sig}\n";
            $num_exc += 1;
            if ($sig !== 'exception') {
                $report .= "Unexpected exception: {$e->getMessage()}\n";
            }
            continue;
        }

        if ($realsig !== $sig) {
            echo "  => SIGNATURE MISMATCH, got {$realsig}, expected: {$sig}\n";
            $num_mis += 1;
            $report .= "Signature mismatch: Entry=" . implode(',', $line) . "\n";
        } else {
            echo " => SIGNATURE OK, got {$realsig}\n";
            $num_sig += 1;
        }
    }
    fclose($handle);
}
if (!empty($report)) { 
    echo "Report of errors:\n\n";
    echo " => {$num_mis} signatures FAILED TO MATCH\n";
    echo " => {$num_sig}/{$num_exp_sig} signatures verified\n";
    echo " => {$num_exc}/{$num_exp_exc} exceptions\n";
    echo " => {$num_inv}/{$num_exp_inv} invalid entries\n";
    echo $report;
} else {
    echo "All entries behaved **like expected**:\n\n";
    echo " => {$num_sig}/{$num_exp_sig} signatures verified\n";
    echo " => {$num_exc}/{$num_exp_exc} exceptions that were expected\n";
    echo " => {$num_inv}/{$num_exp_inv} invalid entries that were expected\n";
}

