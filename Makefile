serve:
	jekyll serve --drafts --config _dev_config.yml

build : gulp
	 jekyll build --config _dev_config.yml

gulp :
	cd assets && gulp
