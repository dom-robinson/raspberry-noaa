# BUILD NOTES FOR MY LOCAL SYSTEM

*This is a rework of rapsberry-noaa with the following features:

-Satvis satellite tracking embedded with hotlinks to satellites from the passes list.
-Colourscheme adjustments
-EMAIL forwarding to zapier service (for downstream automation)
-M2 Workflow has been transplanted in and now displays both IR and 'normal' M2 images.
-use of the 'log' function now outputs to wrxlog.log in the pi hom folder.

-To DO
--Work through the installer process to configure email, ensure all new dependancies are included
--Focus on Passes Table - this should indicate FAILED as a status, and historic passes should hotlink to thier images not to the satvis status - This will require an additional 'ACTIVE' status in the db.
--Sort out the passes and images table to be responsive.
--Automate Mail setup install
--Add UI for web based admin - allowing removal of failed images
--Garbage Collection - still waiting to see how much fits on an SD card, but sense is one month will be max on 32GB card.
--Nice to have: Ajax updaing a push of latest images (I note there is a latestimage viewer but not foudn it in use yet)
--Nice to stream the wrxlog.log output to the webpage to monitor progress
 

*To enable mail sending follow this: https://doc.ubuntu-fr.org/msmtp*

``` bash
sudo apt install msmtp msmtp-mta
sudo nano ~/.msmtprc
```

*Copy, Paste and Edit the content of ~/.msmtprc with nano etc.*
*DON'T FORGET TO SET PASSWD and (if using zapier) the zapier email target (or any other email target)*
*--- snip ---
```
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

```
*--- snip ---

*now change the permission on the file*

``` bash
chown pi:pi .msmtprc 
chmod 400 .msmtprc
```

*then use the following in the scripts to feed to zapier and forward to whatever service.*

``` bash
mpack -s ${3}-$i ${NOAA_OUTPUT}/images/${3}-$i.jpg wrx.XXXX@zapiermail.com
```

*note that I have added in this line to the various receive...sh scripts next to where the twitter settings are.* 
*For anyone pulling this then you may want to move the variables around email settings / server and pwds to a config file.*

# A note on satvis integration
*I have reverse engineered the query to satvis.space as best i can:* 

* "tags=" is essential BUT brings in ALL weather satellites.
* this is why i added the hot-link urls to the pass list - this allows you to instantly follow the 'next' satellite
* satvis provides a huge amount of fun data to explore between passes :) Use its own gui to filter and predict etc.

*Also the satvis integration has its URLs hard coded (using the already-present $pass[ 'sat_name' ] where required)*
*This might be better passed in from config < **TODO** *

# Merging in the optimal M2 decode
*I have merged in the METEORM2 decoding from this excellent tutorial (https://www.instructables.com/Raspberry-Pi-NOAA-and-Meteor-M-2-Receiver/) that i had previously had both good success with and also consistently received better images than the default setup in raspberry-noaa.*

*To make this work you need to add gnuradio*

``` bash
sudo apt install gnuradio
sudo apt install gr-osmosdr
```

(This is now included in the install.sh script)

# Managing the DB
*There were numerous bad images that i wanted to clear out of the system.*

``` sql
sqlite3 panel.db 
```

*brings up the sqlite command prompt: use as follows:* 

``` sql
sqlite> .databases
main: /home/pi/raspberry-noaa/panel.db
sqlite> SELECT * FROM decoded_passes;
1|1611510695|NOAA1520210124-175135|0||1|
2|1611511653|NOAA1920210124-180733|0||1|
3|1611512568|METEOR-M220210124-182248|1||0|
4|1611522104|NOAA1820210124-210144|0||1|
5|1611555853|NOAA1920210125-062413|0||1|
6|1611560446|NOAA1520210125-074046|0||1|
7|1611561902|NOAA1920210125-080502|0||1|
8|1611562513|METEOR-M220210125-081513|1||0|
9|1611566301|NOAA1820210125-091821|0||1|
10|1611572345|NOAA1820210125-105905|1||1|
11|1611597343|NOAA1920210125-175543|0||1|
...

sqlite> DELETE FROM decoded_passes WHERE ID=36;
sqlite> .quit
```

*Note there is also 'prune.py' which will remove the oldest 10 images from the system: this can be automated but for now I am not doing this until Disc is at around 70%.*
