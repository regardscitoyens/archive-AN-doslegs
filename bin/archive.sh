#!/bin/bash

mkdir -p archive

function download() {
  url=$1
  outfile=$2
  curl -sL "$url" > "$outfile"
  if ! test -s "$outfile"; then
    sleep 2
    curl -sL "$url" > "$outfile"
    if ! test -s "$outfile"; then
      print " -> ERROR! Can't download $url"
    fi
  fi
}

function archive() {
  dossier=$1
  outfile=$(echo $dossier | sed -r 's|^.*/([^/]+)$|\1|')
  outdir=archive/$(echo $dossier | sed -r 's|^/(.*)/[^/]+$|\1|')
  mkdir -p $outdir
  if test -s "$outdir/$outfile"; then
    return
  fi
  echo $outdir/$outfile
  download "http://www.assemblee-nationale.fr$dossier" $outdir/$outfile
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
      curl -sLI "http://www.assemblee-nationale.fr$dossier" |
        grep Location             |
        awk -F ': ' '{print $2}'  |
        sed 's/\W*$//'            |
        while read redir; do
          if [ ! -z "$redir" ] && [ "$redir" != "$dossier" ]; then
            if echo $redir | grep '^[^/]' > /dev/null; then
              redir=$(echo $dossier | sed -r 's|^(/.*)/[^/]+$|\1|')/$redir
            fi
            archive "$redir"
          fi
        done
    done
done
