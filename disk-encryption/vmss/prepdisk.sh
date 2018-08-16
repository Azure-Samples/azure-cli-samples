sudo -i
mkfs.ext4 /dev/disk/azure/scsi1/lun3
UUID1="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun3)"
echo "UUID=$UUID1 /data1 ext4 defaults,nofail 0 0" >>/etc/fstab
mkdir /data1
mount -a