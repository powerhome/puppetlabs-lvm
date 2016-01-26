# Verify if a physical volume, volume group, logical volume, or filesystem resource type is created
#
# ==== Attributes
#
# * +resource_type+ - resorce type, i.e 'physical_volume', 'volume_group', 'logical_volume', or 'filesystem'
# * +resource_name+ - The name of resource type, i.e '/dev/sdb' for physical volume, vg_1234 for volume group
#
# ==== Returns
#
# +nil+
#
# ==== Raises
# assert_match failure message
# ==== Examples
#
# verify_if_created?(agent, 'physical_volume', /dev/sdb')
def verify_if_created?(agent, resource_type, resource_name, vg=nil, properties=nil)
  case resource_type
    when 'physical_volume'
      on(agent, "pvdisplay") do |result|
        assert_match(/#{resource_name}/, result.stdout, 'Unexpected error was detected')
      end
    when 'volume_group'
      on(agent, "vgdisplay") do |result|
        assert_match(/#{resource_name}/, result.stdout, 'Unexpected error was detected')
      end
    when 'logical_volume'
      on(agent, "lvdisplay /dev/#{vg}/#{resource_name}") do |result|
        assert_match(/#{resource_name}/, result.stdout, 'Unexpected error was detected')
        if properties
          assert_match(/#{properties}/, result.stdout, 'Unexpected error was detected')
        end
      end
  end
end

# Clean the box after each test, make sure the newly created logical volumes, volume groups,
# and physical volumes are removed at the end of each test to make the server ready for the
# next test case.
#
# ==== Attributes
#
# * +pv+ - physical volume, can be one volume or an array of multiple volumes
# * +vg+ - volume group, can be one group or an array of multiple volume groups
# * +lv+ - logical volume, can be one volume or an array of multiple volumes
#
# ==== Returns
#
# +nil+
#
# ==== Raises
# +nil+
# ==== Examples
#
# remove_all(agent, '/dev/sdb', 'VolumeGroup_1234', 'LogicalVolume_fa13')
def remove_all(agent, pv=nil, vg=nil, lv=nil)
  step 'remove logical volume if any:'
  if lv
    if lv.kind_of?(Array)
      lv.each do |logical_volume|
        on(agent, "umount /dev/#{vg}/#{logical_volume}", :acceptable_exit_codes => [0,1])
        on(agent, "lvremove /dev/#{vg}/#{logical_volume} --force")
      end
    else
      on(agent, "umount /dev/#{vg}/#{lv}", :acceptable_exit_codes => [0,1])
      on(agent, "lvremove /dev/#{vg}/#{lv} --force")
    end
  end

  step 'remove volume group if any:'
  if vg
    if vg.kind_of?(Array)
      vg.each do |volume_group|
        on(agent, "vgremove /dev/#{volume_group}")
      end
    else
      on(agent, "vgremove /dev/#{vg}")
    end
  end

  step 'remove logical volume if any:'
  if pv
    if pv.kind_of?(Array)
      pv.each do |physical_volume|
        on(agent, "pvremove #{physical_volume}")
      end
    else
      on(agent, "pvremove #{pv}")
    end
  end
end
