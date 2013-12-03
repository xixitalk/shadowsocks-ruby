#!/usr/bin/ruby

require 'json'

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

puts "direct.json count: #{$directList.size}"
puts "block.json count: #{$blockList.size}"
puts "other.json count #{$otherDict.size}"

$otherDict.each { |host,port|
  if $directList_fast.include?(host.to_sym.object_id) or $blockList_fast.include?(host.to_sym.object_id)
    puts "#{host} classify already"
    next 
  end
  ret = system("./connect -n -w 10 #{host} #{port}")
  if ret
    puts "#{host} #{port} ok"
    if $directList.include?(host)
      puts "#{host} existed"
    else
      $directList.push(host)
      puts "#{host} add to direct.json"
    end
  else
    puts "#{host} #{port} fail"
    if $blockList.include?(host)
      puts "#{host} existed"
    else
      $blockList.push(host)
      puts "#{host} add to block.json"
    end
  end
}

cfg_file = File.open('direct.json','w')
JSON.dump($directList,cfg_file)
cfg_file.close

cfg_file = File.open('block.json','w')
JSON.dump($blockList,cfg_file)
cfg_file.close

puts "direct.json count: #{$directList.size}"
puts "block.json count: #{$blockList.size}"


