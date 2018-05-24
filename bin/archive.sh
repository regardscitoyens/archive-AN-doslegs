#!/bin.bash

function archive() {
  dossier=$1
  outfile=$(echo $dossier | sed -r 's|^.*/([^/]+)$|\1|')
  outdir=$(echo $dossier | sed -r 's|^/(.*)/[^/]+$|\1|')
  mkdir -p $outdir
  echo $outdir/$outfile
  curl -sL "http://www.assemblee-nationale.fr$dossier" > $outdir/$outfile
}

for leg in $(seq 8 15); do
  curl -sL http://www.assemblee-nationale.fr/$leg/documents/index-dossier.asp |
    tr '\n' ' '                                         |
    sed -r 's/(<a href[^>]*>)/\n\1\n/g'                 |
    grep 'href=.*/dossiers/'                            |
    sed -r "s/^.*href=[\"']//"                          |
    sed -r "s/['\"].*>$//"                              |
    sed -r "s|^https?://www.assemblee-nationale.fr||"   |
    sed -r "s|#.*$||"                                   |
    sort -u                                             |
    while read dossier; do
      archive $dossier
      redir=$(curl -sLI "http://www.assemblee-nationale.fr$dossier" | grep Location | sed 's/^Location: //')
      if [ ! -z "$redir" ] && [ "$redir" != "$dossier" ]; then
        archive $redir
      fi
    done
done