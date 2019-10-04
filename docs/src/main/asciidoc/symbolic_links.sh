#!/bin/bash -x

set -e

projectRoot="${1}"
releaseTrainMajor="${2}"

echo "Making symbolic link for the main docs"
ln -fs "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainMajor}".adoc "${projectRoot}"/src/main/asciidoc/spring-cloud.adoc
ln -fs "${projectRoot}"/src/main/asciidoc/spring-cloud.adoc "${projectRoot}"/src/main/asciidoc/index.adoc

if [ -f "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainMajor}"-single.adoc ]; then
    echo "Making symbolic link for the single page docs"
    ln -fs "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainMajor}"-single.adoc "${projectRoot}"/src/main/asciidoc/spring-cloud.htmlsingleadoc
fi

if [ -f "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainMajor}"-pdf.adoc ]; then
    echo "Making symbolic link for the pdf docs"
    ln -fs "${projectRoot}"/src/main/asciidoc/_spring-cloud-"${releaseTrainMajor}"-pdf.adoc "${projectRoot}"/src/main/asciidoc/spring-cloud.pdfadoc
fi
