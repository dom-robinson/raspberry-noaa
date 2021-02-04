#!/bin/bash

### Run as a normal user
if [ $EUID -eq 0 ]; then
    echo "This script shouldn't be run as root."
    exit 1
fi

## import common lib
. "$HOME/.noaa.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/common.sh"

cd /home/pi/raspberry-noaa/

if [ "$FLIP_METEOR_IMG" == "true" ]; then
    log "I'll flip this image pass because FLIP_METEOR_IMG is set to true" "INFO"
    FLIP="-rotate 180"
else
    FLIP=""
fi

log "METEOR M2 receive_meteor.sh capture starting" "INFO"
## pass start timestamp and sun elevation
PASS_START=$(expr "$5" + 90)
SUN_ELEV=$(python3 "$NOAA_HOME"/sun.py "$PASS_START")

if pgrep "rtl_fm" > /dev/null
then
    log "There is an already running rtl_fm instance but I dont care for now, I prefer this pass" "INFO"
    pkill -9 -f rtl_fm
fi

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture
# $7 = Satellite max elevation

log "Starting rtl_fm record" "INFO"
timeout "${6}" python rtlsdr_m2_lrpt_rx.py $1 $2 $3 $3

NOW=$(date +%m-%d-%Y)
sleep 5
log "Decoding in progress (QPSK to BMP)" "INFO"

# Winter
medet_arm ${3}.s $3 -r 68 -g 65 -b 64 -na -s

# Summer
#medet/medet_arm ${3}.s $3 -r 66 -g 65 -b 64 -na -s

if [ -f "${3}_0.bmp" ]; then
        dte=`date +%H`

	log "Post Processing in  progress" "INFO"

        # Winter
        convert ${3}_1.bmp ${3}_1.bmp ${3}_0.bmp -combine -set colorspace sRGB ${3}.bmp
        convert ${3}_2.bmp ${3}_2.bmp ${3}_2.bmp -combine -set colorspace sRGB -negate ${3}_ir.bmp

        # Summer
        #convert ${3}_0.bmp ${3}_1.bmp ${3}_2.bmp -combine -set colorspace sRGB ${3}.bmp

	python3 rectify.py ${3}.bmp
        python3 rectify.py ${3}_ir.bmp

        if [ $dte -lt 13 ]; then
                convert ${3}-rectified.jpg -normalize -quality 90 $3.jpg
                convert ${3}_ir-rectified.jpg -normalize -quality 90 ${3}_ir.jpg
        else
                convert ${3}-rectified.jpg -rotate 180 -normalize -quality 90 $3.jpg
                convert ${3}_ir-rectified.jpg -rotate 180 -normalize -quality 90 ${3}_ir.jpg
        fi


	log "Compressing and adding to images folder" "INFO"
        #add raspberry-noaa formats
	convert "${3}.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${1} ${START_DATE} Elev: $7°" "${NOAA_OUTPUT}/images/${3}-122-rectified.jpg"
    	convert -thumbnail 300 "${3}.jpg" "${NOAA_OUTPUT}/images/thumb/${3}-122-rectified.jpg"
        convert "${3}_ir.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${1} ${START_DATE} Elev: $7°" "${NOAA_OUTPUT}/images/${3}-122-rectified_ir.jpg"
        convert -thumbnail 300 "${3}_ir.jpg" "${NOAA_OUTPUT}/images/thumb/${3}-122-rectified_ir.jpg"

	log "Emailing to facebook forwarder" "INFO"
    	# Send to email / facebook page: needs some filtration for bad images in due course
	if [ -f "${NOAA_OUTPUT}/images/${3}-122-rectified_ir.jpg" ]; then 
        	mpack -s ${3}-${7}-"InfraRed" ${NOAA_OUTPUT}/images/${3}-122-rectified_ir.jpg trigger@applet.ifttt.com
	fi
	if [ -f "${NOAA_OUTPUT}/images/${3}-122-rectified.jpg" ]; then 
		mpack -s ${3}-${7} ${NOAA_OUTPUT}/images/${3}-122-rectified.jpg trigger@applet.ifttt.com
	fi

	log "Updating DB" "INFO"
	#update db / passes list etc
	sqlite3 /home/pi/raspberry-noaa/panel.db "insert into decoded_passes (pass_start, file_path, daylight_pass, sat_type) values ($5,\"$3\", 1,0);"
    	pass_id=$(sqlite3 /home/pi/raspberry-noaa/panel.db "select id from decoded_passes order by id desc limit 1;")
	sqlite3 /home/pi/raspberry-noaa/panel.db "update predict_passes set is_active = 0 where (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"

	log "METEOR M2 processing complete and successful" "INFO"
	
else
    log "Decoding failed, either a bad pass/low SNR or a software problem" "ERROR"
fi

#tidyup todo
#mkdir -p /home/pi/raspberry-noaa/meteortodel/${NOW}
#mv ${3}* ./meteortodel/${NOW}
rm ${3}*
