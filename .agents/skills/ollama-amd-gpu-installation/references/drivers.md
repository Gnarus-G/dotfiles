# AMD ROCm Driver Installation

## Ubuntu 24.04 LTS

### Install Dependencies

```bash
# Update package list
sudo apt update

# Install kernel headers and modules
sudo apt install -y "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)"

# Install ROCm userspace libraries
sudo apt install -y python3-setuptools python3-wheel
```

### Add User to Groups

```bash
# Add current user to render and video groups for GPU access
sudo usermod -a -G render,video $USER
```

### Install AMD GPU Drivers

```bash
# Download and install amdgpu drivers (version 6.3.3 or newer)
wget https://repo.radeon.com/amdgpu-install/6.3.3/ubuntu/noble/amdgpu-install_6.3.60303-1_all.deb
sudo apt install -y ./amdgpu-install_6.3.60303-1_all.deb
sudo apt update
```

### Install ROCm

```bash
# Install amdgpu-dkms and ROCm
sudo apt install -y amdgpu-dkms rocm
```

### Reboot

```bash
# Reboot to load new drivers
sudo reboot
```

## Arch Linux

### Update System

```bash
# Update package list
sudo pacman -Syu
```

### Install ROCm

```bash
# Install ROCm and dependencies
sudo pacman -S --needed base-devel rocm-opencl rocm-libs rocm-opencl-icd
```

### Add User to Groups

```bash
# Add current user to render and video groups for GPU access
sudo usermod -a -G render,video $USER
```

### Install AMD GPU Drivers

```bash
# Install amdgpu drivers
sudo pacman -S --needed amdgpu
```

### Reboot

```bash
# Reboot to load new drivers
sudo reboot
```

## Verification

After reboot, verify the installation:

```bash
# Check ROCm installation
rocminfo

# Check if GPU is detected
lspci | grep -i amd

# Check kernel modules
lsmod | grep amdgpu
```

## Troubleshooting

### GPU Not Detected

1. Check if kernel modules are loaded:
   ```bash
   lsmod | grep amdgpu
   ```

2. Verify ROCm installation:
   ```bash
   rocminfo
   ```

3. Check user groups:
   ```bash
   groups $USER
   ```

### Permission Errors

If you get permission errors accessing GPU devices:

```bash
# Check device permissions
ls -la /dev/kfd /dev/dri/

# Add user to render group
sudo usermod -a -G render,video $USER

# Logout and login again for changes to take effect
```

### Driver Version Issues

Check the loaded driver version:

```bash
# Check amdgpu driver version
dmesg | grep -i amdgpu | grep version

# Check ROCm version
rocminfo | grep "Name:"
```

## Notes

- Ubuntu requires downloading the AMD GPU driver package
- Arch Linux has ROCm in the official repositories
- Both distributions need user to be in render and video groups
- Reboot is required after driver installation
- The amdgpu kernel driver is included in newer kernels, but ROCm userspace libraries are still needed