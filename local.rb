#!/usr/bin/ruby

# Copyright (c) 2012 clowwindy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rubygems'
require 'eventmachine'
require 'json'
require './encrypt'
require './domainRegex'
require './checkHost'

cfg_file = File.open('config.json')
config =  JSON.parse(cfg_file.read)
cfg_file.close

cfg_file = File.open('direct.json')
$directList =  JSON.parse(cfg_file.read)
$directList_fast = $directList.collect { |x| x.to_sym.object_id}
cfg_file.close

cfg_file = File.open('block.json')
$blockList =  JSON.parse(cfg_file.read)
$blockList_fast = $blockList.collect { |x| x.to_sym.object_id}
cfg_file.close

$otherDict =  {}

key = config['password']
if ARGV.include?("debug")
$debug_flag = true
else
$debug_flag = false 
end

$server = config['server']
$remote_port = config['server_port'].to_i
$port = config['local_port'].to_i

$encrypt_table, $decrypt_table = get_table(key)

num = /\d|[01]?\d\d|2[0-4]\d|25[0-5]/
$IP_regex = /^(#{num}\.){3}#{num}$/

$Host_regex = getDomainRegex()

def inet_ntoa(n)
    n.unpack("C*").join "."
end

def writeList2File
    cfg_file = File.open('direct.json','w')
    JSON.dump($directList,cfg_file)
    cfg_file.close
    cfg_file = File.open('block.json','w')
    JSON.dump($blockList,cfg_file)
    cfg_file.close
end

def isClassify(host_base)
  ret = if $directList_fast.include?(host_base.to_sym.object_id) or $blockList_fast.include?(host_base.to_sym.object_id) then true
        else false end
end

def add2OtherDict(host,port)
  if host == nil or port == nil then return end
  host_base = getHostBase(host)
  if isClassify(host_base) then return end  
  $otherDict[host] = port
end

def checkHostConnectableProc
  if $otherDict.size==0 then return end
  otherDict2 = $otherDict.clone
  otherDict2.each { |host,port|
    host_base = getHostBase(host)
    if host_base == nil then next end
    if isClassify(host_base) then next end
    if hostIsConnectable(host,port)
      $directList.push(host_base)
      $directList_fast.push(host_base.to_sym.object_id)
    else
      $blockList.push(host_base)
      $blockList_fast.push(host_base.to_sym.object_id)
    end
  }

  otherDict2.each { |key,value|
    $otherDict.delete(key)
  }

end

def isProxyConnectFunc(host)
  host_base = getHostBase(host)
  status = if $blockList_fast.include?(host_base.to_sym.object_id) then true 
  else false end 
end

module LocalServer
  class LocalConnector < EventMachine::Connection
    def initialize server
      @server = server
      super
    end

    def post_init
      #p "connecting #{@server.remote_addr} via #{@server.server_using}"
      if @server.isProxyConnect
        addr_to_send = @server.addr_to_send.clone
        encrypt $encrypt_table, addr_to_send
        send_data addr_to_send
      end

      for piece in @server.cached_pieces
        if @server.isProxyConnect
          encrypt $encrypt_table, piece
        end
        send_data piece
      end
      @server.cached_pieces = nil

      @server.stage = 5
    end

    def receive_data data
      if @server.isProxyConnect
        encrypt $decrypt_table, data
      end
      @server.send_data data
    end

    def unbind
      @server.close_connection_after_writing
    end
  end

  attr_accessor :remote_addr
  attr_accessor :remote_port
  attr_accessor :stage
  attr_accessor :addr_to_send
  attr_accessor :server_using
  attr_accessor :cached_pieces
  attr_accessor :isProxyConnect

  def post_init
    #puts "local connected"
    @stage = 0
    @header_length = 0
    @remote = 0
    @cached_pieces = []
    @remote_addr = nil
    @remote_port = nil
    @connector = nil
    @addr_to_send = ""
    @server_using = $server
    @isProxyConnect =false 

  end

  def receive_data data
    if @stage == 5
      if @isProxyConnect
        encrypt $encrypt_table, data
      end
      @connector.send_data data
      return
    end
    if @stage == 0
      send_data "\x05\x00"
      @stage = 1
      return
    end
    if @stage == 1
      begin
        addr_len = 0
        cmd = data[1]
        addrtype = data[3]
        if cmd != "\x01"
          warn "unsupported cmd: " + cmd.unpack('c')[0].to_s
          close_connection
          return
        end
        if addrtype == "\x03"
          addr_len = data[4].unpack('c')[0]
        elsif addrtype != "\x01"
          warn "unsupported addrtype: " + addrtype.unpack('c')[0].to_s
          close_connection
          return
        end
        @addr_to_send = data[3]
        if addrtype == "\x01"
          @addr_to_send += data[4..9]
          @remote_addr = inet_ntoa data[4..7]
          @remote_port = data[8, 2].unpack('s>')[0]
          @header_length = 10
        else
          @remote_addr = data[5, addr_len]
          @addr_to_send += data[4..5 + addr_len + 2]
          @remote_port = data[5 + addr_len, 2].unpack('s>')[0]
          @header_length = 5 + addr_len + 2
        end
        #p @remote_addr, @remote_port
        #p @addr_to_send
        @isProxyConnect = isProxyConnectFunc(@remote_addr)
        if @isProxyConnect
          puts "connecting #{@remote_addr} via #{$server}" if $debug_flag
        else
          puts "direct connecting #{@remote_addr} from localhost" if $debug_flag
        end
        send_data "\x05\x00\x00\x01\x00\x00\x00\x00" + [@remote_port].pack('s>')
        @stage = 4
        if data.size > @header_length
          @cached_pieces.push data[@header_length, data.size]
        end
        if @isProxyConnect
          @connector = EventMachine.connect $server, $remote_port, LocalConnector, self
        else
          @connector = EventMachine.connect @remote_addr, @remote_port, LocalConnector, self
        end
      rescue Exception => e
        warn e
        if @connector != nil
          @connector.close_connection
        end
        close_connection
      end
    elsif @stage == 4
      @cached_pieces.push data
    end

  end

  def unbind
    if @connector != nil
      @connector.close_connection_after_writing
      add2OtherDict(@remote_addr, @remote_port)
    end

  end
end

EventMachine::run {
  EventMachine::start_server "0.0.0.0", $port, LocalServer
  EventMachine.add_periodic_timer(600) do
    writeList2File
    if File.exist?("./emexit")
    	puts "eventmachine stopping"
    	EventMachine.stop
    end
  end
  EventMachine.add_periodic_timer(300) do
    checkHostConnectableProc
  end
}

