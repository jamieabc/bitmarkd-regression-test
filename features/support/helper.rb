def require_all(path)
  glob = File.join(__dir__, path, "*.rb")
  Dir[glob].sort.each do |f|
    require f
  end
end

def os
  `uname`.gsub(/\n/, "")
end

def ci_os
  "FreeBSD"
end

def run_ci?
  os == ci_os
end
