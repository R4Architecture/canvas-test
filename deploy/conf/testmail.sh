#!/usr/bin/env bash


#download swaks
curl http://www.jetmore.org/john/code/swaks/files/swaks-20181104.0.tar.gz --output ./swaks-20181104.0.tar.gz
tar -xvf swaks-20181104.0.tar.gz
cd swaks-20181104.0/
./swaks --to ronald.ham@surf.nl --server outgoing.mf.surf.net --from no-reply@surf.nl