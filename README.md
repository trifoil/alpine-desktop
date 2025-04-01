# Alpine Desktop 

### **1. Boot and Install Alpine**
1. **Boot from USB** (select "Alpine Extended" if prompted).
2. **Login** as `root` (no password by default).
3. **Run setup**:
   ```bash
   setup-alpine
   ```
4. **Follow the prompts**:
   - Keyboard layout (`us`, `uk`, etc.)
   - Hostname (e.g., `alpine-desktop`)
   - Network interface (e.g., `eth0`)
   - IP address (DHCP or manual)
   - Timezone (e.g., `UTC` or `Europe/London`)
   - Proxy (leave blank if not needed)
   - Mirror (pick a nearby one)
   - SSH server (enable if needed)
   - Disk partitioning:
     - **Recommended**: `sys` (entire disk, ext4)
     - Advanced users: Manual (`manual`) for custom partitions.
   - Set root password.
   - Install to disk (`y`).

5. **Reboot**:
   ```bash
   reboot
   ```
   (Remove the USB when prompted.)

---

### **2. Post-Installation Setup**
1. **Login** as `root`.

2. **Run the post install script**:
   ```bash
   git clone https://github.com/trifoil/alpine-desktop
   cd alpine-desktop
   sh install.sh
   cd ..
   rm -rf alpine-desktop
   ```

### **3. Tips**
1. **Super user**
   - Use ```doas``` instead of ```sudo```

2. **Cleaning**
   - Removing a package will automatically remove all of its dependencies that are otherwise not used





```
# Check for virtualization support and install virt-manager
echo "Checking virtualization support..."
if [ -z "$(grep -E 'vmx|svm' /proc/cpuinfo)" ]; then
    echo "WARNING: Virtualization extensions not found in /proc/cpuinfo"
    echo "You may need to enable virtualization in your BIOS/UEFI settings"
else
    echo "Virtualization support detected in CPU"
fi

# Install virt-manager and related packages
echo "Installing virt-manager and virtualization tools..."
apk add virt-manager libvirt qemu qemu-img qemu-system-x86_64 ebtables dnsmasq bridge-utils

# Start and enable libvirt service
rc-update add libvirtd
service libvirtd start

# Add user to libvirt group (assuming the main user is the one who installed the system)
MAIN_USER=$(ls /home | head -n 1)
if [ -n "$MAIN_USER" ]; then
    adduser $MAIN_USER libvirt
    echo "Added user $MAIN_USER to libvirt group"
else
    echo "No regular user found in /home directory"
fi

# Verify installation
if virsh list --all &>/dev/null; then
    echo "libvirt is working correctly"
else
    echo "libvirt installation may have issues - check journalctl for errors"
fi
```


