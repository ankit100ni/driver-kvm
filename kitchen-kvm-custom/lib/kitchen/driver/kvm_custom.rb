require 'kitchen'
require 'open3'

module Kitchen
  module Driver
    class KvmCustom < Kitchen::Driver::Base
      default_config :memory, 1024
      default_config :cpus, 1
      default_config :image, '/var/lib/libvirt/images/ubuntu-vm1.qcow2'
      default_config :cdrom, '/var/lib/libvirt/images/ubuntu-20.04.iso'
      default_config :network, 'default'
      default_config :graphics, 'vnc'
      default_config :ssh_user, 'ubuntu'
      default_config :ssh_key, '~/.ssh/id_rsa'

      def create(state)
        vm_name = config[:instance_name] || instance.name
        cmd = <<-EOC
          sudo virt-install --name=#{vm_name} \
          --memory=#{config[:memory]} \
          --vcpus=#{config[:cpus]} \
          --disk path=#{config[:image]},size=10 \
          --os-variant=ubuntu20.04 \
          --cdrom=#{config[:cdrom]} \
          --network=#{config[:network]} \
          --graphics=#{config[:graphics]} \
          --disk path=/var/lib/libvirt/images/cloud-init.iso,device=cdrom \
          --noautoconsole
        EOC

        run_command(cmd)
        ip_address = fetch_vm_ip(vm_name)
        if ip_address.nil?
          raise "Failed to fetch VM IP address. Check 'virsh domifaddr #{vm_name}'."
        end
        state[:hostname] = ip_address
        state[:username] = config[:ssh_user]
        state[:ssh_key] = config[:ssh_key]
      end

      def destroy(state)
        vm_name = config[:instance_name] || instance.name
        return if vm_name.nil?

        run_command("virsh destroy #{vm_name}")
        run_command("virsh undefine #{vm_name}")
      end

      def fetch_vm_ip(vm_name)
        10.times do
          output = `virsh domifaddr #{vm_name}`
          match = output.match(/\b(\d+\.\d+\.\d+\.\d+)\b/)
          return match[1] if match

          puts "Waiting for VM IP assignment..."
          sleep 5
        end
        nil
      end
    end
  end
end

