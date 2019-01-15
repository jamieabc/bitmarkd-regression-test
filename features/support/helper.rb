def is_os_freebsd
  os == "FreeBSD"
end

def os
  `uname`.gsub(/\n/, "")
end
