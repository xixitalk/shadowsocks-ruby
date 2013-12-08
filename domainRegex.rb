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

def getIP(host)
  num = /\d|[01]?\d\d|2[0-4]\d|25[0-5]/
  ip_regex = /^(#{num}\.){3}#{num}$/
  ret = ip_regex.match(host)
end

def getHostBase(host)
  ret = getIP(host)
  if ret != nil
    return ret[0]
  end

  host_regex = getDomainRegex()
  ret = host_regex.match(host)
  if ret != nil
    host_base = ret[0]
  else
    host_base = nil
  end
  host_base
end

