#!/bin/bash -x

set -e

projectRoot="${1}"
releaseTrainVersion="${2}"
releaseTrainVersion="${releaseTrainVersion//./-}"

rm -f index.adoc
rm -f index.htmlsingleadoc
rm -f index.pdfadoc

cd "${projectRoot}/docs/src/main/asciidoc/"
  echo "Making symbolic link for the main docs"
  ln -fs _spring-cloud-"${releaseTrainVersion}".adoc index.adoc
  
  if [ -f _spring-cloud-"${releaseTrainVersion}"-single.adoc ]; then
      echo "Making symbolic link for the single page docs"
      ln -fs _spring-cloud-"${releaseTrainVersion}"-single.adoc index.htmlsingleadoc
  fi
  
  if [ -f _spring-cloud-"${releaseTrainVersion}"-pdf.adoc ]; then
      echo "Making symbolic link for the pdf docs"
      ln -fs _spring-cloud-"${releaseTrainVersion}"-pdf.adoc index.pdfadoc
  fi
cd "${projectRoot}"