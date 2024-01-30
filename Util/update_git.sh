clear

echo "Updating Git Repositories locally"
echo "========================================"
echo "\n\n"

echo "Updating Desktop/Mint19Setup"
git config --global --add safe.directory /home/lraja/Desktop/Mint19Setup
cd /home/lraja/Desktop/Mint19Setup
git status
git pull

echo "\n\n"
echo "Updating Github/Mint19Setup"
cd /home/lraja/Github/Mint19Setup
git status
git pull

echo "\n\n"
echo "Updating Desktop/PrivateRepo"
git config --global --add safe.directory /home/lraja/Desktop/PrivateRepo
cd /home/lraja/Desktop/PrivateRepo
git status
git pull

echo "\n\n"
echo "Updating Desktop/Kanda"
git config --global --add safe.directory /home/lraja/Desktop/Kanda
cd /home/lraja/Desktop/Kanda
git status
git pull

echo "\n\n"
echo "Updating Desktop/Garage"
git config --global --add safe.directory /home/lraja/Desktop/Garage
cd /home/lraja/Desktop/Garage
git status
git pull

echo "\n\n"
echo "Updating Documents/Deploy.tomcat.web-project"
git config --global --add safe.directory /home/lraja/Documents/Deploy.tomcat.web-project
cd /home/lraja/Documents/Deploy.tomcat.web-project
git status
git pull

# echo "\n\n"
# echo "Updating Desktop/Deploy.tomcat.web-project"
# git config --global --add safe.directory /home/lraja/Desktop/Deploy.tomcat.web-project
# cd /home/lraja/Desktop/Deploy.tomcat.web-project
# git status
# git pull

echo "\n\n"
echo "Updating Documents/Deploy.Kubernetes.web-project"
git config --global --add safe.directory /home/lraja/Documents/Deploy.Kubernetes.web-project
cd /home/lraja/Documents/Deploy.Kubernetes.web-project
git status
git pull

# echo "\n\n"
# echo "Updating Desktop/kandasubbu"
# cd /home/lraja/Desktop/kandasubbu
# git status
# git pull

sleep 15


