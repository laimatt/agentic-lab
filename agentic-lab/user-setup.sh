#!/bin/bash

sudo -u $USERNAME bash -c "cd /home/$USERNAME/$LAB_NAME && make setup"
sudo -u $USERNAME bash -c "cd /home/$USERNAME/$LAB_NAME && make init-db"