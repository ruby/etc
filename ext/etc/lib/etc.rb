# frozen_string_literal: true

# MIT License
#
# Copyright (c) 2025 Taiki Kawakami (a.k.a moznion) https://moznion.net
# https://github.com/moznion/maxprocs-ruby/

require "etc.so"

return unless RUBY_PLATFORM.include?("linux")

module Etc
  # Maxprocs detects CPU quota from Linux cgroups and returns the appropriate
  # number of processors for container environments.
  module Maxprocs
    CGROUP_FILE_PATH = "/proc/self/cgroup"
    CGROUP_V1_QUOTA_PATH = "/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
    CGROUP_V1_PERIOD_PATH = "/sys/fs/cgroup/cpu/cpu.cfs_period_us"
    CGROUP_V2_CONTROLLERS_PATH = "/sys/fs/cgroup/cgroup.controllers"
    CGROUP_V2_CPU_MAX_PATH = "/sys/fs/cgroup/cpu.max"

    def nprocessors
      read_quota or super
    end

    private

    def read_quota
      return unless File.exist?(CGROUP_FILE_PATH)

      # Check for cgroup v2 first
      if File.exist?(CGROUP_V2_CONTROLLERS_PATH)
        read_quota_v2
      elsif File.exist?(CGROUP_V1_QUOTA_PATH)
        read_quota_v1
      end
    rescue Errno::ENOENT, Errno::EACCES, Errno::EINVAL
      # File doesn't exist, permission denied, or invalid - fallback to unlimited
    end

    def read_quota_v1
      quota = Integer(File.read(CGROUP_V1_QUOTA_PATH))
      return nil if quota == -1 # -1 means unlimited

      period = Integer(File.read(CGROUP_V1_PERIOD_PATH))
      return nil if period <= 0

      quota / period
    end

    def read_quota_v2
      max_str, period_str = File.read(CGROUP_V2_CPU_MAX_PATH).split(3)

      return nil if max_str == "max" # "max" means unlimited
      return nil if period_str.nil?

      max = Integer(max_str)
      period = Integer(period_str)
      return nil if period <= 0

      max / period
    end
  end

  prepend Maxprocs
  class << self
    prepend Maxprocs
  end
end
