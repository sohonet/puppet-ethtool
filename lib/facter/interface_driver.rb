require 'facter'
require 'json'

def get_interfaces
  path = '/sys/class/net'
  Dir.foreach(path).reject{|x| x.start_with?('.', 'veth', 'lo')}
rescue Errno::ENOENT, Errno::EACCES => detail
  Facter.debug "Could not read #{path}: #{detail.message}"
end
def set_facts
  get_interfaces.each do |interface|
    next if ! File.exists?('/sbin/ethtool')
    Facter.debug("Running ethtool on interface #{interface}")
    data = {}
    Facter::Util::Resolution.exec("ethtool -i #{interface} 2>/dev/null").split(/\n/).each do |line|
      k, v = line.split(': ')
      if v
       data[k]=v
      end
    end
    if data['driver']
      Facter.add('driver_' + interface) do
        confine :kernel => "Linux"
        setcode do
          data['driver']
        end
      end
    end
    if data['version']
      Facter.add('driver_version_' + interface) do
        confine :kernel => "Linux"
        setcode do
          data['version']
        end
      end
    end
  end
end
set_facts
