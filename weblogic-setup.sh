#!/bin/bash
# Author: Nirjas Jakilim
# Purpose: Setting up weblogic 14 
# The script must be run as a root user. Usage: ./weblogic-setup.sh


# Root permission check
if [ "$EUID" -ne 0 ]
  then echo "Please run the script as root user"
  exit
fi

# Mention the installer file name, response file name and Loc File Name here. Files should be in the same script directory.
installer="fmw_14.1.1.0.0_wls.jar"
response="install.rsp"
loc="oraInst.loc"

echo -e "\n####################### Installing Necessary Packages ###########################\n"
for i in binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.i686 compat-libstdc++-33.x86_64 gcc.x86_64 gcc-c++.x86_64 glibc.x86_64 glibc.i686  glibc-devel.i686 libaio.x86_64 libaio-devel.x86_64 libgcc.x86_64 libstdc++.x86_64 libstdc++.i686 libstdc++-devel.x86_64 libstdc++.i686 libstdc++-devel.x86_64 libXext.i686 libXtst.i686 sysstat.x86_64 ; do yum install -y $i; done

echo -e "\n###################### Creating oracle User and Group #############################\n"
if [[ $(getent passwd oracle) && $(getent group oracle) ]]
then
echo -e "\n User and Groups exist. Continuing the script! \n"
else
useradd oracle -md /home/oracle -s /bin/bash -c "Oracle User"
echo -e "\n User oracle has been created! \n" 
fi

echo -e "\n####################### Creating Swap Space if not added ########################\n"
swap=$(swapon --show --noheadings | head -1 | awk '{print $3}')
if [[ -z $swap || $swap < "2G" ]]
then
dd if=/dev/zero of=/home/oracle/.swapfile bs=1024 count=2097152
mkswap /home/oracle/.swapfile
chmod 0600 /home/oracle/.swapfile
swapon /home/oracle/.swapfile
echo -e "\n 2GB swap storage has been created successfully! \n"
else
echo -e "\n Sufficient swap storage is already there! \n"
fi

echo -e "\n###################### Creating necessary directories and permissions ##############\n"
mkdir -pv /usr/local/Oracle /home/oracle/oraInventory14110
chown -R oracle:oracle /usr/local/Oracle /home/oracle/oraInventory14110

echo -e "\n###################### Copying reponsefile and installer to oracle user #############\n"
cp -rv ${installer} ${response} ${loc} /home/oracle
chown -R oracle:oracle /home/oracle

echo -e "\n###################### Adding Environement Path Variables #############################\n"
oracle_home="/usr/local/Oracle/Middleware/Oracle_Home"
java_home="JAVA_HOME"
mw_check=$(grep -E -o $oracle_home /home/oracle/.bashrc)
java_check=$(grep -E -o $java_home /home/oracle/.bashrc)
if [[ -z $mw_check && -z $java_check ]]
then
echo "export MW=$oracle_home" >> /home/oracle/.bashrc
echo "export PATH=\$MW/oracle_common/common/bin:\$MW/OPatch:\$PATH" >> /home/oracle/.bashrc
echo "export JAVA_HOME=/usr/local/jdk" >> /home/oracle/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /home/oracle/.bashrc
echo -e "\n Added Weblogic and Java Path Variables! \n"
elif [[ -z $mw_check ]]
then
echo "export MW=$oracle_home" >> /home/oracle/.bashrc
echo "export PATH=\$MW/oracle_common/common/bin:\$MW/OPatch:\$PATH" >> /home/oracle/.bashrc
echo -e "\n Added Weblogic Path Variables! \n"
elif [[ -z $java_check ]]
then
echo "export JAVA_HOME=/usr/local/jdk" >> /home/oracle/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /home/oracle/.bashrc
echo -e "\n Added Java Path Variables! \n"
else
echo -e "\n Environment Path already exists! \n"
fi

echo -e "\n########################### Installing weblogic #################################\n"
su - oracle -c "java -jar $installer -silent -responseFile /home/oracle/install.rsp -invPtrLoc /home/oracle/oraInst.loc"

if [[ $? -eq 0 ]]
then
echo -e "\n######################### Weblogic Server Installed Succesfully! #################\n"
fi