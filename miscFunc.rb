#!/usr/bin/ruby

def os_family
  case RUBY_PLATFORM
    when /ix/i, /ux/i, /gnu/i,
         /sysv/i, /solaris/i,
         /sunos/i, /bsd/i
      "unix"
    when /win/i, /ming/i
      "windows"
    else
      "other"
  end
end

def osIsWindows
  os_family.eql?("windows")
end

def osIsUnix
  os_family.eql?("unix")
end

