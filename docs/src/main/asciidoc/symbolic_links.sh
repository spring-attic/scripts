#!/bin/bash -x

set -e

projectRoot="${1}"
releaseTrainVersion="${2}"
releaseTrainVersion="${releaseTrainVersion//./-}"

rm -f "${projectRoot}"/src/main/asciidoc/index.adoc
rm -f "${projectRoot}"/src/main/asciidoc/index.htmlsingleadoc
rm -f "${projectRoot}"/src/main/asciidoc/index.pdfadoc

echo "Making symbolic link for the main docs"
ln -fs "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainVersion}".adoc "${projectRoot}"/src/main/asciidoc/index.adoc

if [ -f "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainVersion}"-single.adoc ]; then
    echo "Making symbolic link for the single page docs"
    ln -fs "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainVersion}"-single.adoc "${projectRoot}"/src/main/asciidoc/index.htmlsingleadoc
fi

if [ -f "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainVersion}"-pdf.adoc ]; then
    echo "Making symbolic link for the pdf docs"
    ln -fs "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainVersion}"-pdf.adoc "${projectRoot}"/src/main/asciidoc/index.pdfadoc
fi