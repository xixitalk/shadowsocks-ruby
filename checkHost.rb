#!/usr/bin/ruby

def hostIsConnectable(host,port,timeout=10)
	status = system("./connect -n -w #{timeout} #{host} #{port}")
end