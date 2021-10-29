-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 3.0 (quilt)
Source: syslinux
Binary: syslinux, syslinux-efi, extlinux, isolinux, pxelinux, syslinux-common, syslinux-utils
Architecture: amd64 i386 x32 all
Version: 3:6.04~git20190206.bf6db5b4+dfsg1-3
Maintainer: Debian CD Group <debian-cd@lists.debian.org>
Uploaders: Lukas Schwaighofer <lukas@schwaighofer.name>
Homepage: http://www.syslinux.org/
Standards-Version: 4.5.0
Vcs-Browser: https://salsa.debian.org/images-team/syslinux
Vcs-Git: https://salsa.debian.org/images-team/syslinux.git
Build-Depends: debhelper-compat (= 12), e2fslibs-dev, gcc-multilib [amd64 x32], libc6-dev-i386 [amd64 x32], nasm, python3, uuid-dev
Build-Depends-Indep: gnu-efi (>= 3.0.8)
Package-List:
 extlinux deb admin optional arch=amd64,i386,x32
 isolinux deb admin optional arch=all
 pxelinux deb admin optional arch=all
 syslinux deb admin optional arch=amd64,i386,x32
 syslinux-common deb admin optional arch=all
 syslinux-efi deb admin optional arch=all
 syslinux-utils deb admin optional arch=amd64,i386,x32
Checksums-Sha1:
 ebd33c9110080c49f1350b966675498cc9a6f185 3164384 syslinux_6.04~git20190206.bf6db5b4+dfsg1.orig.tar.xz
 6f22cbb9a171c65f0e5f1adb5e1a47b199bc2b26 42884 syslinux_6.04~git20190206.bf6db5b4+dfsg1-3.debian.tar.xz
Checksums-Sha256:
 46169f43dabb5f6cb33a3f6fb79a61008179326756481845c0a42d429d0c5bee 3164384 syslinux_6.04~git20190206.bf6db5b4+dfsg1.orig.tar.xz
 ee68e669b061c7b6887bc4d82b3c6c719e3db9d12ea7d034d4d62149161c5305 42884 syslinux_6.04~git20190206.bf6db5b4+dfsg1-3.debian.tar.xz
Files:
 af14c068258814cc96f93ad374f6b18e 3164384 syslinux_6.04~git20190206.bf6db5b4+dfsg1.orig.tar.xz
 7df003796a04643b42b2e323ce7cdc70 42884 syslinux_6.04~git20190206.bf6db5b4+dfsg1-3.debian.tar.xz

-----BEGIN PGP SIGNATURE-----

iQJMBAEBCgA2FiEEyHOrc2J0RyJhSWjkyo1AAZ69TpMFAl85Q8AYHGx1a2FzQHNj
aHdhaWdob2Zlci5uYW1lAAoJEMqNQAGevU6TXpQQAIuErM+tGISXbSjqEZv0bxlF
fDy9Ee5nbO/SYJt/PjkaZS0D0dOjZ3Fzbaz9MPCO43tI0zg4USyy9CQT1mo33UNT
+oy5IR/uqACVhny5DBMey5iEHG5fhZxhavLNPnajjnNXBFHgny078gx/bWXiaHdW
I++jEgbspnZs3lCM5/s2d/82tBGzd9J+l3uwLC7TqzBNaafhlKQpdjdOAobbanH3
GMxNdwuEItYq84UeKP1XbaiQ7O72ZTeVxx/jHXv1e6cq5ZIsQNERI208Mf/CUQ51
/MMSFECaHc8EN8NFknT2/R1y3yGl6Ru0JrlYwl3aEsAMNFfEmS7R7kBReK862j4T
pFkX8ua7uOfEn0Zj1Mp5s42a0A69fiXyQJ/7j3qURxBc5GqYJa6FkzniFahWhFWZ
LgSKnnR5emWn0tagZiMSlqC3XZ2/HI77DnYEEhsHmopzZoU6EsObQCqUAi5zVnBP
YadqtIbui04TrM9KsZpMkZWf6Nl3BN6JU0MHqHfcrwjyHqn9wz+VA+r/rHvECfJs
qMff6nO4Yh2pIiIQAF3/fPC15BZfPeA4LozP3XqVo0ZS8jVvpRxKcQ0tdCEk18gM
Edr5+MzZYf3NApm/sSFTaiQIPPmImBWFDvBTANMVYeZx28QYVgQP7g3GySCxyitL
NyIdB2KGY77pGEmVAiHt
=4Fpr
-----END PGP SIGNATURE-----
