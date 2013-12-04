#!/usr/bin/ruby

require 'json'
require './domainRegex'

cfg_file = File.open('direct.json')
$directList =  JSON.parse(cfg_file.read)
$directList_fast = $directList.collect { |x| x.to_sym.object_id}
cfg_file.close

cfg_file = File.open('block.json')
$blockList =  JSON.parse(cfg_file.read)
$blockList_fast = $blockList.collect { |x| x.to_sym.object_id}
cfg_file.close

cfg_file = File.open('other.json')
$otherDict =  JSON.parse(cfg_file.read)
cfg_file.close

directCount = $directList.size
blockCount = $blockList.size

num = /\d|[01]?\d\d|2[0-4]\d|25[0-5]/
IP_regex = /^(#{num}\.){3}#{num}$/

#host_regex = /([\w-]+)\.([a-z]{2,3}).([a-z]{0,2})$/
#host_regex = /([\w-]+)([.a-z]{3,5})([.a-z]{0,2})$/
host_regex = getDomainRegex()

$otherDict.each { |host,port|
  ret = IP_regex.match(host)
  host_base = host
  if ret == nil
     ret = host_regex.match(host)
     if ret != nil
       host_base = ret[0]
     end
  end
# puts "#{host} #{host_base}";next
  if $directList_fast.include?(host_base.to_sym.object_id) or $blockList_fast.include?(host_base.to_sym.object_id)
    puts "#{host} classify already"
    next 
  end
  ret = system("./connect -n -w 10 #{host} #{port}")
  if ret
    puts "#{host} #{port} ok"
    if $directList.include?(host_base)
      puts "#{host_base} existed"
    else
      $directList.push(host_base)
      $directList_fast.push(host_base.to_sym.object_id)
      puts "#{host_base} add to direct.json"
    end
  else
    puts "#{host} #{port} fail"
    if $blockList.include?(host_base)
      puts "#{host_base} existed"
    else
      $blockList.push(host_base)
      $blockList_fast.push(host_base.to_sym.object_id)
      puts "#{host_base} add to block.json"
    end
  end
}

cfg_file = File.open('direct.json','w')
JSON.dump($directList,cfg_file)
cfg_file.close

cfg_file = File.open('block.json','w')
JSON.dump($blockList,cfg_file)
cfg_file.close
puts "*"*50
puts "direct.json count: #{$directList.size} #{$directList.size-directCount} add"
puts "block.json count: #{$blockList.size} #{$blockList.size-blockCount} add"


