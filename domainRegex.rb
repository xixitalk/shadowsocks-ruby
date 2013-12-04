
$TopDomain = ['com','co','edu','gov','net','org','mil','info','name','xxx','mobi','tel','post','biz','pro']

def getDomainRegex()
  countryDomain = []
  cfg_file = File.open('country_domain.txt')
  cfg_file.each do |line|
    countryDomain.push(line.strip.downcase)
  end
  cfg_file.close

  domainAll = $TopDomain+countryDomain
  domainString = "("
  i = 0
  domainAll.each { |x|
    if i>0 then domainString += "|" end
    domainString += "#{x}"
    i += 1
  }
  domainString += ")"
  domainregex = /([\w-]+)\.#{domainString}\.?#{domainString}?$/
end
