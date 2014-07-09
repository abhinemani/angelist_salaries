require 'net/http'
require 'json'

base_url = "http://api.angel.co/1/jobs"
pages = 76
list = []

puts "Going through #{pages} pages."

pages.times do |i|
  uri = URI("#{base_url}?page=#{i+1}")
  puts "Downloading #{uri}"
  res = Net::HTTP.get(uri)
  data = JSON.parse(res)["jobs"].to_a
  list += data
  sleep 2
end

filename = "#{Time.now.to_i}.json"
File.open("downloaded/#{filename}", "w+") do |f|
  f.write(JSON.dump(list))
end

puts "Saved #{list.size} jobs to #{filename}."