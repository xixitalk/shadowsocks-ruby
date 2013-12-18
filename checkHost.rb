#!/usr/bin/ruby

require './miscFunc'

def hostIsConnectable(host,port,timeout=10)
  if osIsUnix
    cmdStr = "./connect -n -w #{timeout} #{host} #{port}"
  elsif osIsWindows
    cmdStr = "./connect -n #{host} #{port}"
  else
    return false
   end
  system(cmdStr)
end