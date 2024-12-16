#!/bin/bash

# See https://github.com/cisagov/freeipa-server-packer/issues/69 and
# https://fedoraproject.org/wiki/Changes/StrongCryptoSettings2#Upgrade.2Fcompatibility_impact
update-crypto-policies --set DEFAULT:FEDORA32
