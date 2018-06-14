#!/usr/bin/env ruby

require './open_science_identity.rb'

report  = ""
num_sig = 0  ; num_exp_sig = 0
num_mis = 0
num_exc = 0  ; num_exp_exc = 0
num_inv = 0  ; num_exp_inv = 0

verbose = ARGV.size

corrected_db = File.open("new_names_db.csv","w:UTF-8")
read_db      = File.open("names_db.csv","r:UTF-8")

while line = (read_db.readline rescue nil)
  line.strip!
  print "."              if verbose == 1
  puts "---------------" if verbose > 1
  puts "LINE=#{line}"    if verbose > 2
  comps = line.split(/\s*,\s*/)
  gender, first, middle, last, dob, city, sig = *comps

  if sig == 'invalid'
    num_exp_inv += 1
  elsif sig == 'exception'
    num_exp_exc += 1
  else
    num_exp_sig += 1
  end

  id = OpenScienceIdentity.new(
    :gender        => gender,
    :first_name    => first,
    :middle_name   => middle,
    :last_name     => last,
    :birth_day     => dob,
    :city_of_birth => city,
  )
  puts "KEY=#{(id.signature_key rescue 'exception')}" if verbose > 1

  if ! id.valid?
    puts "  => INVALID, expected: #{sig}" if verbose > 3
    num_inv += 1
    if sig != 'invalid'
      report += "Unexpected invalid: "
      report += id.bad_attributes.join(", ") + " Entry=#{line}\n"
    end
    corrected_db.write([gender, first, middle, last, dob, city, "invalid"].join(",") + "\n")
    next
  end

  realsig = nil
  begin
    realsig = id.to_signature
  rescue => ex
    puts "  => EXCEPTION, expected: #{sig}" if verbose > 3
    num_exc += 1
    if sig != 'exception'
      report += "Unexcepted exception: #{ex.class} #{ex.message} ; Entry=#{line}\n"
    end
    corrected_db.write([gender, first, middle, last, dob, city, "exception"].join(",") + "\n")
    next
  end

  if realsig != sig
    puts "  => SIGNATURE MISMATCH, got #{realsig}, expected: #{sig}" if verbose > 3
    num_mis += 1
    report += "Signature mismatch: Entry=#{line}\n"
  else
    puts "  => SIGNATURE OK, got #{realsig}" if verbose > 3
    num_sig += 1
  end
  corrected_db.write([gender, first, middle, last, dob, city, realsig].join(",") + "\n")

end

read_db.close
corrected_db.close

puts "\n"

if report.present?
  puts "Report of errors:\n"
  puts " => #{num_mis} signatures FAILED TO MATCH"
  puts " => #{num_sig}/#{num_exp_sig} signatures verified"
  puts " => #{num_exc}/#{num_exp_exc} exceptions"
  puts " => #{num_inv}/#{num_exp_inv} invalid entries"
  puts report
else
  puts "All entries behaved **like expected**:\n"
  puts " => #{num_sig}/#{num_exp_sig} signatures verified"
  puts " => #{num_exc}/#{num_exp_exc} exceptions that were expected"
  puts " => #{num_inv}/#{num_exp_inv} invalid entries that were expected"
end

