PACKAGE="macos"
PKGID="com.github.cgerke.${PACKAGE}"
VERSION="1.0"
TARGET=.

#################################################

all:
	# clean
	rm -f /tmp/${PACKAGE}.pkg

	# package
	pkgbuild --identifier ${PKGID} \
		--root root \
		--scripts scripts \
		--version ${VERSION} \
		--ownership recommended ${TARGET}/${PACKAGE}.pkg

	# flatten
	productbuild --package ${TARGET}/${PACKAGE}.pkg /tmp/${PACKAGE}.pkg
	rm -f ${TARGET}/${PACKAGE}.pkg
	
	# build
	#./make.sh
