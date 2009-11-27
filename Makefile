# install into $DESTDIR
install_dir=install -d -m 755
install_file=install -m 644
install_user_file=install -m 600
install_script=install -m 755
install_binary=install -m 755 -s
varlib=$(DESTDIR)/var/lib/nginz
user_skel=$(varlib)/skel

all:
	echo done

clean:
	echo cleaned

install:
	$(install_dir) $(user_skel)
	$(install_file) nginz/.gemrc $(user_skel)
	$(install_dir) $(varlib)/vendor
	cp -a ../../../vendor/* $(varlib)/vendor
	chmod -R a+rX $(varlib)/vendor
	echo installed
