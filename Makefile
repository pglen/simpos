# Makefile for the SIMPOS project

all:
	echo Targets: build git run clean

# Auto Checkin
ifeq ("$(AUTOCHECK)","")
AUTOCHECK=autocheck
endif

git:
	#rm -f sys/disk.img
	git add .
	git commit -m "$(AUTOCHECK)"
	git push

build:
	./sh/build.sh

run:
	./sh/run.sh

clean:
	./sh/clean.sh