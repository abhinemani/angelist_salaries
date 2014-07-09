require 'bundler'
require 'json'

VALID_LOCATIONS = ["Atlanta","Austin","Berkeley","Boston","Boulder","Burlingame","California","Cambridge","Culver City", "Cupertino","Dallas","Denver","Fremont","Houston","Las Vegas","Long Beach","Los Angeles","Los Gatos","Manhattan Beach","Mountain View","New Jersey","Menlo Park","Miami","Mill Valley","Milpitas","New York","New York City","Newark","Palm Beach","Palo Alto","Pasadena, CA", "Philadelphia","Phoenix","Pittsburg","Redmond","Redwood City","Reno","Sacramento","San Bruno","San Carlos, CA","San Diego","San Francisco","San Jose","San Mateo","San Ramon","Santa Barbara","Santa Clara, CA","Santa Cruz","Santa Monica","Santa Rosa","Saratoga","Seattle","Silicon Valley","Sonoma","Southern California","Stanford","Stockton","Sunnyvale","Tacoma","Tampa","Washington, DC"]

latest_file = Dir.glob("downloaded/*.json").max_by {|f| File.mtime(f)}
all_jobs = JSON.parse(File.read(latest_file))
all_companies = {}
selected_companies = []

all_jobs.each do |job|
  company_id = job["startup"]["id"]
  location = nil

  location = job["tags"].detect { |t| t["tag_type"] == "LocationTag" }
  location = location["display_name"] if location

  if VALID_LOCATIONS.include?(location)
    unless all_companies[company_id]
      all_companies[company_id] = {
        :id => company_id,
        :name => job["startup"]["name"],
        :url => job["startup"]["company_url"],
        :jobs => []
      }
    end

    j = {
      :id => job["id"],
      :title => job["title"],
      :salary_range => [job["salary_min"].to_i/1000, job["salary_max"].to_i/1000],
      :equity_range => [job["equity_min"], job["equity_max"]],
      :location => location
    }

    all_companies[company_id][:jobs] << j
  else
    puts "Skipping job in #{location}."
  end
end

do_this = false
all_companies.each do |k, company|
  company[:jobs].each do |job|
    do_this = !!(job[:title] =~ /designer/i) && job[:salary_range][0] > 0
    break if do_this
  end

  if do_this
    selected_companies << company
  end

end

#####

html = "<html>"
html << "<head><style> table tr, table th { text-align: left; } table tr.non-designer td, table tr.non-designer th { color: #aaa; } </style></head>"
html << "<body><h1>Companies and Jobs</h1><table>"
html << "<thead><tr><th>Company</th><th>Location</th><th>Position</th><th>Salary</th><th>Equity</th></tr></thead>"
html << "<tbody>"

selected_companies.each do |company|
  company[:jobs].each do |job|
    if job[:title] =~ /designer/i
      html << "<tr>"
    else
      html << '<tr class="non-designer">'
    end
    html << "<th><a href='#{company[:url]}'>#{company[:name]}</a></th>"
    # html << "<th>#{company[:name]}</th>"
    html << "<td>#{job[:location]}</td>"
    html << "<td>#{job[:title]}</td>"
    html << "<td>#{job[:salary_range][0]}-#{job[:salary_range][1]}k</td>"
    html << "<td>#{job[:equity_range][0]}-#{job[:equity_range][1]}%</td>"
  end
end
html << "</tbody></table></body></html>"

filename = "#{Time.now.to_i}.html"
File.open("output/#{filename}", "w+") do |f|
  f.write(html)
end

puts "Saved #{selected_companies.size} to #{filename}."