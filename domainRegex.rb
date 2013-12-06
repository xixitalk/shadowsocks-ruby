#!/usr/bin/ruby

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

def getHostBase(host)
  num = /\d|[01]?\d\d|2[0-4]\d|25[0-5]/
  IP_regex = /^(#{num}\.){3}#{num}$/
  host_regex = getDomainRegex()

  ret = IP_regex.match(host)
  host_base = host
  if ret == nil
     ret = host_regex.match(host)
     if ret != nil
       host_base = ret[0]
     end
  end
  host_base
end
