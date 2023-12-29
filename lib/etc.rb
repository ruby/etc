dir = __dir__
$:.delete(dir)
if libs = ENV.delete("RUBYLIB")
  libs = libs.split(File::PATH_SEPARATOR).select do |d|
    !File.identical?(d, dir)
  end
  ENV["RUBYLIB"] = libs.join(File::PATH_SEPARATOR) unless libs.empty?
end
raise LoadError, "etc"
