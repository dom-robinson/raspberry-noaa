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

SYSTEM_MEMORY=$(free -m | awk '/^Mem:/{print $2}')
if [ "$SYSTEM_MEMORY" -lt 2000 ]; then
    log "The system doesn't have enough space to store a Meteor pass on RAM" "INFO"
	RAMFS_AUDIO="${METEOR_OUTPUT}"
fi

if [ "$FLIP_METEOR_IMG" == "true" ]; then
    log "I'll flip this image pass because FLIP_METEOR_IMG is set to true" "INFO"
    FLIP="-rotate 180"
else
    FLIP=""
fi

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
#timeout "${6}" /usr/local/bin/rtl_fm ${BIAS_TEE} -M raw -f "${2}"M -s 288k -g $GAIN | sox -t raw -r 288k -c 2 -b 16 -e s - -t wav "${RAMFS_AUDIO}/audio/${3}.wav" rate 96k
timeout "${6}" python rtlsdr_m2_lrpt_rx.py $1 $2 $3 $3

NOW=$(date +%m-%d-%Y)


log "Decoding in progress (QPSK to BMP)" "INFO"

# Winter
medet_arm ${3}.s $3 -r 68 -g 65 -b 64 -na -s
# Summer
#medet/medet_arm ${3}.s $3 -r 66 -g 65 -b 64 -na -s

if [ -f "${3}_0.bmp" ]; then
        dte=`date +%H`

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

        #add raspberry-noaa formats
	convert "${3}.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${1} ${START_DATE} Elev: $7°" "${NOAA_OUTPUT}/images/${3}-122-rectified.jpg"
    	convert -thumbnail 300 "${3}.jpg" "${NOAA_OUTPUT}/images/thumb/${3}-122-rectified.jpg"
    

	# Send to email / facebook page: needs some filtration for bad images in due course
	mpack -s ${3}-$i ${NOAA_OUTPUT}/images/${3}-122-rectified.jpg wrx.o0gnwd@zapiermail.com

	#update db / passes list etc
	sqlite3 /home/pi/raspberry-noaa/panel.db "insert into decoded_passes (pass_start, file_path, daylight_pass, sat_type) values ($5,\"$3\", 1,0);"
    	pass_id=$(sqlite3 /home/pi/raspberry-noaa/panel.db "select id from decoded_passes order by id desc limit 1;")
	sqlite3 /home/pi/raspberry-noaa/panel.db "update predict_passes set is_active = 0 where (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"

else
    log "Decoding failed, either a bad pass/low SNR or a software problem" "ERROR"
fi


#tidyup todo
mkdir -p /home/pi/raspberry-noaa/meteortodel/${NOW}
mv ${3}* ./meteortodel/${NOW}
