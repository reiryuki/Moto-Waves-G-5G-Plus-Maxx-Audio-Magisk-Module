PKG="com.motorola.motosignature.app
     com.motorola.motowaves
     com.waves.maxxservice"
for PKGS in $PKG; do
  rm -rf /data/user/*/$PKGS/cache/*
done



