

#To enable mail sending follow this: https://doc.ubuntu-fr.org/msmtp

sudo apt install msmtp msmtp-mta
sudo nano ~/.msmtprc


#---- DON'T FORGET TO SET PASSWD and (if using zapier) the zapier email target (or any other email target)

#Set default values for all following accounts.
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

#Gmail
account        gmail
host           smtp.gmail.com
port           587
from           satellitewrx@gmail.com
user           satellitewrx@gmail.com
password       XXXXXXXXXXX


#Set a default account
account default : gmail

#-----

chown pi:pi .msmtprc 
chmod 400 .msmtprc


#----

#then use

mpack -s ${3}-$i ${NOAA_OUTPUT}/images/${3}-$i.jpg wrx.XXXX@zapiermail.com

#to feed to zapier and forward to whatever service.

#note that I have added in this line to the various receive...sh scripts next to where the twitter settings are. 
#For anyone pulling this then you may want to move the variables around email settings / server and pwds to a config file.

#a note on satvis integration
#I have reverse engineered the query to satvis.space as best i can.
##- tags is essential BUT brings in ALL weather satellites.
##- this is why i added the hot-link urls to the pass list - this allows you to instantly follow the 'next' satellite
##- satvis provides a huge amount of fun data to explore between passes :)

#Also the satvis integration has its URLs hard coded (using the already-present $pass[ 'sat_name' ] where required)


#---
#I have merged in the METEORM2 decoding from this excellent tutorial (https://www.instructables.com/Raspberry-Pi-NOAA-and-Meteor-M-2-Receiver/) that i had previously had both good success with and also consistently received better images than the default setup in raspberry-noaa.

#To make this work you need to add gnuradio

sudo apt install gnuradio
sudo apt install gr-osmosdr
