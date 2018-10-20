# wg-docker
Docker Container running a Gateway with wireguard and babel

### Prerequisites
- installed packages on host: 
    - curl
    - docker
    - dkms
- running docker daemon

### Install
- adjust the variables WIREGUARD_VERSION, BABELD_VERION and HOST_IP in install.sh according to your needs.
- run `bash install.sh` as root

### Uninstall
- remove Docker container
- run `dkms uninstall wireguard/<VERSION>` as root
