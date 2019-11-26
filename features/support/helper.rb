def require_all(path)
  glob = File.join(__dir__, path, "*.rb")
  Dir[glob].sort.each do |f|
    require f
  end
end

def is_os_freebsd
  os == "FreeBSD"
end

def os
  `uname`.gsub(/\n/, "")
end
