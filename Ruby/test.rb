#!/usr/bin/env ruby

require './open_science_identity.rb'

report       = ""
num_sig      = 0
num_mis      = 0
num_exc      = 0
num_inv      = 0
verbose      = ARGV.size

corrected_db = File.open("new_names_db.csv","w:UTF-8")
read_db      = File.open("names_db.csv","r:UTF-8")

while line = (read_db.readline rescue nil)
  line.strip!
  puts "---------------" if verbose > 0
  puts "LINE=#{line}"    if verbose > 1
  comps = line.split(/\s*,\s*/)
  gender, first, middle, last, dob, city, sig = *comps
  id = OpenScienceIdentity.new(
    :gender        => gender,
    :first_name    => first,
    :middle_name   => middle,
    :last_name     => last,
    :birth_day     => dob,
    :city_of_birth => city,
  )
  puts "KEY=#{(id.hash_key rescue 'exception')}" if verbose > 0

  if ! id.valid?
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
    num_exc += 1
    if sig != 'exception'
      report += "Unexcepted exception: #{ex.class} #{ex.message} ; Entry=#{line}\n"
    end
    corrected_db.write([gender, first, middle, last, dob, city, "exception"].join(",") + "\n")
    next
  end

  if realsig != sig
    num_mis += 1
    report += "Signature mismatch: Entry=#{line}\n"
  else
    num_sig += 1
  end
  corrected_db.write([gender, first, middle, last, dob, city, realsig].join(",") + "\n")

end

read_db.close
corrected_db.close

if report.present?
  puts "Report of errors:\n"
  puts report
else
  puts "All entries behaved like expected:\n"
  puts " => #{num_sig} signatures verified"
  puts " => #{num_exc} exceptions"
  puts " => #{num_inv} invalid entries"
end

