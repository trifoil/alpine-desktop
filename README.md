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
apk del gnome-calendar gnome-music cheese gnome-tour totem yelp simple-scan
```

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```