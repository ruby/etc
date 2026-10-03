# frozen_string_literal: true

require "etc.so"

module Etc
  # Internal support for determining the CPU capacity available through Linux
  # control groups.
  module Cgroup
    CGROUP_PATH = "/proc/self/cgroup"
    MOUNTINFO_PATH = "/proc/self/mountinfo"

    module_function

    def cpu_quota(cgroup_path = CGROUP_PATH, mountinfo_path = MOUNTINFO_PATH)
      memberships = memberships(cgroup_path)
      return if memberships.empty?

      limits, matched = limits_from_mounts(memberships, mountinfo_path)
      limits = limits_from_conventional_paths(memberships) unless matched
      limits.min
    rescue Errno::EACCES, Errno::EINVAL, Errno::ENOENT, Errno::ENOTDIR, ArgumentError
      nil
    end

    def memberships(path)
      File.readlines(path, chomp: true).filter_map do |line|
        _id, controllers, cgroup = line.split(":", 3)
        next unless controllers && cgroup

        if controllers.empty?
          [:v2, cgroup]
        elsif controllers.split(",").include?("cpu")
          [:v1, cgroup]
        end
      end
    end

    def limits_from_mounts(memberships, mountinfo_path)
      mounts = File.readlines(mountinfo_path, chomp: true).filter_map do |line|
        fields = line.split
        separator = fields.index("-")
        next unless separator && separator >= 6

        type = case fields[separator + 1]
               when "cgroup2"
                 :v2
               when "cgroup"
                 options = fields[5...separator] + fields[(separator + 2)..]
                 :v1 if options.any? { |option| option.split(",").include?("cpu") }
               end
        next unless type

        [type, unescape_path(fields[3]), unescape_path(fields[4])]
      end

      limits = []
      matched = false
      memberships.each do |type, path|
        mounts.each do |mount_type, root, mountpoint|
          next unless type == mount_type

          directory = resolve_directory(root, mountpoint, path)
          next unless directory

          matched = true
          limits.concat(limits_for_ancestors(type, directory, mountpoint))
        end
      end
      [limits, matched]
    end

    def limits_from_conventional_paths(memberships)
      limits = []
      limits << read_limit(:v2, "/sys/fs/cgroup") if memberships.any? { |type,| type == :v2 }

      if memberships.any? { |type,| type == :v1 }
        limits << read_limit(:v1, "/sys/fs/cgroup/cpu")
        limits << read_limit(:v1, "/sys/fs/cgroup/cpu,cpuacct")
      end

      limits.compact
    end

    def resolve_directory(root, mountpoint, path)
      root = File.expand_path(root)
      path = File.expand_path(path)

      relative = if path == root || path == "/"
                   ""
                 elsif root == "/"
                   path.delete_prefix("/")
                 elsif path.start_with?("#{root}/")
                   path.delete_prefix("#{root}/")
                 else
                   path.delete_prefix("/")
                 end

      File.expand_path(relative, mountpoint)
    end

    def limits_for_ancestors(type, directory, mountpoint)
      mountpoint = File.expand_path(mountpoint)
      directory = File.expand_path(directory)
      return [] unless directory == mountpoint || directory.start_with?("#{mountpoint}/")

      limits = []
      loop do
        limit = read_limit(type, directory)
        limits << limit if limit
        break if directory == mountpoint

        directory = File.dirname(directory)
      end
      limits
    end

    def read_limit(type, directory)
      case type
      when :v2
        maximum, period = File.read(File.join(directory, "cpu.max")).split
        return if maximum == "max" || !maximum || !period

        ratio(maximum, period)
      when :v1
        maximum = File.read(File.join(directory, "cpu.cfs_quota_us"))
        return if Integer(maximum) < 0

        period = File.read(File.join(directory, "cpu.cfs_period_us"))
        ratio(maximum, period)
      end
    rescue Errno::EACCES, Errno::EINVAL, Errno::ENOENT, Errno::ENOTDIR, ArgumentError
      nil
    end

    def ratio(maximum, period)
      maximum = Float(maximum)
      period = Float(period)
      return unless maximum.positive? && period.positive?

      maximum / period
    end

    def unescape_path(path)
      path.gsub(/\\([0-7]{3})/) { $1.to_i(8).chr }
    end
  end
  private_constant :Cgroup

  # call-seq:
  #   processor_count -> Integer
  #
  # Returns the number of processors available to the process as an Integer.
  #
  # This is an alias for Etc.nprocessors.
  alias processor_count nprocessors
  module_function :processor_count

  # call-seq:
  #   processor_quota -> Float
  #
  # Returns the processor capacity available to the process as a Float.
  #
  # On Linux, this accounts for CPU bandwidth limits in cgroup v1 and v2. The
  # result will not exceed Etc.processor_count, which already accounts for CPU
  # affinity. On other platforms, or when no cgroup limit can be determined,
  # it returns Etc.processor_count converted to a Float.
  def processor_quota
    count = processor_count.to_f
    quota = Cgroup.cpu_quota if RUBY_PLATFORM.include?("linux")
    quota ? [count, quota].min : count
  end
  module_function :processor_quota
end
